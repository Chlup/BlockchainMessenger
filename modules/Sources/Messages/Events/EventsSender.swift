//
//  EventsSender.swift
//
//
//  Created by Michal Fousek on 28.11.2023.
//
//  MIT License
//
//  Copyright (c) 2023 Mugeaters
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

import Combine
import Dependencies
import Foundation

protocol EventsSender {
    var eventsStream: AnyPublisher<MessagesEvent, Never> { get }
    func send(event: MessagesEvent)
}

struct EventsSenderImpl {
    private let eventSubject = PassthroughSubject<MessagesEvent, Never>()
    private let workQueue = DispatchQueue(label: "EventsSenderImpl")
}

extension EventsSenderImpl: EventsSender {
    var eventsStream: AnyPublisher<MessagesEvent, Never> { eventSubject.eraseToAnyPublisher() }

    func send(event: MessagesEvent) {
        workQueue.async {
            self.eventSubject.send(event)
        }
    }
}

private enum EventsSenderClientKey: DependencyKey {
    static let liveValue: EventsSender = EventsSenderImpl()
}

extension DependencyValues {
    var eventsSender: EventsSender {
        get { self[EventsSenderClientKey.self] }
        set { self[EventsSenderClientKey.self] = newValue }
    }
}
