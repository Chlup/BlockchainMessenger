//
//  Chat.swift
//
//
//  Created by Michal Fousek on 24.11.2023.
//

import Foundation
import SQLite
import Dependencies

public struct Chat: Codable, Equatable, Identifiable {
    public var id: Int {
        chatID
    }
    
    // TODO: not sure if this must be optional, I will force users to put some alias otherwise new chat won't be created
    // but it might be required for some initial state in the DB?
    public let alias: String?
    public let chatID: Int
    public let timestamp: Int
    public let fromAddress: String
    public let toAddress: String
    public let verificationText: String
    public let verified: Bool

    enum Column {
        static let alias = Expression<String?>("alias")
        static let chatID = Expression<Int>("chatID")
        static let timestamp = Expression<Int>("timestamp")
        static let fromAddress = Expression<String>("fromAddress")
        static let toAddress = Expression<String>("toAddress")
        static let verificationText = Expression<String>("verificationText")
        static let verified = Expression<Bool>("verified")
    }

    public init(
        alias: String?,
        chatID: Int,
        timestamp: Int,
        fromAddress: String,
        toAddress: String,
        verificationText: String,
        verified: Bool
    ) {
        self.alias = alias
        self.chatID = chatID
        self.timestamp = timestamp
        self.fromAddress = fromAddress
        self.toAddress = toAddress
        self.verificationText = verificationText
        self.verified = verified
    }

    init(row: Row) throws {
        do {
            alias = try row.get(Column.alias)
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

    static func createNew(
        alias: String?,
        fromAddress: String,
        toAddress: String,
        verificationText: String
    ) -> Chat {
        @Dependency(\.chatProtocol) var chatProtocol
        
        let timestamp = Int(Date().timeIntervalSince1970)
        
        return Chat(
            alias: alias,
            chatID: chatProtocol.generateIDFor(timestamp),
            timestamp: timestamp,
            fromAddress: fromAddress,
            toAddress: toAddress,
            verificationText: verificationText,
            verified: false
        )
    }
}
