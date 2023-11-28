//
//  WalletStorageTestKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 14.11.2022.
//

import ComposableArchitecture
import XCTestDynamicOverlay

extension WalletStorageClient: TestDependencyKey {
    public static let previewValue = Self.noOp
    public static let testValue = Self()
}

extension WalletStorageClient {
    public static let noOp = Self(
        importWallet: { _, _, _, _ in },
        exportWallet: { .placeholder },
        areKeysPresent: { false },
        updateBirthday: { _ in },
        markUserPassedPhraseBackupTest: { _ in },
        nukeWallet: { }
    )
}
