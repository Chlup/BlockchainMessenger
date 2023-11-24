//
//  Message.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 19.11.2023.
//

import Foundation
import ZcashLightClientKit
import SQLite

public struct Message {
    public typealias ID = String

    public let id: ID
    public let chatID: Int
    public let timestamp: Int
    public let text: String
    public let isSent: Bool
    let transactionID: Transaction.ID

    enum Column {
        static let id = Expression<ID>("id")
        static let chatID = Expression<Int>("chat_id")
        static let timestamp = Expression<Int>("timestamp")
        static let text = Expression<String>("text")
        static let isSent = Expression<Bool>("is_sent")
        static let transactionID = Expression<String>("transaction_id")
    }

    init(row: Row) throws {
        do {
            id = try row.get(Column.id)
            chatID = try row.get(Column.chatID)
            timestamp = try row.get(Column.timestamp)
            text = try row.get(Column.text)
            isSent = try row.get(Column.isSent)
            transactionID = try row.get(Column.transactionID)
        } catch {
            throw MessagesError.messageEntityInit(error)
        }
    }
}

extension Message: Equatable {
    static public func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}
