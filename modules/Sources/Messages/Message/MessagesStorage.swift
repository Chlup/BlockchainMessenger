//
//  MessagesStorage.swift
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

import Foundation
import ZcashLightClientKit
import Dependencies
import SQLite
import SDKSynchronizer

protocol MessagesStorage: Actor {
    func initialize() async throws

    func allChats() async throws -> [Chat]
    func chat(for chatID: Int) async throws -> Chat
    func doesChatExists(for chatID: Int) async throws -> Bool
    func storeChat(_ chat: Chat) async throws

    func allMessages(for chatID: Int) async throws -> [Message]
    func doesMessageExists(for messageID: Message.ID) async throws -> Bool
    func storeMessage(_ message: Message) async throws
}

actor MessagesStorageImpl {
    @Dependency(\.sdkSynchronizer) var synchronizer
    @Dependency(\.logger) var logger
    @Dependency(\.messagesDBConnectionProvider) var dbConnection

    let chatsTable = Table("chats")
    let messagesTable = Table("messages")

    init() {
        Task {
            do {
                let logger = await logger
                let connection = await dbConnection
                let db = try connection.connection()
                db.trace { trace in
                    logger.debug("DB: \(trace)")
                }
            } catch {
                print("ERrroroooooo \(error)")
            }
        }
    }

    private func execute<Entity>(_ query: Table, createEntity: (Row) throws -> Entity) throws -> Entity {
        let entities: [Entity] = try execute(query, createEntity: createEntity)
        guard let entity = entities.first else { throw MessagesError.messagesStorageEntityNotFound }
        return entity
    }

    private func execute<Entity>(_ query: Table, createEntity: (Row) throws -> Entity) throws -> [Entity] {
        do {
            let db = try dbConnection.connection()
            let entities = try db
                .prepare(query)
                .map(createEntity)

            return entities
        } catch {
            if let error = error as? MessagesError {
                throw error
            } else {
                throw MessagesError.messagesStorageQueryExecute(error)
            }
        }
    }
}

extension MessagesStorageImpl: MessagesStorage {
    func initialize() async throws {
        let db = try dbConnection.connection()

        let createChatsTable = chatsTable.create(ifNotExists: true) { table in
            table.column(Chat.Column.chatID, primaryKey: true)
            table.column(Chat.Column.alias)
            table.column(Chat.Column.timestamp)
            table.column(Chat.Column.fromAddress)
            table.column(Chat.Column.toAddress)
            table.column(Chat.Column.verificationText)
            table.column(Chat.Column.verified)
        }
        let createChatsTimestampIndex = chatsTable.createIndex(Chat.Column.timestamp, ifNotExists: true)

        let createMessagesTable = messagesTable.create(ifNotExists: true) { table in
            table.column(Message.Column.id, primaryKey: true)
            table.column(Message.Column.chatID)
            table.column(Message.Column.timestamp)
            table.column(Message.Column.text)
            table.column(Message.Column.isSent)
        }
        let createMessagesChatIDIndex = messagesTable.createIndex(Message.Column.chatID, unique: true, ifNotExists: true)
        let createMessagesTimestampIndex = messagesTable.createIndex(Message.Column.timestamp, ifNotExists: true)

        try db.transaction {
            try db.run(createChatsTable)
            try db.run(createChatsTimestampIndex)
            try db.run(createMessagesTable)
            try db.run(createMessagesChatIDIndex)
            try db.run(createMessagesTimestampIndex)
        }
    }

    func allChats() async throws -> [Chat] {
        let query = chatsTable
            .order(Chat.Column.timestamp.desc)
        return try execute(query) { try Chat(row: $0) }
    }

    func chat(for chatID: Int) async throws -> Chat {
        let query = chatsTable
            .filter(Chat.Column.chatID == chatID)
        return try execute(query) { try Chat(row: $0) }
    }

    func doesChatExists(for chatID: Int) async throws -> Bool {
        let query = chatsTable
            .filter(Chat.Column.chatID == chatID)

        let chats: [Chat] = try execute(query) { try Chat(row: $0) }
        return !chats.isEmpty
    }

    func storeChat(_ chat: Chat) async throws {
        let db = try dbConnection.connection()
        try db.run(chatsTable.insert(chat))
    }

    func allMessages(for chatID: Int) async throws -> [Message] {
        let query = messagesTable
            .filter(Message.Column.chatID == chatID)
            .order(Message.Column.timestamp.desc)
        return try execute(query) { try Message(row: $0) }
    }

    func doesMessageExists(for messageID: Message.ID) async throws -> Bool {
        let query = messagesTable
            .filter(Message.Column.id == messageID)

        let messages: [Message] = try execute(query) { try Message(row: $0) }
        return !messages.isEmpty
    }

    func storeMessage(_ message: Message) async throws {
        let db = try dbConnection.connection()
        try db.run(messagesTable.insert(message))
    }
}

private enum MessagesStorageClientKey: DependencyKey {
    static let liveValue: MessagesStorage = MessagesStorageImpl()
}

extension DependencyValues {
    var messagesStorage: MessagesStorage {
        get { self[MessagesStorageClientKey.self] }
        set { self[MessagesStorageClientKey.self] = newValue }
    }
}
