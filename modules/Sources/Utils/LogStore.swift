//
//  LogStore.swift
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
import OSLog
    
public enum LogStore {
    public static func exportCategory(
        _ category: String,
        hoursToThePast: TimeInterval = 168,
        fileSize: Int = 1_000_000
    ) async throws -> [String]? {
        guard let bundle = Bundle.main.bundleIdentifier else { return nil }
        
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let date = Date.now.addingTimeInterval(-hoursToThePast * 3600)
        let position = store.position(date: date)
        var res: [String] = []
        var size = 0
        
        let entries = try store.getEntries(at: position).reversed()
        for entry in entries {
            guard let logEntry = entry as? OSLogEntryLog else { continue }
            guard logEntry.subsystem == bundle && logEntry.category == category else { continue }
            
            guard size < fileSize else { break }
            
            size += logEntry.composedMessage.utf8.count
            res.append("[\(logEntry.date.timestamp())] \(logEntry.composedMessage)")
        }
        
        return res
    }
}
