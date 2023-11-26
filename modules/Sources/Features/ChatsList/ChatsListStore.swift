//
//  ChatsListStore.swift
//
//
//  Created by Lukáš Korba on 23.11.2023.
//

import ComposableArchitecture
import ZcashLightClientKit

import ChatDetail
import NewChat
import Messages

public struct ChatsListReducer: Reducer {
    let networkType: NetworkType

    public struct State: Equatable {
        public var incomingChats: IdentifiedArrayOf<Chat>
        @PresentationState public var newChat: NewChatReducer.State?
        var path = StackState<Path.State>()
        public var verifiedChats: IdentifiedArrayOf<Chat>

        public init(path: StackState<Path.State> = StackState<Path.State>()) {
            self.path = path
            
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
        case path(StackAction<Path.State, Path.Action>)
    }
    
    public struct Path: Reducer {
        let networkType: NetworkType

        public enum State: Equatable {
            case chatsDetail(ChatDetailReducer.State)
        }
        
        public enum Action: Equatable {
            case chatsDetail(ChatDetailReducer.Action)
        }
        
        public init(networkType: NetworkType) {
            self.networkType = networkType
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.chatsDetail, action: /Action.chatsDetail) {
                ChatDetailReducer(networkType: networkType)
            }
        }
    }
    
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.messages) var messages
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .chatButtonTapped(let chatId):
                state.path.append(.chatsDetail(ChatDetailReducer.State(chatId: chatId)))
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
                
            case .path:
                return .none
            }
        }
        .ifLet(\.$newChat, action: /Action.newChat) {
            NewChatReducer(networkType: networkType)
        }
        .forEach(\.path, action: /Action.path) {
            Path(networkType: networkType)
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
        ),
        Chat(
            alias: "Janicka, zlaticko moje",
            chatID: 3,
            timestamp: 1699297621,
            fromAddress: "utest1zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyzwtgnuc76h",
            toAddress: "utest4zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyzwtgnuc76h",
            verificationText: "123456",
            verified: true
        )
    ]
}
