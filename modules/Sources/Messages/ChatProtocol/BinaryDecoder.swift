//
//  BinaryDecoder.swift
//  
//
//  Created by Michal Fousek on 21.11.2023.
//

import Foundation

final class BinaryDecoder {
    enum Errors: Error {
        case bytesRangeOutOfBounds
        case cantDecodeString
    }

    let bytes: [UInt8]
    private var offset: Int
    init(bytes: [UInt8]) {
        self.bytes = bytes
        offset = 0
    }

    var unreadBytesCount: Int {
        return bytes.count - offset
    }

    private func get(bytesCount count: Int) throws -> ArraySlice<UInt8> {
        guard offset + count <= bytes.count else {
            throw Errors.bytesRangeOutOfBounds
        }

        defer { offset += count }
        return bytes[offset..<(offset + count)]
    }

    func decodeString(bytesCount: Int) throws -> String {
        let bytes = try get(bytesCount: bytesCount)
        guard let str = String(bytes: bytes, encoding: .utf8) else {
            throw Errors.cantDecodeString
        }
        return str
    }

    func decodeUInt8() throws -> UInt8 {
        // This index is super strange but get() returns ArraySlice and that preserves indexes of the original array.
        return try get(bytesCount: 1)[offset - 1]
    }

    func decodeInt(bytesCount: Int) throws -> Int {
        let bytes = try get(bytesCount: bytesCount)
        var value: Int = 0

        for byte in bytes.reversed() {
            value <<= 8
            value |= Int(byte)
        }

        return value
    }
}

