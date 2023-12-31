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

public enum MessagesEvent: Equatable {
    case didVerifyChat(Chat)
    case didUpdateChatAlias(Chat)
    case newChat(Chat)
    case newMessage(Message)
}

public protocol Messages {
    var eventsStream: AnyPublisher<MessagesEvent, Never> { get }

    func allChats() async throws -> [Chat]
    func allMessages(for chatID: Int) async throws -> [Message]
    func initialize(network: NetworkType) async throws
    func newChat(toAddress: String, verificationText: String, alias: String?) async throws
    func sendMessage(chatID: Int, text: String) async throws -> Message
    func start(with seedBytes: [UInt8], birthday: BlockHeight, walletMode: WalletInitMode) async throws
    func updateAlias(for chatID: Int, alias: String?) async throws
    func verifyChat(fromAddress: String, verificationText: String, alias: String?) async throws -> Chat
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
    @Dependency(\.clearedHeightStorage) var clearedHeightStorage
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
        await messagesSender.setNetwork(network)
        try await messagesStorage.initialize()
    }

    func newChat(toAddress: String, verificationText: String, alias: String?) async throws {
        try await messagesSender.newChat(toAddress: toAddress, verificationText: verificationText, alias: alias)
    }

    func sendMessage(chatID: Int, text: String) async throws -> Message {
        return try await messagesSender.sendMessage(chatID: chatID, text: text)
    }

    func start(with seedBytes: [UInt8], birthday: BlockHeight, walletMode: WalletInitMode) async throws {
        await messagesSender.setSeedBytes(seedBytes)
        await transactionsProcessor.start()
        try await sdkManager.start(with: seedBytes, birthday: birthday, walletMode: walletMode)
    }

    func updateAlias(for chatID: Int, alias: String?) async throws {
        try await messagesStorage.updateAlias(for: chatID, alias: alias)
    }

    func verifyChat(fromAddress: String, verificationText: String, alias: String?) async throws -> Chat {
        return try await messagesStorage.verifyChat(fromAddress: fromAddress, verificationText: verificationText, alias: alias)
    }

    func wipe() async throws {
        clearedHeightStorage.updateClearedHeight(0)
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
