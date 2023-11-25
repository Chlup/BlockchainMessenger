//
//  BinaryEncoder.swift
//  
//
//  Created by Michal Fousek on 21.11.2023.
//

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
            let mask = Int(255 << (i*8))
            let byte = UInt8((value & mask) >> (i*8))
            bytes.append(byte)
        }
    }
}

