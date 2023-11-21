//
//  Protocol.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 19.11.2023.
//

import Foundation
import Dependencies

/*
 prefix - "}b." - 3 bajty
 verze - 1 bajt
 chatID - 2 bajty
 typ zpravy 1 bajt
 text - zbytek

 */

struct ChatProtocol {
    enum Errors: Error {
        case notImplemented
        case textTooLong
        case chatIDTooHigh
        case cantEncodeMetadata
        case encodedMessageTooLong
        case encodedMessageTooShort
        case wrongPrefix
        case cantDecodeVersion
        case unknownVersion(Int)
        case cantDecodeChatID
        case cantDecodeMessageType
    }

    enum Constants {
        static let prefix = "}b}"
        static let versionLength = 1 //bytes
        static let maxLength = 512 //bytes
        static let chatIDLength = 3 //bytes
        //Max unsigned value stored in `Constants.maxChatIDLength` bytes
        static let maxChatIDValue = Int(truncating: NSDecimalNumber(decimal: pow(2, Constants.chatIDLength * 8) - 1))
        static let messageTypeLength = 1 //bytes
        //bytes, not characters
        static let maxTextLength =
            Constants.maxLength - Constants.prefix.utf8.count - Constants.versionLength - Constants.chatIDLength - Constants.messageTypeLength
    }

    enum Version: Int {
        case v1 = 1
    }

    fileprivate enum MessageType: Int {
        case text = 1
        case image = 2
        case video = 3
    }

    enum MessageToEncode {
        case text(String)
        // Future types
        case image(Data)
        case video(Data)

        fileprivate var messageType: MessageType {
            switch self {
            case .text: return .text
            case .image: return .image
            case .video: return .video
            }
        }
    }

    enum EncodedMessage {
        case text(String)
    }

    enum DecodedMessage {
        case text(_ chatID: Int, _ text: String)
    }

    private static func doAssertions() {
        assert(
            Constants.maxLength <= 512,
            "It looks like that ChatProtocol is incorrectly configured. Max length of the final message can't be higher than 512 bytes."
        )

        assert(
            Constants.prefix.utf8.count + Constants.messageTypeLength + Constants.chatIDLength + Constants.versionLength + Constants.maxTextLength ==
            Constants.maxLength,
            """
            It looks like that ChatProtocol is incorrectly configured. Constants.maxLength doesn't equal sum of other lengths.
            Sum is: \
            \(Constants.prefix.utf8.count + Constants.messageTypeLength + Constants.chatIDLength + Constants.versionLength + Constants.maxTextLength)
            Max length is: \(Constants.maxLength)
            """
        )
    }

    static func encodeMessage(version: Version = .v1, chatID: Int, message: MessageToEncode) throws -> EncodedMessage {
        doAssertions()

        let text: String
        switch message {
        case let .text(textToEncode):
            text = textToEncode

        case .video, .image:
            throw Errors.notImplemented
        }

        guard chatID <= Constants.maxChatIDValue else {
            throw Errors.chatIDTooHigh
        }

        guard text.utf8.count <= Constants.maxTextLength else {
            throw Errors.textTooLong
        }

        var bytes: [UInt8] = []

        encode(number: version.rawValue, length: Constants.versionLength, into: &bytes)
        encode(number: chatID, length: Constants.chatIDLength, into: &bytes)
        encode(number: message.messageType.rawValue, length: Constants.messageTypeLength, into: &bytes)

        guard let metadata = String(bytes: bytes, encoding: .utf8) else {
            throw Errors.cantEncodeMetadata
        }

        let output = Constants.prefix + metadata + text
        guard output.utf8.count <= Constants.maxLength else {
            throw Errors.encodedMessageTooLong
        }

        return .text(output)
    }

    static func decode(message: String) throws -> DecodedMessage {
        @Dependency(\.logger) var logger
        doAssertions()

        guard message.utf8.count > Constants.prefix.utf8.count + Constants.versionLength + Constants.chatIDLength + Constants.messageTypeLength else {
            throw Errors.encodedMessageTooShort
        }

        let prefix = message.prefix(Constants.prefix.count)
        guard prefix == Constants.prefix else {
            throw Errors.wrongPrefix
        }

        let rawVersion = try decodeNumber(
            from: message,
            startIndex: Constants.prefix.count,
            endIndex: Constants.prefix.count + Constants.versionLength,
            error: .cantDecodeVersion
        )

        guard let version = Version(rawValue: rawVersion) else {
            throw Errors.unknownVersion(rawVersion)
        }

        logger.debug("version: \(version)")

        switch version {
        case .v1:
            return try decodeV1(message: message)
        }
    }

    private static func decodeV1(message: String) throws -> DecodedMessage {
        @Dependency(\.logger) var logger

        let chatID = try decodeNumber(
            from: message,
            startIndex: Constants.prefix.utf8.count + Constants.versionLength,
            endIndex: Constants.prefix.utf8.count + Constants.versionLength + Constants.chatIDLength,
            error: .cantDecodeChatID
        )

        logger.debug("chatid \(chatID)")

        let rawMessageType = try decodeNumber(
            from: message,
            startIndex: Constants.prefix.utf8.count + Constants.versionLength + Constants.chatIDLength,
            endIndex: Constants.prefix.utf8.count + Constants.versionLength + Constants.chatIDLength + Constants.messageTypeLength,
            error: .cantDecodeMessageType
        )

        guard let messageType = MessageType(rawValue: rawMessageType) else {
            throw Errors.cantDecodeMessageType
        }

        switch messageType {
        case .text:
            return .text(chatID, decodeV1Text(from: message))

        case .video, .image:
            throw Errors.notImplemented
        }
    }

    private static func decodeV1Text(from message: String) -> String {
        @Dependency(\.logger) var logger

        let startIndex = message.index(
            message.startIndex,
            offsetBy: Constants.prefix.utf8.count + Constants.versionLength + Constants.chatIDLength + Constants.messageTypeLength
        )

        let text = String(message[startIndex..<message.endIndex])
        logger.debug("Text \(text)")
        return text
    }

    private static func encode(number: Int, length: Int, into output: inout [UInt8]) {
        for i in 0..<length {
            let bitShift = 8*i
            let byte = (number & (255 << bitShift)) >> bitShift
            output.append(UInt8(byte))
        }
    }

    private static func decodeNumber(from message: String, startIndex: Int, endIndex: Int, error: Errors) throws -> Int {
        let strStartIndex = message.index(message.startIndex, offsetBy: startIndex)
        let strEndIndex = message.index(message.startIndex, offsetBy: endIndex)
        let bytes = Array(message[strStartIndex..<strEndIndex].utf8)
        let length = endIndex - startIndex

        guard bytes.count == length else {
            throw error
        }

        var number: Int = 0
        for i in stride(from: length - 1, to: -1, by: -1) {
            number |= Int(bytes[i])
            if i > 0 {
                number <<= 8
            }
        }

        return number
    }
}
