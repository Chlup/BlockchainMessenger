//
//  Protocol.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 19.11.2023.
//

import Foundation
import Dependencies

/*
 zcash arbitrary memo byte - 0xff - 1 byte
 prefix - "}b." - 3 bytes
 version - 1 byte
 chatID - 7 bytes (5 bytes timestamp + 2 bytes unique ID)
 timestamp - 5 bytes
 message type - 1 byte
 message content - max 494 bytes
 */

struct ChatProtocol {
    enum Version: UInt8 {
        case v1 = 1
    }

    struct ChatMessage {
        enum Content {
            case initialisation(_ fromAddress: String)
            case text(String)

            var messageType: ChatProtocol.MessageType {
                switch self {
                case .initialisation: return .initialisation
                case .text: return .text
                }
            }
        }

        let chatID: Int
        let timestmap: Int
        let content: Content
    }

    enum MessageType: UInt8 {
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
    }

    // Encode message with latest version.
    var encode: (_ message: ChatMessage) throws -> Data
    // Decode message
    var decode: (_ message: Data) throws -> ChatMessage

    enum Constants {
        static let maxEncodedMessageLength = 512
        static let zcashMemoByte: UInt8 = 0xFF
        static let prefix = "}b}"
    }

    private static func encode(_ message: ChatMessage) throws -> Data {
        let encoder = BinaryEncoder()
        encoder.encode(byte: Constants.zcashMemoByte)
        encoder.encode(string: Constants.prefix)
        encoder.encode(byte: Version.v1.rawValue)

        return try ChatProtocolV1.encode(encoder: encoder, message: message)
    }

    private static func decode(_ data: Data) throws -> ChatMessage {
        let decoder = BinaryDecoder(data: data)

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

    static var live: ChatProtocol {
        return Self(
            encode: { message in
                return try Self.encode(message)
            },
            decode: { data in
                return try Self.decode(data)
            }
        )
    }
}

private enum ChatProtocolClientKey: DependencyKey {
    static let liveValue: ChatProtocol = ChatProtocol.live
}

extension DependencyValues {
    var chatProtocol: ChatProtocol {
        get { self[ChatProtocolClientKey.self] }
        set { self[ChatProtocolClientKey.self] = newValue }
    }
}

