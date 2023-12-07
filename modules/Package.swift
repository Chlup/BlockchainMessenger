// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "modules",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "ChatDetail", targets: ["ChatDetail"]),
        .library(name: "ChatsList", targets: ["ChatsList"]),
        .library(name: "ChatVerification", targets: ["ChatVerification"]),
        .library(name: "CreateAccount", targets: ["CreateAccount"]),
        .library(name: "DatabaseFiles", targets: ["DatabaseFiles"]),
        .library(name: "DerivationTool", targets: ["DerivationTool"]),
        .library(name: "FileManager", targets: ["FileManager"]),
        .library(name: "Funds", targets: ["Funds"]),
        .library(name: "Messages", targets: ["Messages"]),
        .library(name: "MnemonicClient", targets: ["MnemonicClient"]),
        .library(name: "Models", targets: ["Models"]),
        .library(name: "NewChat", targets: ["NewChat"]),
        .library(name: "Pasteboard", targets: ["Pasteboard"]),
        .library(name: "RestoreAccount", targets: ["RestoreAccount"]),
        .library(name: "Root", targets: ["Root"]),
        .library(name: "SDKSynchronizer", targets: ["SDKSynchronizer"]),
        .library(name: "SecItem", targets: ["SecItem"]),
        .library(name: "Utils", targets: ["Utils"]),
        .library(name: "VerifyChat", targets: ["VerifyChat"]),
        .library(name: "WalletStorage", targets: ["WalletStorage"]),
        .library(name: "ZcashSDKEnvironment", targets: ["ZcashSDKEnvironment"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.5.1"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths", exact: "1.1.1"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", exact: "1.1.1"),
        .package(url: "https://github.com/zcash-hackworks/MnemonicSwift", exact: "2.2.4"),
        .package(url: "https://github.com/Chlup/ZcashLightClientKit.git", revision: "aa205d0b175f1e29761b80e295c793bece6468ae"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", exact: "0.14.1"),
        .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", exact: "6.6.2"),
        .package(url: "https://github.com/realm/SwiftLint.git", exact: "0.54.0")
    ],
    targets: [
        .target(
            name: "ChatDetail",
            dependencies: [
                "DerivationTool",
                "Generated",
                "Logger",
                "Messages",
                "SDKSynchronizer",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/ChatDetail",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "ChatsList",
            dependencies: [
                "ChatDetail",
                "Funds",
                "Logger",
                "Messages",
                "Models",
                "NewChat",
                "SDKSynchronizer",
                "TransactionsDebug",
                "Utils",
                "VerifyChat",
                "WalletStorage",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/ChatsList",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "ChatVerification",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/ChatVerification",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "CreateAccount",
            dependencies: [
                "Logger",
                "Models",
                "Pasteboard",
                "Utils",
                "WalletStorage",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Features/CreateAccount",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "DatabaseFiles",
            dependencies: [
                "FileManager",
                "Logger",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Dependencies/DatabaseFiles",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "DerivationTool",
            dependencies: [
                "Logger",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Dependencies/DerivationTool",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "FileManager",
            dependencies: [
                "Logger",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/FileManager",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "Funds",
            dependencies: [
                "DerivationTool",
                "Generated",
                "Logger",
                "Messages",
                "Pasteboard",
                "SDKSynchronizer",
                "Utils",
                "WalletStorage",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/Funds",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "Logger",
            dependencies: [
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Dependencies/Logger",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "Generated",
            resources: [.process("Resources")],
            plugins: [
                .plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin")
            ]
        ),
        .target(
            name: "Messages",
            dependencies: [
                "Logger",
                "SDKSynchronizer",
                .product(name: "MnemonicSwift", package: "MnemonicSwift"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources/Messages",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "MnemonicClient",
            dependencies: [
                "Logger",
                .product(name: "MnemonicSwift", package: "MnemonicSwift"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/MnemonicClient",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "Models",
            dependencies: [
                "Logger",
                "Utils",
                .product(name: "MnemonicSwift", package: "MnemonicSwift")
            ],
            path: "Sources/Models",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "NewChat",
            dependencies: [
                "ChatVerification",
                "DerivationTool",
                "Logger",
                "Messages",
                "SDKSynchronizer",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Features/NewChat",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "Pasteboard",
            dependencies: [
                "Logger",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/Pasteboard",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "RestoreAccount",
            dependencies: [
                "Logger",
                "MnemonicClient",
                "Utils",
                "WalletStorage",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/RestoreAccount",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "Root",
            dependencies: [
                "ChatsList",
                "CreateAccount",
                "DatabaseFiles",
                "Generated",
                "Logger",
                "Messages",
                "MnemonicClient",
                "Models",
                "RestoreAccount",
                "SDKSynchronizer",
                "WalletStorage",
                "ZcashSDKEnvironment",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Features/Root",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "SDKSynchronizer",
            dependencies: [
                "DatabaseFiles",
                "Logger",
                "Models",
                "ZcashSDKEnvironment",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Dependencies/SDKSynchronizer",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "SecItem",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/SecItem",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "TransactionsDebug",
            dependencies: [
                "Logger",
                "Messages",
                "SDKSynchronizer",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Features/TransactionsDebug",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "Utils",
            dependencies: [
                "Generated",
                "Logger",
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit"),
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Utils",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "VerifyChat",
            dependencies: [
                "DerivationTool",
                "Logger",
                "Messages",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Features/VerifyChat",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "WalletStorage",
            dependencies: [
                "Logger",
                "MnemonicClient",
                "Models",
                "SecItem",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Dependencies/WalletStorage",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "ZcashSDKEnvironment",
            dependencies: [
                "Logger",
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Dependencies/ZcashSDKEnvironment",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        )
    ]
)
