//
//  ChatProtocolV1.swift
//
//
//  Created by Michal Fousek on 21.11.2023.
//

import Foundation

/*
 chatID - 7 bytes (5 bytes timestamp + 2 bytes unique ID)
 timestamp - 5 bytes
 message type - 1 byte
 message content - max 494 bytes
 */

enum ChatProtocolV1 {
    static func encode(encoder: BinaryEncoder, message: ChatProtocol.ChatMessage) throws -> Data {
        encoder.encode(value: message.chatID, bytesCount: 7)
        encoder.encode(value: message.timestmap, bytesCount: 5)
        encoder.encode(byte: message.content.messageType.rawValue)

        switch message.content {
        case let .initialisation(fromAddress):
            guard fromAddress.utf8.count + encoder.data.count <= ChatProtocol.Constants.maxEncodedMessageLength else {
                throw ChatProtocol.Errors.messageContentTooLong
            }
            encoder.encode(string: fromAddress)

        case let .text(text):
            guard text.utf8.count + encoder.data.count <= ChatProtocol.Constants.maxEncodedMessageLength else {
                throw ChatProtocol.Errors.messageContentTooLong
            }
            encoder.encode(string: text)
        }

        return encoder.data
    }

    static func decode(decoder: BinaryDecoder) throws -> ChatProtocol.ChatMessage {
        let chatID = try decoder.decodeInt(bytesCount: 7)
        let timestamp = try decoder.decodeInt(bytesCount: 5)
        let rawMessageType = try decoder.decodeUInt8()
        guard let messageType = ChatProtocol.MessageType(rawValue: rawMessageType) else {
            throw ChatProtocol.Errors.unknownMessageType(rawMessageType)
        }

        let content: ChatProtocol.ChatMessage.Content
        switch messageType {
        case .initialisation:
            let fromAddress = try decoder.decodeString(bytesCount: decoder.unreadBytesCount)
            content = .initialisation(fromAddress)

        case .text:
            let text = try decoder.decodeString(bytesCount: decoder.unreadBytesCount)
            content = .text(text)
        }

        return ChatProtocol.ChatMessage(chatID: chatID, timestmap: timestamp, content: content)
    }
}
