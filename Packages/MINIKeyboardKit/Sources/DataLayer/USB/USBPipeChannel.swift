import Foundation
import IOKit
import IOUSBHost
import Domain

/// A configuration interface no driver takes, opened through IOUSBHost and written on its interrupt OUT
/// pipe. The 1189:8890's interface 1 is HID class with only an OUT endpoint, so macOS attaches no HID
/// driver to it; the Windows tool writes the same reports to it through its HID stack. Nothing comes back.
@MainActor
final class USBPipeChannel: ReportChannel {
    let framing: ReportFraming
    private let pipe: PipeWriter

    private init(framing: ReportFraming, pipe: PipeWriter) {
        self.framing = framing
        self.pipe = pipe
    }

    enum Failure: Error {
        /// Not the configuration interface after all — its reports are not vendor-defined.
        case notConfiguration
        case failed(IOReturn)
    }

    /// Opens the interface and reads what writing needs from its descriptors: the interrupt OUT endpoint,
    /// and the output report's ID and length. Reads only — nothing is written to the keyboard. Blocks, so
    /// it runs off the main thread; the channel is made on the main actor.
    nonisolated static func open(_ service: io_service_t) -> Result<PipeWriter.Opened, Failure> {
        let interface: IOUSBHostInterface
        do {
            interface = try IOUSBHostInterface(__ioService: service, options: [], queue: nil, interestHandler: nil)
        } catch {
            return .failure(.failed(code(of: error)))
        }
        func fail(_ failure: Failure) -> Result<PipeWriter.Opened, Failure> {
            interface.destroy()
            return .failure(failure)
        }

        let number = Int(interface.interfaceDescriptor.pointee.bInterfaceNumber)
        let configuration = interface.configurationDescriptor
        let configurationBytes = Array(UnsafeRawBufferPointer(
            start: configuration, count: Int(UInt16(littleEndian: configuration.pointee.wTotalLength))))
        guard let summary = USBDescriptors.interface(number, inConfiguration: configurationBytes),
              let endpoint = summary.outEndpoint(preferring: nil),
              let length = summary.reportDescriptorLength, length > 0
        else { return fail(.failed(kIOReturnUnsupported)) }

        // GET_DESCRIPTOR for the interface's HID report descriptor — a standard read request.
        var request = IOUSBDeviceRequest()
        request.bmRequestType = 0x81
        request.bRequest = 6
        request.wValue = 0x22 << 8
        request.wIndex = UInt16(number)
        request.wLength = UInt16(length)
        guard let data = NSMutableData(length: length) else { return fail(.failed(kIOReturnNoMemory)) }
        var transferred = 0
        do {
            try interface.__send(request, data: data, bytesTransferred: &transferred, completionTimeout: 1)
        } catch {
            return fail(.failed(code(of: error)))
        }
        let reportDescriptor = Array(UnsafeRawBufferPointer(start: data.bytes, count: transferred))
        guard (HIDReportDescriptor.usagePage(in: reportDescriptor) ?? 0) >= 0xFF00 else { return fail(.notConfiguration) }
        guard let output = HIDReportDescriptor.firstOutputReport(in: reportDescriptor) else {
            return fail(.failed(kIOReturnUnsupported))
        }

        let pipe: IOUSBHostPipe
        do {
            pipe = try interface.copyPipe(withAddress: Int(endpoint.address))
        } catch {
            return fail(.failed(code(of: error)))
        }
        let framing = ReportFraming(reportID: output.id, length: output.length + (output.id == 0 ? 0 : 1))
        // bMaxPower is byte 8 of the configuration descriptor, in units of 2 mA.
        let maxPower = configurationBytes.count > 8 ? Int(configurationBytes[8]) * 2 : nil
        return .success(PipeWriter.Opened(
            writer: PipeWriter(interface: interface, pipe: pipe), framing: framing, interfaceNumber: number,
            outEndpoint: endpoint.address, maxPower: maxPower))
    }

    static func make(_ opened: PipeWriter.Opened) -> USBPipeChannel {
        USBPipeChannel(framing: opened.framing, pipe: opened.writer)
    }

    func write(_ report: [UInt8]) async throws(KeyboardDeviceError) {
        let status = await pipe.write(report)
        guard status == kIOReturnSuccess else { throw .writeFailed(code: status) }
    }

    func discardPendingReplies() {}

    func nextReply(timeout: Duration) async -> [UInt8]? { nil }

    func close() {
        pipe.close()
    }

    nonisolated static func code(of error: any Error) -> IOReturn {
        IOReturn(truncatingIfNeeded: (error as NSError).code)
    }
}

/// The interface and its OUT pipe. A write is enqueued on the pipe and ends when IOUSBHost hands back its
/// completion — no thread waits for it, so no thread waits on IOUSBHost's lower-priority queue. Each write's
/// state lives on `queue`, where the completions are brought.
final class PipeWriter: @unchecked Sendable {
    /// What opening the interface found.
    struct Opened: Sendable {
        var writer: PipeWriter
        var framing: ReportFraming
        var interfaceNumber: Int
        var outEndpoint: UInt8
        /// `bMaxPower` in mA.
        var maxPower: Int?
    }

    private let interface: IOUSBHostInterface
    private let pipe: IOUSBHostPipe
    private let queue = DispatchQueue(label: "MINIKeyboard.PipeWriter")

    init(interface: IOUSBHostInterface, pipe: IOUSBHostPipe) {
        self.interface = interface
        self.pipe = pipe
    }

    func write(_ report: [UInt8]) async -> IOReturn {
        await withCheckedContinuation { continuation in
            queue.async {
                self.start(Request(report) { continuation.resume(returning: $0) })
            }
        }
    }

    /// On `queue`. An interrupt pipe takes no completion timeout, so the Windows tool's 500 ms write timeout
    /// (`HidLib.WriteDevice`) is kept here: the request is aborted when it runs out, and the write ends when
    /// the aborted request comes back.
    private func start(_ request: Request) {
        do {
            try pipe.enqueueIORequest(with: request.data, completionTimeout: 0) { [queue] status, _ in
                queue.async { request.complete(status) }
            }
        } catch {
            request.complete(USBPipeChannel.code(of: error))
            return
        }
        queue.asyncAfter(deadline: .now() + 0.5) {
            guard request.runOut() else { return }
            try? self.pipe.__abort(with: .asynchronous)
        }
    }

    func close() {
        queue.async { self.interface.destroy() }
    }

    /// One write: its bytes, kept until the pipe is done with them, and who waits for its status. Touched
    /// only on `queue`.
    private final class Request: @unchecked Sendable {
        let data: NSMutableData
        private let done: @Sendable (IOReturn) -> Void
        private var isComplete = false
        private var isLate = false

        init(_ report: [UInt8], done: @escaping @Sendable (IOReturn) -> Void) {
            data = NSMutableData(bytes: report, length: report.count)
            self.done = done
        }

        func complete(_ status: IOReturn) {
            guard !isComplete else { return }
            isComplete = true
            done(isLate ? kIOReturnTimeout : status)
        }

        /// The time is up: true when the request is still out, and is to be aborted.
        func runOut() -> Bool {
            guard !isComplete else { return false }
            isLate = true
            return true
        }
    }
}
