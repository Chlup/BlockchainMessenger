//
//  ChatsListStore.swift
//
//
//  Created by Lukáš Korba on 23.11.2023.
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

import Foundation
import ComposableArchitecture
import ZcashLightClientKit

import ChatDetail
import Funds
import Messages
import NewChat
import Utils

@Reducer
public struct ChatsListReducer {
    private enum CancelId { case timer }
    let networkType: NetworkType

    public struct State: Equatable {
        public var incomingChats: IdentifiedArrayOf<Chat>
        @PresentationState public var sheetPath: SheetPath.State?
        var path = StackState<Path.State>()
        public var shieldedBalance = Balance.zero
        public var verifiedChats: IdentifiedArrayOf<Chat>

        public var availableMessagesCount: UInt {
            UInt(floor(Double(shieldedBalance.data.verified.amount) / 10_001))
        }

        public var possibleMessagesCount: UInt {
            UInt(floor(Double(shieldedBalance.data.total.amount) / 10_001))
        }

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
        case fundsButtonTapped
        case newChatButtonTapped
        case onAppear
        case onDisappear
        case path(StackAction<Path.State, Path.Action>)
        case sheetPath(PresentationAction<SheetPath.Action>)
        case synchronizerStateChanged(SynchronizerState)
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
    
    public struct SheetPath: Reducer {
        let networkType: NetworkType

        public enum State: Equatable {
            case funds(FundsReducer.State)
            case newChat(NewChatReducer.State)
        }
        
        public enum Action: Equatable {
            case funds(FundsReducer.Action)
            case newChat(NewChatReducer.Action)
        }
        
        public init(networkType: NetworkType) {
            self.networkType = networkType
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.funds, action: /Action.funds) {
                FundsReducer(networkType: networkType)
            }
            Scope(state: /State.newChat, action: /Action.newChat) {
                NewChatReducer(networkType: networkType)
            }
        }
    }
    
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.messages) var messages
    @Dependency(\.sdkSynchronizer) var synchronizer
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return Effect.publisher {
                    synchronizer.stateStream()
                        .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                        .map(ChatsListReducer.Action.synchronizerStateChanged)
                }
                .cancellable(id: CancelId.timer, cancelInFlight: true)

            case .onDisappear:
                return .cancel(id: CancelId.timer)

            case .chatButtonTapped(let chatId):
                state.path.append(.chatsDetail(ChatDetailReducer.State(chatId: chatId)))
                return .none

            case .fundsButtonTapped:
                state.sheetPath = .funds(FundsReducer.State())
                return .none

            case .newChatButtonTapped:
                state.sheetPath = .newChat(NewChatReducer.State())
                return .none
                
            case .path:
                return .none

            case .sheetPath(.presented(.newChat(.startChatButtonTapped))):
                if case .newChat(let newChatState) = state.sheetPath.optional {
                    let uAddress = newChatState.uAddress
                    let alias = newChatState.alias
                    // TODO: here we know what UA user wants to initiate chat with
                    print("uAddress: \(uAddress), alias: \(alias)")
                    // TODO: some messages.createChat is needed
                    // messages.createChat(for: uAddress, alias: alias)
                }
                state.sheetPath = nil
                return .none

            case .sheetPath:
                return .none
                
            case .synchronizerStateChanged(let latestState):
                let shieldedBalance = latestState.shieldedBalance
                state.shieldedBalance = shieldedBalance.redacted
                return .none
            }
        }
        .ifLet(\.$sheetPath, action: \.sheetPath) {
            SheetPath(networkType: networkType)
        }
        .forEach(\.path, action: \.path) {
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
