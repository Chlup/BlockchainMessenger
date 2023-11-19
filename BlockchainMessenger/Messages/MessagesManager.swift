//
//  MessagesManager.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 19.11.2023.
//

import Foundation
import Combine
import ZcashLightClientKit

protocol MessagesManager {
    func start()
}

final class MessagesManagerImpl {
    private var cancellables: [AnyCancellable] = []
    private let storage: MessagesStorage

    let stream: AnyPublisher<[Transaction], Never>
    init(synchronizer: Synchronizer, foundTransactionsStream stream: AnyPublisher<[Transaction], Never>) {
        self.stream = stream
        // DI should be used
        self.storage = MessagesStorageImpl(synchronizer: synchronizer)
    }

    deinit {
        cancel()
    }

    private func cancel() {
        cancellables.forEach { $0.cancel() }
        cancellables = []
    }

    private func process(transactions: [Transaction]) async {
        print("Processing received transactions")
        for transaction in transactions {
            print("processing transaction \(transaction)")
            do {
                try await storage.store(transaction: transaction)
            } catch {
                print("Failed to store transaction: \(error) \(transaction)")
            }
        }
    }
}

extension MessagesManagerImpl: MessagesManager {
    func start() {
        cancel()
        stream
            .sink(
                receiveValue: { [weak self] transactions in
                    print("Found transactions !!! \(transactions.count)")
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
