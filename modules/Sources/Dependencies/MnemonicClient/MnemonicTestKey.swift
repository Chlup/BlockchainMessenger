//
//  MnemonicTestKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 13.11.2022.
//

import ComposableArchitecture
import XCTestDynamicOverlay

extension MnemonicClient: TestDependencyKey {
    public static let previewValue = Self.noOp
    public static let testValue = Self()
}

extension MnemonicClient {
    public static let noOp = Self(
        randomMnemonic: { "" },
        randomMnemonicWords: { [] },
        toSeed: { _ in [] },
        asWords: { _ in [] },
        isValid: { _ in }
    )
}
