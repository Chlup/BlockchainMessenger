//
//  BinaryDecoder.swift
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

