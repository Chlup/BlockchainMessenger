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
import Models
import NewChat
import TransactionsDebug
import Utils
import VerifyChat
import WalletStorage

@Reducer
public struct ChatsListReducer {
    private enum CancelId { case timer }
    let networkType: NetworkType

    public struct State: Equatable {
        public var incomingChats: IdentifiedArrayOf<Chat>
        public var hasFinishedFirstSync = false
        var path = StackState<Path.State>()
        @PresentationState public var sheetPath: SheetPath.State?
        public var shieldedBalance = Balance.zero
        public var synchronizerStatusSnapshot: SyncStatusSnapshot
        public var uAddress: RedactableString = "".redacted
        public var verifiedChats: IdentifiedArrayOf<Chat>

        public var availableMessagesCount: UInt {
            UInt(floor(Double(shieldedBalance.data.verified.amount) / 10_000))
        }

        public var possibleMessagesCount: UInt {
            UInt(floor(Double(shieldedBalance.data.total.amount) / 10_000))
        }

        public var isZeroFundsAccount: Bool {
            shieldedBalance.data.total.amount == 0
            && hasFinishedFirstSync
        }
        
        public init(
            path: StackState<Path.State> = StackState<Path.State>(),
            synchronizerStatusSnapshot: SyncStatusSnapshot
        ) {
            self.path = path
            self.synchronizerStatusSnapshot = synchronizerStatusSnapshot
            self.incomingChats = []
            self.verifiedChats = []
        }
    }
    
    public enum Action: Equatable {
        case chatButtonTapped(Chat)
        case chatRequestsButtonTapped
        case debugButtonTapped
        case didLoadChats(IdentifiedArrayOf<Chat>, IdentifiedArrayOf<Chat>)
        case editChatAliasTapped(Int)
        case fundsButtonTapped
        case newChatButtonTapped
        case onAppear
        case onDisappear
        case path(StackAction<Path.State, Path.Action>)
        case reloadChats
        case sheetPath(PresentationAction<SheetPath.Action>)
        case synchronizerStateChanged(SynchronizerState)
        case uAddressResponse(RedactableString)
    }
    
    public struct Path: Reducer {
        let networkType: NetworkType

        public enum State: Equatable {
            case chatsDetail(ChatDetailReducer.State)
            case transactionsDebug(TransactionsDebugReducer.State)
        }
        
        public enum Action: Equatable {
            case chatsDetail(ChatDetailReducer.Action)
            case transactionsDebug(TransactionsDebugReducer.Action)
        }
        
        public init(networkType: NetworkType) {
            self.networkType = networkType
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.chatsDetail, action: /Action.chatsDetail) {
                ChatDetailReducer(networkType: networkType)
            }

