//
//  SDKManager.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 19.11.2023.
//

import Foundation
import ZcashLightClientKit
import MnemonicSwift
import Combine
import Dependencies

protocol SDKManager: AnyObject {
    var transactionsStream: AnyPublisher<[Transaction], Never> { get }
    
    func start(with seed: String, birthday: BlockHeight, walletMode: WalletInitMode) async throws
}

final class SDKManagerImpl {
    enum Errors: Error {
        case synchronizerInitFailed(Initializer.InitializationResult)
    }

    private enum Constants {
    }

    private var cancellables: [AnyCancellable] = []

    var transactionsStream: AnyPublisher<[Transaction], Never> {
        return synchronizer.eventStream
            .compactMap { event in
                switch event {
                case let .foundTransactions(transactions, _):
                    return transactions.map { Transaction(zcashTransaction: $0) }
                default:
                    return nil
                }
            }
            .share()
            .eraseToAnyPublisher()
    }

    @Dependency(\.sdkSynchronizer) var synchronizer

    init() {
    }

    // MARK: - Subscribe to SDK combine API

    private func subscribeToSynchronizer() {
        cancellables.forEach { $0.cancel() }
        cancellables = []
        synchronizer.stateStream
            .sink(
                receiveValue: { state in
                    print("State:\n\(state)")
                }
            )
            .store(in: &cancellables)

        synchronizer.eventStream
            .sink(
                receiveValue: { event in
                    switch event {
                    case .foundTransactions:
                        print("Found transactions !!! Manager")
                    default:
                        break
                    }
                    print("Event:\n\(event)")
                }
            )
            .store(in: &cancellables)
    }
}

extension SDKManagerImpl: SDKManager {
    func start(with seed: String, birthday: BlockHeight, walletMode: WalletInitMode) async throws {
        if synchronizer.latestState.syncStatus == .unprepared {
            let seedBytes = try Mnemonic.deterministicSeedBytes(from: seed)
            let result = try await synchronizer.prepare(with: seedBytes, walletBirthday: birthday, for: walletMode)
            if result != .success {
                throw Errors.synchronizerInitFailed(result)
            }
        }

        subscribeToSynchronizer()
        try await synchronizer.start(retry: false)
    }
}

private enum SDKManagerKey: DependencyKey {
    static let liveValue: SDKManager = SDKManagerImpl()
}

extension DependencyValues {
    var sdkManager: SDKManager {
        get { self[SDKManagerKey.self] }
        set { self[SDKManagerKey.self] = newValue }
    }
}
