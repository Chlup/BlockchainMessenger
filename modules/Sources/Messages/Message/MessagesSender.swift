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
    func newChat(fromAddress: String, toAddress: String, verificationText: String) async throws
    func sendMessage(chatID: Int, text: String) async throws
}

actor MessagesSenderImpl {
    @Dependency(\.sdkSynchronizer) var synchronizer
    @Dependency(\.messagesStorage) var storage
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.chatProtocol) var chatProtocol
    @Dependency(\.logger) var logger

    var network: NetworkType = .testnet
    var seedBytes: [UInt8] = []

    private func send(message: ChatProtocol.ChatMessage, toAddress: String) async throws {
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

        try await synchronizer.sendTransaction(spendingKey, Constants.messagePrice, recipient, memo)
    }
}

extension MessagesSenderImpl: MessagesSender {
    private enum Constants {
        static let messagePrice = Zatoshi(1)
    }

    func setSeedBytes(_ seedBytes: [UInt8]) async {
        self.seedBytes = seedBytes
    }

    func setNetwork(_ network: NetworkType) async {
        self.network = network
    }

    func newChat(fromAddress: String, toAddress: String, verificationText: String) async throws {
        let newChat = Chat.createNew(alias: nil, fromAddress: fromAddress, toAddress: toAddress, verificationText: verificationText)
        let protocolMessage = ChatProtocol.ChatMessage(
            chatID: newChat.chatID,
            timestmap: newChat.timestamp,
            messageID: newChat.chatID,
            content: .initialisation(fromAddress, toAddress, verificationText)
        )

        guard derivationTool.isUnifiedAddress(fromAddress, network) else {
            throw MessagesError.invalidFromAddressWhenCreatingChat
        }

        try await send(message: protocolMessage, toAddress: toAddress)

        try await storage.storeChat(newChat)
    }
    
    func sendMessage(chatID: Int, text: String) async throws {
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
            messageID: chatProtocol.generateIDFor(newMessage.timestamp),
            content: .text(text)
        )

        try await send(message: protocolMessage, toAddress: chat.toAddress)
        try await storage.storeMessage(newMessage)
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
