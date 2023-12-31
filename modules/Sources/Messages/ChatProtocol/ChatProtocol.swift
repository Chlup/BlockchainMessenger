//
//  Protocol.swift
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
import Dependencies

/*
 zcash arbitrary memo byte - 0xff - 1 byte
 prefix - "}b." - 3 bytes
 version - 1 byte
 chatID - 8 bytes (5 bytes timestamp + 3 bytes unique ID)
 timestamp - 5 bytes
 message ID - 3 bytes (final is timestamp + message ID)
 message type - 1 byte
 message content - max 490 bytes
 */

public struct ChatProtocol {
    enum Version: UInt8 {
        case v1 = 1
    }

    public struct ChatMessage: Equatable, Identifiable {
        public var id: Int { messageID }

        public enum Content: Equatable {
            case initialisation(_ fromAddress: String, _ toAddress: String, _ verificationText: String)
            case text(String)

            public var messageType: ChatProtocol.MessageType {
                switch self {
                case .initialisation: return .initialisation
                case .text: return .text
                }
            }
        }

        public let chatID: Int
        public let timestmap: Int
        public let messageID: Int
        public let content: Content
    }

    public enum MessageType: UInt8 {
        case initialisation = 1
        case text = 2
    }

    enum Errors: Error {
        // Encoding. Can't encode message because content is too long.
        case messageContentTooLong
        // Decoding. First byte in memo should be 0xFF. But different value is found.
        case invalidFirstMemoByte(UInt8)
        // Decoding. Wrong value found for prefix.
        case invalidPrefix(String)
        // Decoding. Unknown protocol version found.
        case unknownVersion(UInt8)
        // Decodeing. Unknown message type found.
        case unknownMessageType(UInt8)
        // Decoding. Can't decode message because it doesn't contain all the expected data.
        // Provided Data probably don't contain correctly encoded message.
        case invalidMessage(Error)
        // Decoding. Decoded content of init message and it doesn't contain expected parts.
        case invalidInitMessageContent(String)
    }

    // Encode message with latest version.
    public var encode: (_ message: ChatMessage) throws -> [UInt8]
    // Decode message
    public var decode: (_ message: [UInt8]) throws -> ChatMessage
    public var getTimestampForNow: () -> Int
    // Generate new message ID or chat ID for some timestamp.
    public var generateIDFor: (_ timestamp: Int) -> Int

    enum Constants {
        static let maxEncodedMessageLength = 512
        static let zcashMemoByte: UInt8 = 0xFF
        static let prefix = "}b}"
    }

    private static func encode(_ message: ChatMessage) throws -> [UInt8] {
        let encoder = BinaryEncoder()
        encoder.encode(byte: Constants.zcashMemoByte)
        encoder.encode(string: Constants.prefix)
        encoder.encode(byte: Version.v1.rawValue)

        return try ChatProtocolV1.encode(encoder: encoder, message: message)
    }

    private static func decode(_ bytes: [UInt8]) throws -> ChatMessage {
        @Dependency(\.logger) var logger

        logger.debug("Decoding: \(bytes)")
        let decoder = BinaryDecoder(bytes: bytes)

        do {
            let firstByte = try decoder.decodeUInt8()
            guard firstByte == Constants.zcashMemoByte else {
                throw Errors.invalidFirstMemoByte(firstByte)
            }

            let prefix = try decoder.decodeString(bytesCount: 3)
            guard prefix == Constants.prefix else {
                throw Errors.invalidPrefix(prefix)
            }

            let rawVersion = try decoder.decodeUInt8()
            guard let version = Version(rawValue: rawVersion) else {
                throw Errors.unknownVersion(rawVersion)
            }

            switch version {
            case .v1:
                return try ChatProtocolV1.decode(decoder: decoder)
            }
        } catch BinaryDecoder.Errors.bytesRangeOutOfBounds {
            throw Errors.invalidMessage(BinaryDecoder.Errors.bytesRangeOutOfBounds)
        } catch BinaryDecoder.Errors.cantDecodeString {
            throw Errors.invalidMessage(BinaryDecoder.Errors.cantDecodeString)
        } catch {
            throw error
        }
    }

    private static func random3BytesNumber() -> Int {
        let maxValue = Int(truncating: NSDecimalNumber(decimal: pow(2, 24) - 1))
        return Int.random(in: 0...maxValue)
    }

    static func merge(timestamp: Int, andRestOfID rest: Int) -> Int {
        var id = timestamp
        id <<= 24
        id |= rest
        return id
    }

    static var live: ChatProtocol {
        return Self(
            encode: { message in
                return try Self.encode(message)
            },
            decode: { data in
                return try Self.decode(data)
            },
            getTimestampForNow: { Int(Date().timeIntervalSince1970) },
            generateIDFor: { timestamp in
                Self.merge(timestamp: timestamp, andRestOfID: Self.random3BytesNumber())
            }
        )
    }
}

private enum ChatProtocolClientKey: DependencyKey {
    static let liveValue = ChatProtocol.live
}

extension DependencyValues {
    public var chatProtocol: ChatProtocol {
        get { self[ChatProtocolClientKey.self] }
        set { self[ChatProtocolClientKey.self] = newValue }
    }
}
