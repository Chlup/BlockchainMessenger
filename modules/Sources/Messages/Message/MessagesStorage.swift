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
    func doesMessageExists(for transactionID: Transaction.ID) async throws -> Bool
    func storeMessage(_ message: Message) async throws
}

actor MessagesStorageImpl {
    @Dependency(\.sdkSynchronizer) var synchronizer
    @Dependency(\.logger) var logger
    @Dependency(\.messagesDBConnectionProvider) var dbConnection

    let chatsTable = Table("chats")
    let messagesTable = Table("messages")

    private func execute<Entity>(_ query: Table, createEntity: (Row) throws -> Entity) throws -> Entity {
        let entities: [Entity] = try execute(query, createEntity: createEntity)
        guard let entity = entities.first else { throw MessagesError.messagesStorageEntityNotFound }
        return entity
    }

    private func execute<Entity>(_ query: Table, createEntity: (Row) throws -> Entity) throws -> [Entity] {
        do {
            let entities = try dbConnection.connection()
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

//    private func processTransactionForExistingMessage(transaction: Transaction, existingMessage: Message) {
//        // Previously we stored message from transaction which wasn't mined. Now we have the same transaction but is mined. We should update
//        // height of message.
////        if  let minedHeight = transaction.minedHeight,
////            existingMessage.transactionHeight == nil,
////            let messageIndex = messagesList.firstIndex(of: existingMessage) {
//
////            let newMessage = Message(
////                id: existingMessage.id,
////                state: existingMessage.state,
////                text: existingMessage.text,
////                transactionID: existingMessage.transactionID,
////                transactionHeight: minedHeight
////            )
////
////            messages[existingMessage.transactionID] = newMessage
////            messagesList[messageIndex] = newMessage
////        }
//    }
//
//    private func processNewTransaction(_ transaction: Transaction) async throws {
//        logger.debug("Storing new transaction")
//        // Transaction must have memo
//        guard transaction.memoCount > 0 else {
//            logger.debug("Transaction doesn't have memos count")
//            return
//        }
//        let memos = try await synchronizer.getMemos(transaction.rawID)
//        // Memo must be text and text of memo must be recognized as chat message.
//        guard let memo = memos.first else {
//            logger.debug("Transaction doesn't have memos")
//            return
//        }
//
//        guard let text = memo.toString() else {
//            logger.debug("Memo for transaction can't be converted to text.")
//            return
//        }
//
//        guard doesMemoContainChatMessage(text: text) else { return }
//
//        logger.debug("Storing!!!!")
//
////        let message = Message(
////            id: UUID().uuidString,
////            state: transaction.isSentTransaction ? .sent : .received,
////            text: text,
////            transactionID: transaction.rawID.sha256,
////            transactionHeight: transaction.minedHeight
////        )
////
////        messages[message.transactionID] = message
////        messagesList.append(message)
//    }
//
//    private func doesMemoContainChatMessage(text: String) -> Bool {
//        // Here we must do some test for memo text to recognize chat messages. We need to distinguish between chat messages and regular financial
//        // transactions with memos.
//        return true
//    }
}

extension MessagesStorageImpl: MessagesStorage {
    func initialize() async throws {
        let db = try dbConnection.connection()

        let createChatsTable = chatsTable.create(ifNotExists: true) { table in
            table.column(Chat.Column.chatID, primaryKey: true)
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
            table.column(Message.Column.transactionID)
        }
        let createMessagesChatIDIndex = messagesTable.createIndex(Message.Column.chatID, unique: true, ifNotExists: true)
        let createMessagesTimestampIndex = messagesTable.createIndex(Message.Column.timestamp, ifNotExists: true)
        let createMessagesTransactionIDIndex = messagesTable.createIndex(Message.Column.transactionID, unique: true, ifNotExists: true)

        try db.transaction {
            try db.run(createChatsTable)
            try db.run(createChatsTimestampIndex)
            try db.run(createMessagesTable)
            try db.run(createMessagesChatIDIndex)
            try db.run(createMessagesTimestampIndex)
            try db.run(createMessagesTransactionIDIndex)
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

    func doesMessageExists(for transactionID: Transaction.ID) async throws -> Bool {
        let query = messagesTable
            .filter(Message.Column.transactionID == transactionID)

        let messages: [Message] = try execute(query) { try Message(row: $0) }
        return !messages.isEmpty
    }

    func storeMessage(_ message: Message) async throws {
        let db = try dbConnection.connection()
        try db.run(messagesTable.insert(message))
    }

    func process(foundTransaction transaction: Transaction) async throws {
        logger.debug("Processing found transaction in storage")
//        
//        
//
//
//
//        let transactionID = transaction.rawID.sha256
//        if let existingMessage = messages[transactionID] {
//            processTransactionForExistingMessage(transaction: transaction, existingMessage: existingMessage)
//        } else {
//            try await processNewTransaction(transaction)
//        }
//
//        logger.debug("Messages list: \(messagesList.count)")
//        if messagesList.count > 0 {
//            for message in messagesList {
//                var output = message.state == .sent ? "S: " : "R: "
//                output += message.text
//                logger.debug(output)
//            }
//            
//            logger.debug("Raw messages:")
//            messagesList.forEach { self.logger.debug("\($0)") }
//        }
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
