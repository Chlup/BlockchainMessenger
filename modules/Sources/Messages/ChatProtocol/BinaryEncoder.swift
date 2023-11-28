//
//  BinaryEncoder.swift
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

final class BinaryEncoder {
    private(set) var bytes: [UInt8] = []

    func encode(byte: UInt8) {
        bytes.append(byte)
    }

    func encode(byte: Int8) {
        bytes.append(UInt8(bitPattern: byte))
    }

    func encode(string: String) {
        bytes.append(contentsOf: Array(string.utf8))
    }

    func encode(value: Int, bytesCount: Int) {
        for i in 0..<bytesCount {
            let mask = Int(255 << (i * 8))
            let byte = UInt8((value & mask) >> (i * 8))
            bytes.append(byte)
        }
    }
}
