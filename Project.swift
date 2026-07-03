import ProjectDescription

let project = Project(
    name: "SpendMind",
    packages: [],
    settings: .settings(
        base: [
            "IPHONEOS_DEPLOYMENT_TARGET": "18.0",
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
                "UILaunchScreen": [:]
            ]),
            sources: ["SpendMind/**"],
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
    ]
)
