//
//  Message.swift
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
