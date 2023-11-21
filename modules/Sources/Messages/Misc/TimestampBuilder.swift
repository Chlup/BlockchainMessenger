//
//  TimestampBuilder.swift
//
//
//  Created by Michal Fousek on 21.11.2023.
//

import Foundation
import Dependencies

struct TimestampBuilder {
    // Number of seconds since 1.1.2001
    var now: () -> Int
    // `timestamp` is number of seconds since 1.1.2001
    var date: (_ fromTimestamp: Int) -> Date

    static var live: TimestampBuilder {
        return Self(
            now: {
                Int(Date().timeIntervalSinceReferenceDate)
            }, 
            date: { timestamp in
                return Date(timeIntervalSinceReferenceDate: TimeInterval(timestamp))
            }
        )
    }
}

private enum TimestampBuilderClientKey: DependencyKey {
    static let liveValue: TimestampBuilder = TimestampBuilder.live
}

extension DependencyValues {
    var timestampBuilder: TimestampBuilder {
        get { self[TimestampBuilderClientKey.self] }
        set { self[TimestampBuilderClientKey.self] = newValue }
    }
}
