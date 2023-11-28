//
//  ChatProtocolV1.swift
//
//
//  Created by Michal Fousek on 21.11.2023.
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

/*
 chatID - 7 bytes (5 bytes timestamp + 3 bytes unique ID)
 timestamp - 5 bytes
 message ID - 3 bytes (final is timestamp + message ID)
 message type - 1 byte
 message content - max 490 bytes
 */

enum ChatProtocolV1 {
    static func encode(encoder: BinaryEncoder, message: ChatProtocol.ChatMessage) throws -> [UInt8] {
        encoder.encode(value: message.chatID, bytesCount: 8)
        encoder.encode(value: message.timestmap, bytesCount: 5)
        encoder.encode(value: message.messageID, bytesCount: 3)
        encoder.encode(byte: message.content.messageType.rawValue)

        switch message.content {
        case let .initialisation(fromAddress, toAddress, verificationText):
            let finalText = "\(fromAddress):\(toAddress):\(verificationText)"
            guard finalText.utf8.count + encoder.bytes.count <= ChatProtocol.Constants.maxEncodedMessageLength else {
                throw ChatProtocol.Errors.messageContentTooLong
            }
            encoder.encode(string: finalText)

        case let .text(text):
            guard text.utf8.count + encoder.bytes.count <= ChatProtocol.Constants.maxEncodedMessageLength else {
                throw ChatProtocol.Errors.messageContentTooLong
            }
            encoder.encode(string: text)
        }

        return encoder.bytes
    }

    static func decode(decoder: BinaryDecoder) throws -> ChatProtocol.ChatMessage {
        let chatID = try decoder.decodeInt(bytesCount: 8)
        let timestamp = try decoder.decodeInt(bytesCount: 5)

        let messageIDPart = try decoder.decodeInt(bytesCount: 3)
        let messageID = ChatProtocol.merge(timestamp: timestamp, andRestOfID: messageIDPart)

        let rawMessageType = try decoder.decodeUInt8()
        guard let messageType = ChatProtocol.MessageType(rawValue: rawMessageType) else {
            throw ChatProtocol.Errors.unknownMessageType(rawMessageType)
        }

        let content: ChatProtocol.ChatMessage.Content
        switch messageType {
        case .initialisation:
            let initText = try decoder.decodeString(bytesCount: decoder.unreadBytesCount)
            let parts = initText.split(separator: ":").map { String($0) }
            guard parts.count == 3 else {
                throw ChatProtocol.Errors.invalidInitMessageContent(initText)
            }
            content = .initialisation(parts[0], parts[1], parts[2])

        case .text:
            let text = try decoder.decodeString(bytesCount: decoder.unreadBytesCount)
            content = .text(text)
        }

        return ChatProtocol.ChatMessage(chatID: chatID, timestmap: timestamp, messageID: messageID, content: content)
    }
}
