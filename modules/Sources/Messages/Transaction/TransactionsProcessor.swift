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
import Logger
import Foundation
import ZcashLightClientKit

protocol TransactionsProcessor: Actor {
    func start() async
}

actor TransactionsProcessorImpl {
    private var cancellables: [AnyCancellable] = []
    @Dependency(\.messagesStorage) var storage
    @Dependency(\.sdkManager) var sdkManager
    @Dependency(\.sdkSynchronizer) var synchronizer
    @Dependency(\.logger) var logger
    @Dependency(\.chatProtocol) var chatProtokol

    private func cancel() async {
        cancellables.forEach { $0.cancel() }
        cancellables = []
    }

    private func process(transactions: [Transaction]) async {
        logger.debug("Processing received transactions")
        for transaction in transactions {
            logger.debug("processing transaction \(transaction)")
            do {
                try await process(transaction: transaction)
            } catch {
                logger.debug("Failed to store transaction: \(error) \(transaction)")
            }
        }
    }

    private func process(transaction: Transaction) async throws {
        // 1. check if transaction has memos
        // 2. get first memo for transaction
        // 3. check if memo contains chat messages
        // 4.
        //   - if transaction contains init message handle chat creation for that
        //   - if transaction continas message handle message creation
        logger.debug("\(transaction.id) Processing transaction")
        guard transaction.memoCount > 0 else {
            logger.debug("\(transaction.id) Transaction doesn't have any memo.")
            return
        }

        guard let memo = try await synchronizer.getMemos(transaction.rawID).first else {
            logger.debug("\(transaction.id) Can't get memo for transaction.")
            return
        }

        let memoBytes = try memo.asMemoBytes().bytes
        let decodedMessage = try chatProtokol.decode(memoBytes)

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

        let newChat = Chat(
            alias: alias,
            chatID: message.chatID,
            timestamp: message.timestmap,
            fromAddress: fromAddress,
            toAddress: toAddress,
            verificationText: verificationText,
            verified: false
        )

        // TODO: We must somehow builtin some recovery mode. Because now each found transacation is handled only once. When storing fails then
        // it won't ever be handled and it is practically lost.
        try await storage.storeChat(newChat)
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

        // TODO: We must somehow builtin some recovery mode. Because now each found transacation is handled only once. When storing fails then
        // it won't ever be handled and it is practically lost.
        try await storage.storeMessage(newMessage)
    }
}

extension TransactionsProcessorImpl: TransactionsProcessor {
    func start() async {
        await cancel()
        sdkManager.transactionsStream
            .sink(
                receiveValue: { [weak self] transactions in
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
