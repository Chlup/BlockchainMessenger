//
//  SDKSynchronizerLive.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 15.11.2022.
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
import DatabaseFiles
import Models
import ZcashSDKEnvironment

extension SDKSynchronizerClient {
    public static func live(
        databaseFiles: DatabaseFilesClient = .liveValue,
        environment: ZcashSDKEnvironment = .liveValue,
        network: ZcashNetwork
    ) -> Self {
        let initializer = Initializer(
            cacheDbURL: databaseFiles.cacheDbURLFor(network),
            fsBlockDbRoot: databaseFiles.fsBlockDbRootFor(network),
            generalStorageURL: databaseFiles.documentsDirectory(),
            dataDbURL: databaseFiles.dataDbURLFor(network),
            endpoint: environment.endpoint(network),
            network: network,
            spendParamsURL: databaseFiles.spendParamsURLFor(network),
            outputParamsURL: databaseFiles.outputParamsURLFor(network),
            saplingParamsSourceURL: SaplingParamsSourceURL.default,
            loggingPolicy: .default(.debug)
        )
        
        let synchronizer = SDKSynchronizer(initializer: initializer)

        return SDKSynchronizerClient(
            stateStream: { synchronizer.stateStream },
            eventStream: { synchronizer.eventStream },
            latestState: { synchronizer.latestState },
            prepareWith: { seedBytes, walletBirtday, walletMode in
                let result = try await synchronizer.prepare(with: seedBytes, walletBirthday: walletBirtday, for: walletMode)
                if result != .success { throw ZcashError.synchronizerNotPrepared }
            },
            start: { retry in try await synchronizer.start(retry: retry) },
            stop: { synchronizer.stop() },
            isSyncing: { synchronizer.latestState.syncStatus.isSyncing },
            isInitialized: { synchronizer.latestState.syncStatus != SyncStatus.unprepared },
            rewind: { synchronizer.rewind($0) },
            getShieldedBalance: { synchronizer.latestState.shieldedBalance },
            getTransparentBalance: { synchronizer.latestState.transparentBalance },
            getAllTransactions: {
                let clearedTransactions = try await synchronizer.allTransactions()

                var clearedTxs: [TransactionState] = []
                
                for clearedTransaction in clearedTransactions {
                    var transaction = TransactionState.init(
                        transaction: clearedTransaction,
                        memos: clearedTransaction.memoCount > 0 ? try await synchronizer.getMemos(for: clearedTransaction) : nil,
                        latestBlockHeight: try await SDKSynchronizerClient.latestBlockHeight(synchronizer: synchronizer)
                    )

                    let recipients = await synchronizer.getRecipients(for: clearedTransaction)
                    let addresses = recipients.compactMap {
                        if case let .address(address) = $0 {
                            return address
                        } else {
                            return nil
                        }
                    }
                    
                    transaction.zAddress = addresses.first?.stringEncoded
                    
                    clearedTxs.append(transaction)
                }
                
                return clearedTxs
            },
            getMemos: { try await synchronizer.getMemos(for: $0) },
            getUnifiedAddress: { try await synchronizer.getUnifiedAddress(accountIndex: $0) },
            getTransparentAddress: { try await synchronizer.getTransparentAddress(accountIndex: $0) },
            getSaplingAddress: { try await synchronizer.getSaplingAddress(accountIndex: $0) },
            getTransaction: { try await synchronizer.getTransaction(for: $0) },
            getTransactions: { try await synchronizer.getTransactions(from: $0) },
            sendTransaction: { spendingKey, amount, recipient, memo in
                let transaction = try await synchronizer.sendToAddress(
                    spendingKey: spendingKey,
                    zatoshi: amount,
                    toAddress: recipient,
                    memo: memo
                )
                return transaction.rawID
            },
//            shieldFunds: { spendingKey, memo, shieldingThreshold in
//                let pendingTransaction = try await synchronizer.shieldFunds(
//                    spendingKey: spendingKey,
//                    memo: memo,
//                    shieldingThreshold: shieldingThreshold
//                )
//                
//                return TransactionState(
//                    transaction: pendingTransaction,
//                    latestBlockHeight: try await SDKSynchronizerClient.latestBlockHeight(synchronizer: synchronizer)
//                )
//            },
            wipe: { synchronizer.wipe() }
        )
    }
}

// TODO: [#1313] SDK improvements so a client doesn't need to determing if the transaction isPending
// https://github.com/zcash/ZcashLightClientKit/issues/1313
// Once #1313 is done, cleint will no longer need to call for a `latestHeight()`
private extension SDKSynchronizerClient {
    static func latestBlockHeight(synchronizer: SDKSynchronizer) async throws -> BlockHeight {
        let latestBlockHeight: BlockHeight
        
        if synchronizer.latestState.latestBlockHeight > 0 {
            latestBlockHeight = synchronizer.latestState.latestBlockHeight
        } else {
            latestBlockHeight = try await synchronizer.latestHeight()
        }
        
        return latestBlockHeight
    }
}
