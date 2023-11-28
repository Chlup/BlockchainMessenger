//
//  DatabaseFilesTestKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 11.11.2022.
//

import Foundation
import ComposableArchitecture
import XCTestDynamicOverlay
import Utils

extension DatabaseFilesClient: TestDependencyKey {
    public static let previewValue = Self.noOp
    public static let testValue = Self()
}

extension DatabaseFilesClient {
    public static let noOp = Self(
        documentsDirectory: { .emptyURL },
        fsBlockDbRootFor: { _ in .emptyURL },
        cacheDbURLFor: { _ in .emptyURL },
        dataDbURLFor: { _ in .emptyURL },
        outputParamsURLFor: { _ in .emptyURL },
        pendingDbURLFor: { _ in .emptyURL },
        spendParamsURLFor: { _ in .emptyURL },
        areDbFilesPresentFor: { _ in false },
        messagesDBURL: {.emptyURL }
    )
}
