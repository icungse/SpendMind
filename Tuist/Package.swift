// swift-tools-version: 6.0

import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    baseSettings: .settings(base: [
        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
        "CLANG_ENABLE_MODULE_VERIFIER": "YES",
        "ENABLE_MODULE_VERIFIER": "YES",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        "LIBTOOLFLAGS": "-no_warning_for_no_symbols",
        "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
        "MODULE_VERIFIER_SUPPORTED_LANGUAGES": "objective-c objective-c++",
        "MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS": "gnu17 gnu++20",
        "STRING_CATALOG_GENERATE_SYMBOLS": "YES"
    ])
)
#endif

let package = Package(
    name: "VeyraDependencies",
    platforms: [.iOS(.v18)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.1")
    ]
)
