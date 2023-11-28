//
//  DatabaseFilesInterface.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 11.11.2022.
//

import Foundation
import ComposableArchitecture
import ZcashLightClientKit

extension DependencyValues {
    public var databaseFiles: DatabaseFilesClient {
        get { self[DatabaseFilesClient.self] }
        set { self[DatabaseFilesClient.self] = newValue }
    }
}

@DependencyClient
public struct DatabaseFilesClient {
    public var documentsDirectory: () -> URL = { .emptyURL }
    public var fsBlockDbRootFor: (ZcashNetwork) -> URL = { _ in .emptyURL }
    public var cacheDbURLFor: (ZcashNetwork) -> URL = { _ in .emptyURL }
    public var dataDbURLFor: (ZcashNetwork) -> URL = { _ in .emptyURL }
    public var outputParamsURLFor: (ZcashNetwork) -> URL = { _ in .emptyURL }
    public var pendingDbURLFor: (ZcashNetwork) -> URL = { _ in .emptyURL }
    public var spendParamsURLFor: (ZcashNetwork) -> URL = { _ in .emptyURL }
    public var areDbFilesPresentFor: (ZcashNetwork) -> Bool = { _ in false }
    public var messagesDBURL: () -> URL = { .emptyURL }
}
