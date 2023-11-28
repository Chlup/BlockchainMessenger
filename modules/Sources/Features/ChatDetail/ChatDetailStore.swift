//
//  ChatDetailStore.swift
//
//
//  Created by Lukáš Korba on 25.11.2023.
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

import ComposableArchitecture
import ZcashLightClientKit

import Logger
import Messages

@Reducer
public struct ChatDetailReducer {
    let networkType: NetworkType

    public struct State: Equatable {
        public var chatId: Int
        public var messages: IdentifiedArrayOf<Message> = []

        public init(chatId: Int) {
            self.chatId = chatId
            self.messages = Message.mockedMessages
        }
    }
    
    public enum Action: Equatable {
        case messagesLoaded(IdentifiedArrayOf<Message>)
        case onAppear
        case send(String)
    }
      
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.messages) var messages
    @Dependency(\.logger) var logger

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { [chatId = state.chatId] send in
                    var messages = try await messages.allMessages(for: chatId)
                    if messages.isEmpty {
                        // TODO: This is just for now to let mocking for mocked chats work.
                        messages = Array(Message.mockedMessages)
                    }

                    await send(.messagesLoaded(IdentifiedArrayOf(uniqueElements: messages)))
                }

            case .messagesLoaded(let messages):
                state.messages = messages
                return .none
            
            case .send(let text):
                return .run { [chatId = state.chatId] send in
                    do {
                        _ = try await messages.sendMessage(chatID: chatId, text: text)
                        let messages = try await messages.allMessages(for: chatId)
                        await send(.messagesLoaded(IdentifiedArrayOf(uniqueElements: messages)))
                    } catch {
                        // TODO: error handling
                        self.logger.debug("oh no :( \(error)")
                    }
                }
            }
        }
    }
}

extension Message {
    public static let mockedMessages: IdentifiedArrayOf<Message> = [
        Message(
            id: 1,
            chatID: 1,
            timestamp: 1699290621,
            text: "Cau Chlupaku, posli mi pls ty supertajny kody",
            isSent: true
        ),
        Message(
            id: 2,
            chatID: 1,
            timestamp: 1699290721,
            text: "ktery kody myslis?",
            isSent: false
        ),
        Message(
            id: 3,
            chatID: 1,
            timestamp: 1699290821,
            text: "Na bitcoin ucet",
            isSent: true
        ),
        Message(
            id: 4,
            chatID: 1,
            timestamp: 1699290921,
            text: "Jasne, uz vim... asdkjad asdasd qweeqew wrqwr adsasd asd adarfq adef, ale nikomu je nedavej, je to dulezity",
            isSent: false
        ),
        Message(
            id: 5,
            chatID: 1,
            timestamp: 1699291021,
            text: "jasne, neboj",
            isSent: true
        )
    ]
}
