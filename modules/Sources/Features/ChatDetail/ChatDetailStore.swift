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
import Utils

@Reducer
public struct ChatDetailReducer {
    private enum CancelId { case timer }
    let networkType: NetworkType

    public struct State: Equatable {
        public var chatId: Int
        public var isSyncing = false
        @BindingState public var message = ""
        public var messages: IdentifiedArrayOf<Message> = []
        public var shieldedBalance = Balance.zero

        public var isSendAvailable: Bool {
            shieldedBalance.data.verified.amount > 0 && !isSyncing
        }
        
        public init(chatId: Int) {
            self.chatId = chatId
            self.messages = Message.mockedMessages
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case messagesLoaded(IdentifiedArrayOf<Message>)
        case onAppear
        case sendButtonTapped
        case synchronizerStateChanged(SynchronizerState)
    }
      
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.logger) var logger
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.messages) var messages
    @Dependency(\.sdkSynchronizer) var synchronizer

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .run { [chatId = state.chatId] send in
                        var messages = try await messages.allMessages(for: chatId)
                        if messages.isEmpty {
                            // TODO: This is just for now to let mocking for mocked chats work.
                            messages = Array(Message.mockedMessages)
                        }

                        await send(.messagesLoaded(IdentifiedArrayOf(uniqueElements: messages)))
                    },
                    Effect.publisher {
                        synchronizer.stateStream()
                            .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                            .map(ChatDetailReducer.Action.synchronizerStateChanged)
                    }
                    .cancellable(id: CancelId.timer, cancelInFlight: true)
                )

            case .binding:
                return .none

            case .messagesLoaded(let messages):
                state.messages = messages
                return .none
            
            case .sendButtonTapped:
                let message = state.message
                state.message = ""
                return .run { [chatId = state.chatId] send in
                    do {
                        _ = try await messages.sendMessage(chatID: chatId, text: message)
                        let messages = try await messages.allMessages(for: chatId)
                        await send(.messagesLoaded(IdentifiedArrayOf(uniqueElements: messages)))
                    } catch {
                        // TODO: error handling
                        self.logger.debug("oh no :( \(error)")
                    }
                }
                
            case .synchronizerStateChanged(let latestState):
                let shieldedBalance = latestState.shieldedBalance
                state.shieldedBalance = shieldedBalance.redacted
                
                if case .upToDate = latestState.syncStatus {
                    state.isSyncing = false
                    return .run { [chatId = state.chatId, currentMessages = state.messages] send in
                        let messages = IdentifiedArrayOf(uniqueElements: try await messages.allMessages(for: chatId))
                        if currentMessages != messages {
                            await send(.messagesLoaded(IdentifiedArrayOf(uniqueElements: messages)))
                        }
                    }
                }
                if case .syncing = latestState.syncStatus {
                    state.isSyncing = true
                }
                return .none
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
