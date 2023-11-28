//
//  DerivationToolLiveKey.swift
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

extension DerivationToolClient: DependencyKey {
    public static let liveValue = DerivationToolClient.live()
        
    public static func live() -> Self {
        Self(
            deriveSpendingKey: { seed, accountIndex, networkType in
                try DerivationTool(networkType: networkType).deriveUnifiedSpendingKey(seed: seed, accountIndex: accountIndex)
            },
            deriveUnifiedFullViewingKey: { spendingKey, networkType in
                try DerivationTool(networkType: networkType).deriveUnifiedFullViewingKey(from: spendingKey)
            },
            isUnifiedAddress: { address, networkType in
                do {
                    if case .unified = try Recipient(address, network: networkType) {
                        return true
                    } else {
                        return false
                    }
                } catch {
                    return false
                }
            },
            isSaplingAddress: { address, networkType in
                do {
                    if case .sapling = try Recipient(address, network: networkType) {
                        return true
                    } else {
                        return false
                    }
                } catch {
                    return false
                }
            },
            isTransparentAddress: { address, networkType in
                do {
                    if case .transparent = try Recipient(address, network: networkType) {
                        return true
                    } else {
                        return false
                    }
                } catch {
                    return false
                }
            },
            isZcashAddress: { address, networkType in
                do {
                    _ = try Recipient(address, network: networkType)
                    return true
                } catch {
                    return false
                }
            }
        )
    }
}
