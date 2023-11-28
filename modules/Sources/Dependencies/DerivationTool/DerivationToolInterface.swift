//
//  DerivationToolInterface.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 12.11.2022.
//
//  MIT License
//
//  Copyright (c) 2023 Zcash
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import ComposableArchitecture
import ZcashLightClientKit

extension DependencyValues {
    public var derivationTool: DerivationToolClient {
        get { self[DerivationToolClient.self] }
        set { self[DerivationToolClient.self] = newValue }
    }
}

@DependencyClient
public struct DerivationToolClient {
    /// Given a seed and a number of accounts, return the associated spending keys.
    /// - Parameter seed: the seed from which to derive spending keys.
    /// - Parameter accountIndex: Index of account to use. Multiple accounts are not fully
    /// supported so the default value of 0 is recommended.
    /// - Returns: the spending keys that correspond to the seed, formatted as Strings.
    public var deriveSpendingKey: ([UInt8], Int, NetworkType) throws -> UnifiedSpendingKey

    /// Given a unified spending key, returns the associated unified viewwing key.
    public var deriveUnifiedFullViewingKey: (UnifiedSpendingKey, NetworkType) throws -> UnifiedFullViewingKey
    
    /// Checks validity of the unified address.
    public var isUnifiedAddress: (String, NetworkType) -> Bool = { _, _ in false }

    /// Checks validity of the shielded address.
    public var isSaplingAddress: (String, NetworkType) -> Bool = { _, _ in false }

    /// Checks validity of the transparent address.
    public var isTransparentAddress: (String, NetworkType) -> Bool = { _, _ in false }

    /// Checks if given address is a valid zcash address.
    public var isZcashAddress: (String, NetworkType) -> Bool = { _, _ in false }
}
