//
//  SecItemClient.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 12.04.2022.
//
//  MIT License
//
//  Copyright (c) 2023 Zcash
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
import Security

public struct SecItemClient {
    public let copyMatching: (CFDictionary, inout CFTypeRef?) -> OSStatus
    public let add: (CFDictionary, inout CFTypeRef?) -> OSStatus
    public let update: (CFDictionary, CFDictionary) -> OSStatus
    public let delete: (CFDictionary) -> OSStatus
    
    public init(
        copyMatching: @escaping (CFDictionary, inout CFTypeRef?) -> OSStatus,
        add: @escaping (CFDictionary, inout CFTypeRef?) -> OSStatus,
        update: @escaping (CFDictionary, CFDictionary) -> OSStatus,
        delete: @escaping (CFDictionary) -> OSStatus
    ) {
        self.copyMatching = copyMatching
        self.add = add
        self.update = update
        self.delete = delete
    }
}
