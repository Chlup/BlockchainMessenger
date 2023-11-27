//
//  Message.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 19.11.2023.
//

import Foundation
import ZcashLightClientKit
import SQLite
import Dependencies

public struct Message: Codable, Equatable, Identifiable {
    public typealias ID = Int

    public let id: ID
    public let chatID: Int
    public let timestamp: Int
    public let text: String
    public let isSent: Bool

    enum Column {
        static let id = Expression<ID>("id")
        static let chatID = Expression<Int>("chatID")
        static let timestamp = Expression<Int>("timestamp")
        static let text = Expression<String>("text")
        static let isSent = Expression<Bool>("isSent")
    }

    public init(
        id: ID,
        chatID: Int,
        timestamp: Int,
        text: String,
        isSent: Bool
    ) {
        self.id = id
        self.chatID = chatID
        self.timestamp = timestamp
        self.text = text
        self.isSent = isSent
    }

    init(row: Row) throws {
        do {
            id = try row.get(Column.id)
            chatID = try row.get(Column.chatID)
            timestamp = try row.get(Column.timestamp)
            text = try row.get(Column.text)
            isSent = try row.get(Column.isSent)
        } catch {
            throw MessagesError.messageEntityInit(error)
        }
    }

    static func createSent(chatID: Int, text: String) -> Message {
        @Dependency(\.chatProtocol) var chatProtocol
        let timestamp = chatProtocol.getTimestampForNow()
        return Message(id: chatProtocol.generateIDFor(timestamp), chatID: chatID, timestamp: timestamp, text: text, isSent: true)
    }
}
