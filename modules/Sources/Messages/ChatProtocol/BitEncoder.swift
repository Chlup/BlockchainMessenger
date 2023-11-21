//
//  BitEncoder.swift
//  
//
//  Created by Michal Fousek on 21.11.2023.
//

import Foundation

final class BitEncoder {
    private(set) var data: Data
    init() {
        data = Data()
    }

    func encode(byte: UInt8) {
        data.append(byte)
    }

    func encode(byte: Int8) {
        data.append(UInt8(bitPattern: byte))
    }

    func encode(string: String) {
        data.append(contentsOf: Array(string.utf8))
    }

    func encode(value: Int, bytesCount: Int) {
        var bytesToEncode: [UInt8] = []
        for i in 0..<bytesCount {
            let mask = Int(255 << (i*8))
            let byte = UInt8((value & mask) >> (i*8))
            bytesToEncode.append(byte)
        }
        data.append(contentsOf: bytesToEncode)
    }
}

