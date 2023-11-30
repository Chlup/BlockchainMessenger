//
//  TransactionsProcessor.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 19.11.2023.
//
//  MIT License
//
//  Copyright (c) 2023 Mugeaters
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

import Combine
import Dependencies
import Foundation
import Logger
import ZcashLightClientKit

protocol TransactionsProcessor: Actor {
    func start() async
    func failureHappened() async
}

actor TransactionsProcessorImpl {
    private enum Constants {
        static let retriesCount = 1
    }

    private struct ProcessingItem {
        var transactionID: String { transaction.rawID.sha256 }
        let transaction: Transaction
        let failuresCount: Int
    }

    @Dependency(\.messagesStorage) var storage
    @Dependency(\.sdkManager) var sdkManager
    @Dependency(\.sdkSynchronizer) var synchronizer
    @Dependency(\.logger) var logger
    @Dependency(\.chatProtocol) var chatProtocol
    @Dependency(\.clearedHeightStorage) var clearedHeightStorage

    private var cancellables: [AnyCancellable] = []
    private var processing = false

    private func cancel() async {
        cancellables.forEach { $0.cancel() }
        cancellables = []
    }

    private func startProcessingTransactions() async {
        Task {
            logger.debug("Trying to start processing of transactions.")
            guard !processing else {
                logger.debug("Processing already in progress.")
                return
            }
            processing = true

            logger.debug("Processing transactions")

            var clearedHeight = clearedHeightStorage.clearedHeight()
            logger.debug("Cleared height: \(clearedHeight)")
            var recordClearedHeight = true
            var latestTransactionHeight: BlockHeight = clearedHeight
            var processedMinedTransactionsCount = 0

            do {
                logger.debug("Going to read transactions from height \(clearedHeight + 1)")
                let transactionsStream = try await synchronizer.getTransactionsToLastEnhancedHeight(clearedHeight + 1)
                var iterator = transactionsStream.makeAsyncIterator()

                do {
                    while let zcashTransaction = try await iterator.next() {
                        let transaction = Transaction(zcashTransaction: zcashTransaction)
                        logger.debug("Start processing transaction \(transaction.minedHeight) \(transaction.id)")
                        do {
                            if transaction.minedHeight != nil {
                                processedMinedTransactionsCount += 1
                            }

                            try await process(transaction: transaction)

                            if let height = transaction.minedHeight {
                                if (height - 1) > clearedHeight, recordClearedHeight {
                                    clearedHeightStorage.updateClearedHeight(height - 1)
                                    clearedHeight = clearedHeightStorage.clearedHeight()
                                    logger.debug("Recoding new cleared height: \(clearedHeight)")
                                }
                                latestTransactionHeight = height
                            }

                            logger.debug("Finished processing transaction \(transaction.minedHeight) \(transaction.id)")
                        } catch {
                            logger.error("Failed to process transaction: \(error)")
                            recordClearedHeight = false
                            continue
                        }
                    }

                    if recordClearedHeight, latestTransactionHeight > clearedHeight {
                        logger.debug("Recording new cleard heigh from last transaction: \(latestTransactionHeight)")
                        clearedHeightStorage.updateClearedHeight(latestTransactionHeight)
                    }
                } catch {
                    logger.error("Error while loading transations from DB. \(error)")
                }
            } catch {
                logger.error("Failed to get transactions stream. This is strange and bad. Something is wrong with SDK DB. \(error)")
            }

            logger.debug("Finished transactions processing")

            processing = false

            if processedMinedTransactionsCount > 0 {
                logger.debug("Scheduling another attempt to process transactions.")
                await startProcessingTransactions()
            }
        }
    }

    private func process(transaction: Transaction) async throws {
        // 1. check if transaction has memos
        // 2. get memos for transaction
        // 3. check if any memo contains chat messages
        // 4.
        //   - if transaction contains init message handle chat creation for that
        //   - if transaction continas message handle message creation
        logger.debug("\(transaction.id) Processing transaction")
        guard transaction.memoCount > 0 else {
            logger.debug("\(transaction.id) Transaction doesn't have any memo.")
            return
        }

        let memos: [Memo]
        do {
            memos = try await synchronizer.getMemos(transaction.rawID)
        } catch let ZcashError.transactionRepositoryFindMemos(underlyingError) {
            logger.error("Failed to get memos for transaction: \(transaction.id) \(underlyingError)")
            throw ZcashError.transactionRepositoryFindMemos(underlyingError)
        } catch {
            logger.error("Failed to get memos for transaction: \(transaction.id) \(error)")
            return
        }

        guard let decodedMessage = processMemos(memos) else {
            logger.debug("\(transaction.id) Can't get memo for transaction.")
            return
        }

        logger.debug("\(decodedMessage)")

        switch decodedMessage.content {
        case let .initialisation(fromAddress, toAddress, verificationText):
            try await processInitialisationMessage(
                decodedMessage,
                alias: nil,
                fromAddress: fromAddress,
                toAddress: toAddress,
                verificationText: verificationText
            )
        case let .text(text):
            try await processTextMessage(decodedMessage, text: text, transaction: transaction)
        }
    }

    private func processInitialisationMessage(
        _ message: ChatProtocol.ChatMessage,
        alias: String?,
        fromAddress: String,
        toAddress: String,
        verificationText: String
    ) async throws {
        let doestChatExists = try await storage.doesChatExists(for: message.chatID)
        guard !doestChatExists else {
            logger.debug("Chat already exists for this init message. \(message.content)")
            return
        }

        let myUnifiedAddress: String
        do {
            guard let possibleUnifiedAddress = try await synchronizer.getUnifiedAddress(account: 0) else { return }
            myUnifiedAddress = possibleUnifiedAddress.stringEncoded
        } catch {
            logger.debug("Can't get unifiead address \(error)")
            throw error
        }

        let amICreatorOfChat = myUnifiedAddress == fromAddress

        let newChat = Chat(
            alias: alias,
            chatID: message.chatID,
            timestamp: message.timestmap,
            fromAddress: fromAddress,
            toAddress: toAddress,
            verificationText: verificationText,
            // When current seed is creator of chat then chat is verified on it's side because there is nothing to verify. The other side must
            // recieve `verificationText` through different channel and verify this chat.
            verified: amICreatorOfChat
        )

        do {
            try await storage.storeChat(newChat)
        } catch {
            logger.error("Failed to store new chat from processed transaction into DB: \(error)")
            throw error
        }
    }

    private func processTextMessage(_ message: ChatProtocol.ChatMessage, text: String, transaction: Transaction) async throws {
        let doesMessageExists = try await storage.doesMessageExists(for: message.messageID)
        guard !doesMessageExists else {
            logger.debug("Message already exists for this transaction. \(message.content) \(transaction.id)")
            return
        }

        let newMessage = Message(
            id: message.messageID,
            chatID: message.chatID,
            timestamp: message.timestmap,
            text: text,
            isSent: transaction.isSentTransaction
        )

        do {
            try await storage.storeMessage(newMessage)
        } catch {
            logger.error("Failed to store new message from processed transaction into DB: \(error)")
            throw error
        }
    }

    private func processMemos(_ memos: [Memo]) -> ChatProtocol.ChatMessage? {
        for memo in memos {
            do {
                let memoBytes = try memo.asMemoBytes().bytes
                return try chatProtocol.decode(memoBytes)
            } catch {
                continue
            }
        }

        return nil
    }
}

extension TransactionsProcessorImpl: TransactionsProcessor {
    func start() async {
        await cancel()
        sdkManager.importantSDKEventsStream
            .sink(
                receiveValue: { [weak self] _ in
                    // Strange hack. If self?.process... is used then compiler throws:
                    // "Reference to captured var 'self' in concurrently-executing code" error.
                    let me = self
                    Task {
                        await me?.startProcessingTransactions()
                    }
                }
            )
            .store(in: &cancellables)
    }

    func failureHappened() async {
        await startProcessingTransactions()
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
