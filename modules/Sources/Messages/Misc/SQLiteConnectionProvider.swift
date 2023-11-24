//
//  SQLiteConnectionProvider.swift
//
//
//  Created by Michal Fousek on 24.11.2023.
//

import Foundation
import SQLite
import DatabaseFiles
import Dependencies

protocol ConnectionProvider {
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
                throw MessagesError.simpleConnectionProvider(error)
            }
        }
        return conn
    }

    func close() {
        self.db = nil
    }

    static func live(databaseFiles: DatabaseFilesClient = .liveValue) -> ConnectionProvider {
        print("DB path: \(databaseFiles.messagesDBURL().path)")
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
