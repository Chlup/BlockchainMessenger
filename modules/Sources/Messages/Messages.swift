//
//  Messages.swift
//
//
//  Created by Michal Fousek on 20.11.2023.
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
import ZcashLightClientKit

public enum MessagesError: Error {
    case chatEntityInit(Error)
    case messageEntityInit(Error)
    case simpleConnectionProvider(Error)
    case synchronizerInitFailed(Error)
    case messagesStorageQueryExecute(Error)
    case messagesStorageEntityNotFound
    case invalidFromAddressWhenCreatingChat
    case invalidToAddressWhenCreatingChat
    case createMemoFromMessageWhenCreatingChat(Error)
    case createRecipientWhenCreatingChat(Error)
    case storeNewChat(Error)
    case chatDoesntExistWhenSendingMessage(Error)
    case getUnifiedAddressWhenSendingMessage
}

public enum MessagesEvent: Equatable {
    case newChat(Chat)
    case newMessage(Message)
}

public protocol Messages {
    var eventsStream: AnyPublisher<MessagesEvent, Never> { get }

    func allChats() async throws -> [Chat]
    func allMessages(for chatID: Int) async throws -> [Message]
    func initialize(network: NetworkType) async throws
    func newChat(fromAddress: String, toAddress: String, verificationText: String) async throws
    func sendMessage(chatID: Int, text: String) async throws -> Message
    func start(with seedBytes: [UInt8], birthday: BlockHeight, walletMode: WalletInitMode) async throws
    func wipe() async throws
}

struct MessagesImpl {
    @Dependency(\.transactionsProcessor) var transactionsProcessor
    @Dependency(\.sdkManager) var sdkManager
    @Dependency(\.logger) var logger
    @Dependency(\.chatProtocol) var chatProtocol
    @Dependency(\.messagesStorage) var messagesStorage
    @Dependency(\.messagesSender) var messagesSender
    @Dependency(\.eventsSender) var eventsSender
}

extension MessagesImpl: Messages {
    var eventsStream: AnyPublisher<MessagesEvent, Never> { eventsSender.eventsStream }

    func allChats() async throws -> [Chat] {
        return try await messagesStorage.allChats()
    }

    func allMessages(for chatID: Int) async throws -> [Message] {
        return try await messagesStorage.allMessages(for: chatID)
    }

    func initialize(network: NetworkType) async throws {
        //        do {
        //            let message = Message.createSent(chatID: 123, text: "Hello 🐞world")
        //            logger.debug("Input message \(message)")
        //            logger.debug(message.id.binaryDescription)
        //            logger.debug(message.timestamp.binaryDescription)
        //            let protocolMessage = ChatProtocol.ChatMessage(chatID: message.chatID, timestmap: message.timestamp, messageID: message.id, content: .text(message.text))
        //
        //            let encoded = try chatProtocol.encode(protocolMessage)
        //
        //            let decoded = try chatProtocol.decode(Array(encoded))
        //            logger.debug("Decoded message \(decoded)")
        //
        //        } catch {
        //            logger.debug("Error while encoding/decoding message: \(error)")
        //        }

        await messagesSender.setNetwork(network)
        try await messagesStorage.initialize()
    }

    func newChat(fromAddress: String, toAddress: String, verificationText: String) async throws {
        try await messagesSender.newChat(fromAddress: fromAddress, toAddress: toAddress, verificationText: verificationText)
    }

    func sendMessage(chatID: Int, text: String) async throws -> Message {
        return try await messagesSender.sendMessage(chatID: chatID, text: text)
    }

    func start(with seedBytes: [UInt8], birthday: BlockHeight, walletMode: WalletInitMode) async throws {
        await messagesSender.setSeedBytes(seedBytes)
        await transactionsProcessor.start()
        try await sdkManager.start(with: seedBytes, birthday: birthday, walletMode: walletMode)
    }

    func wipe() async throws {
        try await messagesStorage.wipe()
    }
}

private enum MessagesClientKey: DependencyKey {
    static let liveValue: Messages = MessagesImpl()
}

extension DependencyValues {
    public var messages: Messages {
        get { self[MessagesClientKey.self] }
        set { self[MessagesClientKey.self] = newValue }
    }
}
