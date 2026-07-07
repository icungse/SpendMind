import ProjectDescription

let project = Project(
    name: "SpendMind",
    packages: [],
    settings: .settings(
        base: [
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            "CLANG_ENABLE_MODULE_VERIFIER": "YES",
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": "1",
            "ENABLE_MODULE_VERIFIER": "YES",
            "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
            "IPHONEOS_DEPLOYMENT_TARGET": "18.0",
            "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
            "MARKETING_VERSION": "0.1.0",
            "MODULE_VERIFIER_SUPPORTED_LANGUAGES": "objective-c objective-c++",
            "MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS": "gnu17 gnu++20",
            "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
            "SWIFT_VERSION": "6.0"
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release")
        ]
    ),
    targets: [
        .target(
            name: "SpendMind",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.spendmind.app",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "UILaunchScreen": [
                    "UIColorName": "LaunchBackground"
                ],
                "UIAppFonts": [
                    "Poppins-Regular.ttf",
                    "Poppins-Medium.ttf",
                    "Poppins-SemiBold.ttf",
                    "Poppins-Bold.ttf",
                    "Poppins-Black.ttf"
                ]
            ]),
            sources: ["SpendMind/**"],
            resources: [
                "SpendMind/Resources/**",
                "SpendMind/Shared/Fonts/**"
            ],
            dependencies: [
                .external(name: "Algorithms"),
                .external(name: "Collections")
            ]
        ),
        .target(
            name: "SpendMindTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.spendmind.tests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["SpendMindTests/**"],
            resources: ["SpendMindTests/__Snapshots__/**"],
            dependencies: [.target(name: "SpendMind")]
        ),
        .target(
            name: "SpendMindUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "dev.spendmind.uitests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["SpendMindUITests/**"],
            dependencies: [.target(name: "SpendMind")]
        )
    ],
    schemes: [
        .scheme(
            name: "SpendMind",
            shared: true,
            buildAction: .buildAction(targets: ["SpendMind"]),
            testAction: .targets(
                [
                    "SpendMindTests",
                    "SpendMindUITests"
                ],
                arguments: .arguments(environmentVariables: [
                    "PROJECT_DIR": "$(PROJECT_DIR)"
                ]),
                options: .options(
                    coverage: true,
                    codeCoverageTargets: [.target("SpendMind")]
                )
            ),
            runAction: .runAction(executable: "SpendMind")
        )
    ]
)
