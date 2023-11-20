// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "modules",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "Chlup", targets: ["Chlup"]),
        .library(name: "CreateAccount", targets: ["CreateAccount"]),
        .library(name: "RestoreAccount", targets: ["RestoreAccount"]),
        .library(name: "Root", targets: ["Root"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.4.0"),
        .package(url: "https://github.com/zcash-hackworks/MnemonicSwift", from: "2.2.4"),
        .package(url: "https://github.com/Chlup/ZcashLightClientKit.git", branch: "blockchainmessenger")
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
            name: "Chlup",
            dependencies: [
                .product(name: "MnemonicSwift", package: "MnemonicSwift"),
                .product(name: "ZcashLightClientKit", package: "ZcashLightClientKit")
            ],
            path: "Sources/Chlup"
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
