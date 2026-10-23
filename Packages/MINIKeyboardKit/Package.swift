// swift-tools-version: 6.2
import PackageDescription

// The configurator's layers. Dependencies point inwards — DataLayer → Domain ← Presentation — so a
// layer that reaches outwards does not compile. The app target holds the SwiftUI views and the
// composition root, and links all three.
let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "MINIKeyboardKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "DataLayer", targets: ["DataLayer"]),
        .library(name: "Presentation", targets: ["Presentation"]),
    ],
    targets: [
        .target(name: "Domain", swiftSettings: strict),
        .target(
            name: "DataLayer",
            dependencies: ["Domain"],
            // The simulated keyboards are compiled into debug builds only.
            swiftSettings: strict + [.define("DEBUG", .when(configuration: .debug))],
            linkerSettings: [.linkedFramework("IOKit"), .linkedFramework("IOUSBHost")]),
        .target(name: "Presentation", dependencies: ["Domain"], swiftSettings: strict),
        .testTarget(name: "DomainTests", dependencies: ["Domain"], swiftSettings: strict),
        .testTarget(
            name: "DataLayerTests", dependencies: ["DataLayer", "Domain"],
            swiftSettings: strict + [.define("DEBUG", .when(configuration: .debug))]),
        .testTarget(name: "PresentationTests", dependencies: ["Presentation", "Domain"], swiftSettings: strict),
    ]
)
