//
//  SQLiteConnectionProvider.swift
//
//
//  Created by Michal Fousek on 24.11.2023.
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
import SQLite
import DatabaseFiles
import Dependencies

protocol ConnectionProvider {
    var path: String { get }
    func connection() throws -> Connection
    func close()
}

class SimpleConnectionProvider: ConnectionProvider {
    let path: String
    let readonly: Bool
    var db: Connection?

    init(path: String, readonly: Bool = false) {
        self.path = path
        self.readonly = readonly
    }

    func connection() throws -> Connection {
        guard let conn = db else {
            do {
                let conn = try Connection(path, readonly: readonly)
                self.db = conn
                return conn
            } catch {
                throw MError.simpleConnectionProvider(error)
            }
        }
        return conn
    }

    func close() {
        self.db = nil
    }

    static func live(databaseFiles: DatabaseFilesClient = .liveValue) -> ConnectionProvider {
        return SimpleConnectionProvider(path: databaseFiles.messagesDBURL().path, readonly: false)
    }
}

private enum ConnectionProviderClientKey: DependencyKey {
    static let liveValue: ConnectionProvider = SimpleConnectionProvider.live()
}

extension DependencyValues {
    var messagesDBConnectionProvider: ConnectionProvider {
        get { self[ConnectionProviderClientKey.self] }
        set { self[ConnectionProviderClientKey.self] = newValue }
    }
}
