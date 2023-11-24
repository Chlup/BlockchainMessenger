//
//  Chat.swift
//
//
//  Created by Michal Fousek on 24.11.2023.
//

import Foundation
import SQLite

public struct Chat {
    public typealias ID = String

    public let id: ID
    public let chatID: Int
    public let timestamp: Int
    public let fromAddress: String
    public let toAddress: String
    public let verificationText: String
    public let verified: Bool

    enum Column {
        static let id = Expression<ID>("id")
        static let chatID = Expression<Int>("chat_id")
        static let timestamp = Expression<Int>("timestamp")
        static let fromAddress = Expression<String>("from_address")
        static let toAddress = Expression<String>("to_address")
        static let verificationText = Expression<String>("verification_text")
        static let verified = Expression<Bool>("verified")
    }

    init(row: Row) throws {
        do {
            id = try row.get(Column.id)
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
}
