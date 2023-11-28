//
//  WalletLogger.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 23.01.2023.
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
import ZcashLightClientKit
import os

public enum LoggerConstants {
    public static let sdkLogs = "sdkLogs"
    public static let tcaLogs = "tcaLogs"
    public static let walletLogs = "walletLogs"
}

public var walletLogger: ZcashLightClientKit.Logger?

public enum LoggerProxy {
    public static func debug(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        walletLogger?.debug(message, file: file, function: function, line: line)
    }
    
    public static func info(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        walletLogger?.info(message, file: file, function: function, line: line)
    }
    
    public static func event(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        walletLogger?.event(message, file: file, function: function, line: line)
    }
    
    public static func warn(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        walletLogger?.warn(message, file: file, function: function, line: line)
    }
    
    public static func error(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        walletLogger?.error(message, file: file, function: function, line: line)
    }
}
