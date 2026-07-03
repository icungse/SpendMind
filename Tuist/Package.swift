// swift-tools-version: 6.0

import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    baseSettings: .settings(base: [
        "LIBTOOLFLAGS": "-no_warning_for_no_symbols"
    ])
)
#endif

let package = Package(
    name: "SpendMindDependencies",
    platforms: [.iOS(.v18)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.1")
    ]
)
