//
//  ChatIDBuilder.swift
//  
//
//  Created by Michal Fousek on 21.11.2023.
//

import Foundation
import Dependencies

struct ChatIDBuilder {
    var uniqueID: () -> Int
    var buildForNow: () -> Int
    var build: (_ from: Int, _ uniqueID: Int) -> Int

    private static func uniqueID() -> Int {
        let maxValue = Int(truncating: NSDecimalNumber(decimal: pow(2, 16) - 1))
        return Int.random(in: 0...maxValue)
    }

    private static func build(from timestamp: Int, uniqueID: Int) -> Int {
        var chatID = timestamp
        chatID <<= 16
        chatID |= uniqueID
        return chatID
    }

    static var live: Self {
        return Self(
            uniqueID: { 
                Self.uniqueID()
            },
            buildForNow: {
                @Dependency(\.timestampBuilder) var timestampBuilder
                let timestamp = timestampBuilder.now()
                return Self.build(from: timestamp, uniqueID: Self.uniqueID())
            },
            build: { timestamp, uniqueID in
                return Self.build(from: timestamp, uniqueID: Self.uniqueID())
            }
        )
    }
}

private enum ChatIDBuilderClientKey: DependencyKey {
    static let liveValue: ChatIDBuilder = ChatIDBuilder.live
}

extension DependencyValues {
    var chatIDBuilder: ChatIDBuilder {
        get { self[ChatIDBuilderClientKey.self] }
        set { self[ChatIDBuilderClientKey.self] = newValue }
    }
}
