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

public protocol SDKManager: AnyObject {
    func start(with seed: String, birthday: BlockHeight, walletMode: WalletInitMode) async throws
}

public final class SDKManagerImpl {
    enum Errors: Error {
        case synchronizerInitFailed(Initializer.InitializationResult)
    }

    private enum Constants {
        static let zcashNetwork = ZcashNetworkBuilder.network(for: .testnet)
        static let host = /*ZcashSDK.isMainnet ? "mainnet.lightwalletd.com" : */"lightwalletd.testnet.electriccoin.co"
        static let port: Int = 9067
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
            .eraseToAnyPublisher()
    }

    let synchronizer: SDKSynchronizer
    public init() {
        // We need to use some kind of DI here in future
        let initializer = Initializer(
            cacheDbURL: nil,
            fsBlockDbRoot: Self.fsBlockDbRootURLHelper(),
            generalStorageURL: Self.generalStorageURLHelper(),
            dataDbURL: Self.dataDbURLHelper(),
            endpoint: LightWalletEndpoint(address: Constants.host, port: Constants.port, secure: true, streamingCallTimeoutInMillis: 10 * 60 * 60 * 1000),
            network: Constants.zcashNetwork,
            spendParamsURL: Self.spendParamsURLHelper(),
            outputParamsURL: Self.outputParamsURLHelper(),
            saplingParamsSourceURL: SaplingParamsSourceURL.default,
            enableBackendTracing: true
        )

        synchronizer = SDKSynchronizer(initializer: initializer)
    }

    // MARK: - SDK init helpers

    static private func documentsDirectoryHelper() -> URL {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            // This is not super clean but this is second best thing when the above call fails.
            return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
        }
    }

    static private func fsBlockDbRootURLHelper() -> URL {
        Self.documentsDirectoryHelper()
            .appendingPathComponent(SDKManagerImpl.Constants.zcashNetwork.networkType.chainName)
            .appendingPathComponent(
                ZcashSDK.defaultFsCacheName,
                isDirectory: true
            )
    }

    static private func generalStorageURLHelper() -> URL {
        Self.documentsDirectoryHelper()
            .appendingPathComponent(SDKManagerImpl.Constants.zcashNetwork.networkType.chainName)
            .appendingPathComponent(
                "general_storage",
                isDirectory: true
            )
    }

    static private func cacheDbURLHelper() -> URL {
        Self.documentsDirectoryHelper()
            .appendingPathComponent(
                SDKManagerImpl.Constants.zcashNetwork.constants.defaultDbNamePrefix + ZcashSDK.defaultCacheDbName,
                isDirectory: false
            )
    }

    static private func dataDbURLHelper() -> URL {
        Self.documentsDirectoryHelper()
            .appendingPathComponent(
                SDKManagerImpl.Constants.zcashNetwork.constants.defaultDbNamePrefix + ZcashSDK.defaultDataDbName,
                isDirectory: false
            )
    }

    private static func spendParamsURLHelper() -> URL {
        Self.documentsDirectoryHelper().appendingPathComponent("sapling-spend.params")
    }

    private static func outputParamsURLHelper() -> URL {
        Self.documentsDirectoryHelper().appendingPathComponent("sapling-output.params")
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
    public func start(with seed: String, birthday: BlockHeight, walletMode: WalletInitMode) async throws {
        if synchronizer.latestState.syncStatus == .unprepared {
            let seedBytes = try Mnemonic.deterministicSeedBytes(from: seed)
            let result = try await synchronizer.prepare(with: seedBytes, walletBirthday: birthday, for: walletMode)
            if result != .success {
                throw Errors.synchronizerInitFailed(result)
            }
        }

        subscribeToSynchronizer()
        try await synchronizer.start()
    }
}
