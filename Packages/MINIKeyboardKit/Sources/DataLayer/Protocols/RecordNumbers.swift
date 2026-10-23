import Domain

/// The record each control of the cross-platform app's layouts is stored in on a 884x keyboard: a key in
/// the record of its number, a knob action where the app puts it. In 0add1, records 19 and 21 turn its one
/// knob while it is pressed — a second knob would have its press in record 20, as in 0add2.
enum RecordNumbers {
    static func record(of control: ControlID, in layout: KeyboardLayout) -> Int? {
        guard layout.controls.contains(control) else { return nil }
        switch control {
        case .key(let number): return number
        case .knob: return knobs[layout.id]?[control]
        }
    }

    /// The control stored in `record`, or nil when the layout has none there.
    static func control(inRecord record: Int, of layout: KeyboardLayout) -> ControlID? {
        layout.controls.first { self.record(of: $0, in: layout) == record }
    }

    private static let knobs: [String: [ControlID: Int]] = [
        "0add1": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
            .knob(number: 1, part: .pressRotateLeft): 19,
            .knob(number: 1, part: .pressRotateRight): 21,
        ],
        "0add2": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
            .knob(number: 2, part: .rotateLeft): 19,
            .knob(number: 2, part: .press): 20,
            .knob(number: 2, part: .rotateRight): 21,
        ],
        "0add3": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
            .knob(number: 2, part: .rotateLeft): 19,
            .knob(number: 2, part: .press): 20,
            .knob(number: 2, part: .rotateRight): 21,
            .knob(number: 3, part: .rotateLeft): 22,
            .knob(number: 3, part: .press): 23,
            .knob(number: 3, part: .rotateRight): 24,
        ],
        "3add1": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
        ],
        "4add1": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
        ],
        "4add2": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
        ],
        "4add3": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
            .knob(number: 2, part: .rotateLeft): 19,
            .knob(number: 2, part: .press): 20,
            .knob(number: 2, part: .rotateRight): 21,
            .knob(number: 3, part: .rotateLeft): 22,
            .knob(number: 3, part: .press): 23,
            .knob(number: 3, part: .rotateRight): 24,
        ],
        "6add1": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
        ],
        "6add2": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
            .knob(number: 2, part: .rotateLeft): 19,
            .knob(number: 2, part: .press): 20,
            .knob(number: 2, part: .rotateRight): 21,
        ],
        "9add2": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
            .knob(number: 2, part: .rotateLeft): 19,
            .knob(number: 2, part: .press): 20,
            .knob(number: 2, part: .rotateRight): 21,
        ],
        "9add3": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
            .knob(number: 2, part: .rotateLeft): 19,
            .knob(number: 2, part: .press): 20,
            .knob(number: 2, part: .rotateRight): 21,
            .knob(number: 3, part: .rotateLeft): 22,
            .knob(number: 3, part: .press): 23,
            .knob(number: 3, part: .rotateRight): 24,
        ],
        "11add3": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
            .knob(number: 2, part: .rotateLeft): 19,
            .knob(number: 2, part: .press): 20,
            .knob(number: 2, part: .rotateRight): 21,
            .knob(number: 3, part: .rotateLeft): 22,
            .knob(number: 3, part: .press): 23,
            .knob(number: 3, part: .rotateRight): 24,
        ],
        "12add2": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
            .knob(number: 2, part: .rotateLeft): 19,
            .knob(number: 2, part: .press): 20,
            .knob(number: 2, part: .rotateRight): 21,
        ],
        "12add3": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
            .knob(number: 2, part: .rotateLeft): 19,
            .knob(number: 2, part: .press): 20,
            .knob(number: 2, part: .rotateRight): 21,
            .knob(number: 3, part: .rotateLeft): 22,
            .knob(number: 3, part: .press): 23,
            .knob(number: 3, part: .rotateRight): 24,
        ],
        "12add4": [
            .knob(number: 4, part: .rotateLeft): 13,
            .knob(number: 4, part: .press): 14,
            .knob(number: 4, part: .rotateRight): 15,
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
            .knob(number: 2, part: .rotateLeft): 19,
            .knob(number: 2, part: .press): 20,
            .knob(number: 2, part: .rotateRight): 21,
            .knob(number: 3, part: .rotateLeft): 22,
            .knob(number: 3, part: .press): 23,
            .knob(number: 3, part: .rotateRight): 24,
        ],
        "15add3": [
            .knob(number: 1, part: .rotateLeft): 16,
            .knob(number: 1, part: .press): 17,
            .knob(number: 1, part: .rotateRight): 18,
            .knob(number: 2, part: .rotateLeft): 19,
            .knob(number: 2, part: .press): 20,
            .knob(number: 2, part: .rotateRight): 21,
            .knob(number: 3, part: .rotateLeft): 22,
            .knob(number: 3, part: .press): 23,
            .knob(number: 3, part: .rotateRight): 24,
        ],
        "16add3": [
            .knob(number: 1, part: .rotateLeft): 17,
            .knob(number: 1, part: .press): 18,
            .knob(number: 1, part: .rotateRight): 19,
            .knob(number: 2, part: .rotateLeft): 20,
            .knob(number: 2, part: .press): 21,
            .knob(number: 2, part: .rotateRight): 22,
            .knob(number: 3, part: .rotateLeft): 23,
            .knob(number: 3, part: .press): 24,
            .knob(number: 3, part: .rotateRight): 25,
        ],
        "21add1": [
            .knob(number: 1, part: .rotateRight): 22,
            .knob(number: 1, part: .press): 23,
            .knob(number: 1, part: .rotateLeft): 24,
        ],
    ]
}
