//
//  MessagesStorage.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 19.11.2023.
//

import Foundation
import ZcashLightClientKit
import Dependencies
import SQLite
import SDKSynchronizer

protocol MessagesStorage: Actor {
    func initialize() async throws
    func doesChatExists(for chatID: Int) async throws -> Bool
    func storeChat(_ chat: Chat) async throws
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
