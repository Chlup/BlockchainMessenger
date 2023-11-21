// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "modules",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "Messages", targets: ["Messages"]),
        .library(name: "CreateAccount", targets: ["CreateAccount"]),
        .library(name: "RestoreAccount", targets: ["RestoreAccount"]),
        .library(name: "Root", targets: ["Root"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.4.0"),
        .package(url: "https://github.com/zcash-hackworks/MnemonicSwift", exact: "2.2.4"),
        .package(url: "https://github.com/Chlup/ZcashLightClientKit.git", branch: "blockchainmessenger"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", exact: "1.1.1"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", exact: "0.14.1")
    ],
    targets: [
        .target(
            name: "CreateAccount",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Features/CreateAccount"
        ),
        .target(
            name: "Messages",
            dependencies: [
                .product(name: "MnemonicSwift", package: "MnemonicSwift"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources/Messages"
        ),
        .target(
            name: "RestoreAccount",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Features/RestoreAccount"
        ),
        .target(
            name: "Root",
            dependencies: [
                "CreateAccount",
                "RestoreAccount",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/Features/Root"
        )
    ]
)
