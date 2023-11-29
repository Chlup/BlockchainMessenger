//
//  SDKSynchronizerClient.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 13.04.2022.
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

import Foundation
import Combine
import ComposableArchitecture
import ZcashLightClientKit
import Models

extension DependencyValues {
    public var sdkSynchronizer: SDKSynchronizerClient {
        get { self[SDKSynchronizerClient.self] }
        set { self[SDKSynchronizerClient.self] = newValue }
    }
}

@DependencyClient
public struct SDKSynchronizerClient {
    public var stateStream: () -> AnyPublisher<SynchronizerState, Never> = { Empty().eraseToAnyPublisher() }
    public var eventStream: () -> AnyPublisher<SynchronizerEvent, Never> = { Empty().eraseToAnyPublisher() }
    public var latestState: () -> SynchronizerState = { .zero }
    
    public var prepareWith: ([UInt8], BlockHeight, WalletInitMode) async throws -> Void
    public var start: (_ retry: Bool) async throws -> Void
    public var stop: () -> Void
    public var isSyncing: () -> Bool = { false }
    public var isInitialized: () -> Bool = { false }

    public var rewind: (RewindPolicy) -> AnyPublisher<Void, Error> = { _ in Empty().eraseToAnyPublisher() }

    public var getShieldedBalance: () -> WalletBalance?
    public var getTransparentBalance: () -> WalletBalance?
    public var getAllTransactions: () async throws -> [TransactionState]

    public var getMemos: (_ transactionRawID: Data) async throws -> [Memo]

    public var getUnifiedAddress: (_ account: Int) async throws -> UnifiedAddress?
    public var getTransparentAddress: (_ account: Int) async throws -> TransparentAddress?
    public var getSaplingAddress: (_ accountIndex: Int) async throws -> SaplingAddress?

    public var getTransaction: (_ rawID: Data) async throws -> ZcashTransaction.Overview?
    public var sendTransaction: (UnifiedSpendingKey, Zatoshi, Recipient, Memo?) async throws -> Data
//    public let shieldFunds: (UnifiedSpendingKey, Memo, Zatoshi) async throws -> TransactionState

    public var wipe: () -> AnyPublisher<Void, Error>?
}