            Scope(state: /State.transactionsDebug, action: /Action.transactionsDebug) {
                TransactionsDebugReducer()
            }
        }
    }
    
    public struct SheetPath: Reducer {
        let networkType: NetworkType

        public enum State: Equatable {
            case funds(FundsReducer.State)
            case newChat(NewChatReducer.State)
            case verifyChat(VerifyChatReducer.State)
        }
        
        public enum Action: Equatable {
            case funds(FundsReducer.Action)
            case newChat(NewChatReducer.Action)
            case verifyChat(VerifyChatReducer.Action)
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
            Scope(state: /State.verifyChat, action: /Action.verifyChat) {
                VerifyChatReducer(networkType: networkType)
            }
        }
    }
    
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.logger) var logger
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.messages) var messages
    @Dependency(\.sdkSynchronizer) var synchronizer
    @Dependency(\.walletStorage) var walletStorage

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    Effect.publisher {
                        synchronizer.stateStream()
                            .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                            .map(ChatsListReducer.Action.synchronizerStateChanged)
                    }
                    .cancellable(id: CancelId.timer, cancelInFlight: true),
                    .run { send in
                        if let address = try await synchronizer.getUnifiedAddress(0) {
                            await send(.uAddressResponse(address.stringEncoded.redacted))
                        }
                    }
                )

            case .onDisappear:
                return .cancel(id: CancelId.timer)

            case .chatButtonTapped(let chat):
                var verificationText: String?
                if chat.fromAddress == state.uAddress.data {
                    verificationText = chat.verificationText
                }
                state.path.append(.chatsDetail(ChatDetailReducer.State(chatId: chat.chatID, verificationText: verificationText)))
                return .none
                
            case .chatRequestsButtonTapped:
                state.sheetPath = .verifyChat(VerifyChatReducer.State())
                return .none

            case .debugButtonTapped:
                state.path.append(.transactionsDebug(TransactionsDebugReducer.State(transactions: [])))
                return .none

            case let .didLoadChats(incomingChats, verifiedChats):
                state.incomingChats = incomingChats
                state.verifiedChats = verifiedChats
                return .none

            case .editChatAliasTapped(let chatId):
                // TODO: API for the chat alias update needed
                logger.debug("\(chatId)")
                return .none
                
            case .fundsButtonTapped:
                state.sheetPath = .funds(FundsReducer.State())
                return .none

            case .newChatButtonTapped:
                state.sheetPath = .newChat(NewChatReducer.State())
                return .none
                
            case .path:
                return .none

            case .reloadChats:
                return .run { send in
                    let chats = try await messages.allChats()

                    let incomingChats: IdentifiedArrayOf<Chat> = IdentifiedArrayOf(
                        uniqueElements:
                            chats.compactMap {
                                guard !$0.verified else { return nil }
                                return $0
                            }
                    )

                    let verifiedChats: IdentifiedArrayOf<Chat> = IdentifiedArrayOf(
                        uniqueElements:
                            chats.compactMap {
                                guard $0.verified else { return nil }
                                return $0
                            }
                    )

                    await send(.didLoadChats(incomingChats, verifiedChats))
                }

            case .sheetPath(.presented(.verifyChat(.chatVerified(let chat)))):
                state.sheetPath = nil
                return .send(.chatButtonTapped(chat))
                
            case .sheetPath(.presented(.newChat(.alert(.dismiss)))):
                state.sheetPath = nil
                return .send(.reloadChats)

//            case .sheetPath(.presented(.newChat(.startChatButtonTapped))):
//                if case .newChat(let newChatState) = state.sheetPath.optional {
//                    let uAddress = newChatState.uAddress
//                    let alias = newChatState.alias
//                    // TODO: here we know what UA user wants to initiate chat with
//                    logger.debug("uAddress: \(uAddress), alias: \(alias)")
//                    // TODO: some messages.createChat is needed
//                    // messages.createChat(for: uAddress, alias: alias)
//                }
//                state.sheetPath = nil
//                return .none

            case .sheetPath:
                return .none
                
            case .synchronizerStateChanged(let latestState):
                let shieldedBalance = latestState.shieldedBalance
                state.shieldedBalance = shieldedBalance.redacted
                
                if shieldedBalance.total.amount > 0 {
                    state.hasFinishedFirstSync = true
                }
                
                let snapshot = SyncStatusSnapshot.snapshotFor(state: latestState.syncStatus)
                if snapshot.syncStatus != state.synchronizerStatusSnapshot.syncStatus {
                    state.synchronizerStatusSnapshot = snapshot
                }
                
                if case .upToDate = latestState.syncStatus {
                    state.hasFinishedFirstSync = true
                    return .send(.reloadChats)
                }
                return .none
                
            case .uAddressResponse(let address):
                state.uAddress = address
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
            fromAddress: """
            utest1zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyz\
            wtgnuc76h
            """,
            toAddress: """
            utest2zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyz\
            wtgnuc76h
            """,
            verificationText: "123456",
            verified: false
        ),
        Chat(
            alias: nil,
            chatID: 1,
            timestamp: 1699290921,
            fromAddress: """
            utest1zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwy\
            zwtgnuc76h
            """,
            toAddress: """
            utest3zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyz\
            wtgnuc76h
            """,
            verificationText: "123456",
            verified: false
        ),
        Chat(
            alias: "Chlup",
            chatID: 2,
            timestamp: 1699295621,
            fromAddress: """
            utest1zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyz\
            wtgnuc76h
            """,
            toAddress: """
            utest4zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyz\
            wtgnuc76h
            """,
            verificationText: "123456",
            verified: true
        ),
        Chat(
            alias: "Janicka, zlaticko moje",
            chatID: 3,
            timestamp: 1699297621,
            fromAddress: """
            utest1zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyz\
            wtgnuc76h
            """,
            toAddress: """
            utest4zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7dwyz\
            wtgnuc76h
            """,
            verificationText: "123456",
            verified: true
        )
    ]
}
