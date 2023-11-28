//
//  DatabaseFiles.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 05.04.2022.
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
import FileManager

public struct DatabaseFiles {
    enum DatabaseFilesError: Error {
        case getFsBlockDbRoot
        case getDocumentsURL
        case getCacheURL
        case getDataURL
        case getOutputParamsURL
        case getPendingURL
        case getSpendParamsURL
        case nukeFiles
        case filesPresentCheck
    }
    
    private let fileManager: FileManagerClient
    
    public init(fileManager: FileManagerClient) {
        self.fileManager = fileManager
    }
    
    func documentsDirectory() -> URL {
        do {
            return try fileManager.url(.documentDirectory, .userDomainMask, nil, true)
        } catch {
            // This is not super clean but this is second best thing when the above call fails.
            return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
        }
    }

    func cacheDbURL(for network: ZcashNetwork) -> URL {
        return documentsDirectory()
            .appendingPathComponent(
                "\(network.constants.defaultDbNamePrefix)cache.db",
                isDirectory: false
            )
    }

    func dataDbURL(for network: ZcashNetwork) -> URL {
        return documentsDirectory()
            .appendingPathComponent(
                "\(network.constants.defaultDbNamePrefix)data.db",
                isDirectory: false
                )
    }

    func outputParamsURL(for network: ZcashNetwork) -> URL {
        return documentsDirectory()
            .appendingPathComponent(
                "\(network.constants.defaultDbNamePrefix)sapling-output.params",
                isDirectory: false
            )
    }

    func pendingDbURL(for network: ZcashNetwork) -> URL {
        return documentsDirectory()
            .appendingPathComponent(
                "\(network.constants.defaultDbNamePrefix)pending.db",
                isDirectory: false
            )
    }

    func spendParamsURL(for network: ZcashNetwork) -> URL {
        return documentsDirectory()
            .appendingPathComponent(
                "\(network.constants.defaultDbNamePrefix)sapling-spend.params",
                isDirectory: false
            )
    }

    func areDbFilesPresent(for network: ZcashNetwork) -> Bool {
        let dataDbURL = dataDbURL(for: network)
        return fileManager.fileExists(dataDbURL.path)
    }

    func messagesDBURL() -> URL {
        return documentsDirectory()
            .appendingPathComponent(
                "messages.db",
                isDirectory: false
            )
    }
}
