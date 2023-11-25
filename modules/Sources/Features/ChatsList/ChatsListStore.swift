//
//  ChatsListStore.swift
//
//
//  Created by Lukáš Korba on 23.11.2023.
//

import ComposableArchitecture
import ZcashLightClientKit

import NewChat
import Messages

public struct ChatsListReducer: Reducer {
    let networkType: NetworkType

    public struct State: Equatable {
        @PresentationState public var newChat: NewChatReducer.State?
        public var incomingChats: IdentifiedArrayOf<Chat>
        public var verifiedChats: IdentifiedArrayOf<Chat>

        public init() {
            let chats = Chat.mockedChats
            
            self.incomingChats = IdentifiedArrayOf(
                uniqueElements:
                    chats.compactMap {
                        guard !$0.verified else { return nil }
                        return $0
                    }
            )

            self.verifiedChats = IdentifiedArrayOf(
                uniqueElements:
                    chats.compactMap {
                        guard $0.verified else { return nil }
                        return $0
                    }
            )
        }
    }
    
    public enum Action: Equatable {
        case chatButtonTapped(Int)
        case newChat(PresentationAction<NewChatReducer.Action>)
        case newChatButtonTapped
    }
      
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.messages) var messages
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .chatButtonTapped:
                return .none

            case .newChat(.presented(.startChatButtonTapped)):
                if let uAddress = state.newChat?.uAddress, let alias = state.newChat?.alias {
                    // TODO: here we know what UA user wants to initiate chat with
                    print("uAddress: \(uAddress), alias: \(alias)")
                    // TODO: some messages.createChat is needed
                    // messages.createChat(for: uAddress, alias: alias)
                }
                state.newChat = nil
                return .none
                
            case .newChat:
                return .none
            
            case .newChatButtonTapped:
                state.newChat = NewChatReducer.State()
                return .none
            }
        }
        .ifLet(\.$newChat, action: /Action.newChat) {
            NewChatReducer(networkType: networkType)
        }
    }
}

extension Chat {
    static let mockedChats: IdentifiedArrayOf<Chat> = [
        Chat(
            alias: nil,
            chatID: 0,
            timestamp: 1699290621,
            fromAddress: "utest1zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyzwtgnuc76h",
            toAddress: "utest2zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyzwtgnuc76h",
            verificationText: "123456",
            verified: false
        ),
        Chat(
            alias: nil,
            chatID: 1,
            timestamp: 1699290921,
            fromAddress: "utest1zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyzwtgnuc76h",
            toAddress: "utest3zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyzwtgnuc76h",
            verificationText: "123456",
            verified: false
        ),
        Chat(
            alias: "Chlup",
            chatID: 2,
            timestamp: 1699295621,
            fromAddress: "utest1zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyzwtgnuc76h",
            toAddress: "utest4zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyzwtgnuc76h",
            verificationText: "123456",
            verified: true
        )
    ]
}
