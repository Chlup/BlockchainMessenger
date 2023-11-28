//
//  SDKSynchronizerClient.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 13.04.2022.
//

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
//    public var getAllTransactions: () async throws -> [TransactionState]

    public var getMemos: (_ transactionRawID: Data) async throws -> [Memo]

    public var getUnifiedAddress: (_ account: Int) async throws -> UnifiedAddress?
    public var getTransparentAddress: (_ account: Int) async throws -> TransparentAddress?
    public var getSaplingAddress: (_ accountIndex: Int) async throws -> SaplingAddress?

    public var sendTransaction: (UnifiedSpendingKey, Zatoshi, Recipient, Memo?) async throws -> Void
//    public let shieldFunds: (UnifiedSpendingKey, Memo, Zatoshi) async throws -> TransactionState

    public var wipe: () -> AnyPublisher<Void, Error>?
}
