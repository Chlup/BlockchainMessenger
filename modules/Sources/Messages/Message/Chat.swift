//
//  Chat.swift
//
//
//  Created by Michal Fousek on 24.11.2023.
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
        verificationText: String,
        verified: Bool
    ) -> Chat {
        @Dependency(\.chatProtocol) var chatProtocol
        
        let timestamp = chatProtocol.getTimestampForNow()
        
        return Chat(
            alias: alias,
            chatID: chatProtocol.generateIDFor(timestamp),
            timestamp: timestamp,
            fromAddress: fromAddress,
            toAddress: toAddress,
            verificationText: verificationText,
            verified: verified
        )
    }
}
