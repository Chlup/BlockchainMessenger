//
//  ChatProtocolV1.swift
//
//
//  Created by Michal Fousek on 21.11.2023.
//

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
