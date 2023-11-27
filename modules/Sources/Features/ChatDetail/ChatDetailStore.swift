//
//  ChatDetailStore.swift
//
//
//  Created by Lukáš Korba on 25.11.2023.
//

import ComposableArchitecture
import ZcashLightClientKit

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
    }
      
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.messages) var messages
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
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
