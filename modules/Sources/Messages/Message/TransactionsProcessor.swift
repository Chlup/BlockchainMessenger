//
//  TransactionsProcessor.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 19.11.2023.
//

import Foundation
import Combine
import ZcashLightClientKit
import Dependencies

protocol TransactionsProcessor {
    func start()
}

final class TransactionsProcessorImpl {
    private var cancellables: [AnyCancellable] = []
    @Dependency(\.messagesStorage) var storage
    @Dependency(\.sdkManager) var sdkManager
    @Dependency(\.logger) var logger

    init() {
    }

    deinit {
        cancel()
    }

    private func cancel() {
        cancellables.forEach { $0.cancel() }
        cancellables = []
    }

    private func process(transactions: [Transaction]) async {
        logger.debug("Processing received transactions")
        for transaction in transactions {
            logger.debug("processing transaction \(transaction)")
            do {
                try await storage.store(transaction: transaction)
            } catch {
                logger.debug("Failed to store transaction: \(error) \(transaction)")
            }
        }
    }
}

extension TransactionsProcessorImpl: TransactionsProcessor {
    func start() {
        cancel()
        sdkManager.transactionsStream
            .sink(
                receiveValue: { [weak self] transactions in
                    self?.logger.debug("Found transactions !!! \(transactions.count)")
                    // Strange hack. If self?.process... is used then compiler throws:
                    // "Reference to captured var 'self' in concurrently-executing code" error.
                    let me = self
                    Task {
                        await me?.process(transactions: transactions)
                    }
                }
            )
            .store(in: &cancellables)
    }
}

private enum TransactionsProcessorClientKey: DependencyKey {
    static let liveValue: TransactionsProcessor = TransactionsProcessorImpl()
}

extension DependencyValues {
    var transactionsProcessor: TransactionsProcessor {
        get { self[TransactionsProcessorClientKey.self] }
        set { self[TransactionsProcessorClientKey.self] = newValue }
    }
}
