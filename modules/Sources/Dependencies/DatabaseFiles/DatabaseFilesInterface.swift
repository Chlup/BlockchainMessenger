//
//  DatabaseFilesInterface.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 11.11.2022.
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
