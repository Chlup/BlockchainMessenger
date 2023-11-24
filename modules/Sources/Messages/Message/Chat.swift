//
//  Chat.swift
//
//
//  Created by Michal Fousek on 24.11.2023.
//

import Foundation
import SQLite
import Dependencies

public struct Chat: Codable, Equatable {
    public let chatID: Int
    public let timestamp: Int
    public let fromAddress: String
    public let toAddress: String
    public let verificationText: String
    public let verified: Bool

    enum Column {
        static let chatID = Expression<Int>("chat_id")
        static let timestamp = Expression<Int>("timestamp")
        static let fromAddress = Expression<String>("from_address")
        static let toAddress = Expression<String>("to_address")
        static let verificationText = Expression<String>("verification_text")
        static let verified = Expression<Bool>("verified")
    }

    init(chatID: Int, timestamp: Int, fromAddress: String, toAddress: String, verificationText: String, verified: Bool) {
        self.chatID = chatID
        self.timestamp = timestamp
        self.fromAddress = fromAddress
        self.toAddress = toAddress
        self.verificationText = verificationText
        self.verified = verified
    }

    init(row: Row) throws {
        do {
            chatID = try row.get(Column.chatID)
            timestamp = try row.get(Column.timestamp)
            fromAddress = try row.get(Column.fromAddress)
            toAddress = try row.get(Column.toAddress)
            verificationText = try row.get(Column.verificationText)
            verified = try row.get(Column.verified)
        } catch {
            throw MessagesError.chatEntityInit(error)
        }
    }

    static func createNew(fromAddress: String, toAddress: String, verificationText: String) -> Chat {
        @Dependency(\.chatProtocol) var chatProtocol
        let timestamp = Int(Date().timeIntervalSince1970)
        return Chat(
            chatID: chatProtocol.generateIDFor(timestamp),
            timestamp: timestamp,
            fromAddress: fromAddress,
            toAddress: toAddress,
            verificationText: verificationText,
            verified: false
        )
    }
}
