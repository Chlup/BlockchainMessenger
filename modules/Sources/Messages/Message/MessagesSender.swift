//
//  MessagesSender.swift
//
//
//  Created by Michal Fousek on 24.11.2023.
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

import Foundation
import Dependencies
import SDKSynchronizer
import DerivationTool
import ZcashLightClientKit

protocol MessagesSender: Actor {
    func setNetwork(_ network: NetworkType) async
    func setSeedBytes(_ seedBytes: [UInt8]) async
    func newChat(fromAddress: String, toAddress: String, verificationText: String, alias: String?) async throws
    func sendMessage(chatID: Int, text: String) async throws -> Message
}

actor MessagesSenderImpl {
    @Dependency(\.sdkSynchronizer) var synchronizer
    @Dependency(\.messagesStorage) var storage
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.chatProtocol) var chatProtocol
    @Dependency(\.logger) var logger
    @Dependency(\.transactionsProcessor) var transactionsProcessor

    private enum Constants {
        static let messagePrice = Zatoshi(0)
    }

    var network: NetworkType = .testnet
    var seedBytes: [UInt8] = []

    private func send(message: ChatProtocol.ChatMessage, toAddress: String) async throws -> Data {
        let encodedMessage = try chatProtocol.encode(message)
        logger.debug("Encoded: \(encodedMessage)")

        guard derivationTool.isUnifiedAddress(toAddress, network) else {
            throw MessagesError.invalidToAddressWhenCreatingChat
        }

        let spendingKey = try derivationTool.deriveSpendingKey(seedBytes, 0, network)
        let memo: Memo
        do {
            memo = try Memo(bytes: encodedMessage)
        } catch {
            throw MessagesError.createMemoFromMessageWhenCreatingChat(error)
        }

        let recipient: Recipient
        do {
            recipient = try Recipient(toAddress, network: network)
        } catch {
            throw MessagesError.createRecipientWhenCreatingChat(error)
        }

        return try await synchronizer.sendTransaction(spendingKey, Constants.messagePrice, recipient, memo)
    }
}

extension MessagesSenderImpl: MessagesSender {
    func setSeedBytes(_ seedBytes: [UInt8]) async {
        self.seedBytes = seedBytes
    }

    func setNetwork(_ network: NetworkType) async {
        self.network = network
    }

    func newChat(fromAddress: String, toAddress: String, verificationText: String, alias: String?) async throws {
        let myUnifiedAddress: String
        do {
            guard let possibleUnifiedAddress = try await synchronizer.getUnifiedAddress(account: 0) else {
                throw MessagesError.getUnifiedAddressWhenCreatingChat
            }
            myUnifiedAddress = possibleUnifiedAddress.stringEncoded
        } catch {
            throw MessagesError.getUnifiedAddressWhenCreatingChat
        }

        let amICreatorOfChat = myUnifiedAddress == fromAddress

        let newChat = Chat.createNew(
            alias: alias,
            fromAddress: fromAddress,
            toAddress: toAddress,
            verificationText: verificationText,
            // When current seed is creator of chat then chat is verified on it's side because there is nothing to verify. The other side must
            // recieve `verificationText` through different channel and verify this chat.
            verified: amICreatorOfChat
        )

        let protocolMessage = ChatProtocol.ChatMessage(
            chatID: newChat.chatID,
            timestmap: newChat.timestamp,
            messageID: newChat.chatID,
            content: .initialisation(fromAddress, toAddress, verificationText)
        )

        guard derivationTool.isUnifiedAddress(fromAddress, network) else {
            throw MessagesError.invalidFromAddressWhenCreatingChat
        }

        let transactionRawID = try await send(message: protocolMessage, toAddress: toAddress)
        do {
            try await storage.storeChat(newChat)
        } catch {
            await transactionsProcessor.failureHappened()
            throw MessagesError.storeNewChat(error)
        }
    }
    
    func sendMessage(chatID: Int, text: String) async throws -> Message {
        let chat: Chat
        do {
            chat = try await storage.chat(for: chatID)
        } catch {
            throw MessagesError.chatDoesntExistWhenSendingMessage(error)
        }

        let newMessage = Message.createSent(chatID: chatID, text: text)
        let protocolMessage = ChatProtocol.ChatMessage(
            chatID: newMessage.chatID,
            timestmap: newMessage.timestamp,
            messageID: newMessage.id,
            content: .text(text)
        )

        let unifiedAddress: UnifiedAddress
        do {
            guard let possibleUnifiedAddress = try await synchronizer.getUnifiedAddress(account: 0) else {
                throw MessagesError.getUnifiedAddressWhenSendingMessage
            }
            unifiedAddress = possibleUnifiedAddress
        } catch {
            throw MessagesError.getUnifiedAddressWhenSendingMessage
        }

        // There are two sides chatting. When side A creates chat it sends init message with `fromAddress` and `toAddress`. Side A's address is
        // `fromAddress`. And B's side address is `toAddress`. So when side B is sending message it must choose `chat.fromAddress` as to adress to
        // send message to side A and not to itself.
        let toAddress: String
        if unifiedAddress.stringEncoded == chat.toAddress {
            toAddress = chat.fromAddress
        } else {
            toAddress = chat.toAddress
        }

        _ = try await send(message: protocolMessage, toAddress: toAddress)
        do {
            try await storage.storeMessage(newMessage)
        } catch {
            await transactionsProcessor.failureHappened()
        }

        return newMessage
    }
}

private enum MessagesSenderClientKey: DependencyKey {
    static let liveValue: MessagesSender = MessagesSenderImpl()
}

extension DependencyValues {
    var messagesSender: MessagesSender {
        get { self[MessagesSenderClientKey.self] }
        set { self[MessagesSenderClientKey.self] = newValue }
    }
}
