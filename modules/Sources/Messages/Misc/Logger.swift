//
//  Logger.swift
//  
//
//  Created by Michal Fousek on 20.11.2023.
//

import Foundation
import Dependencies
import ZcashLightClientKit

private enum LoggerClientKey: DependencyKey {
    static let liveValue: Logger = OSLogger(logLevel: .debug, category: "chat")
}

extension DependencyValues {
    public var logger: Logger {
        get { self[LoggerClientKey.self] }
        set { self[LoggerClientKey.self] = newValue }
    }
}
