//
//  NewChatStore.swift
//
//
//  Created by Lukáš Korba on 24.11.2023.
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

import ChatVerification
import DerivationTool
import Messages
import Utils

@Reducer
public struct NewChatReducer {
    private enum CancelId { case timer }
    let networkType: NetworkType

    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action>?
        @BindingState public var alias = ""
        var isValidAddress = false
        var isValidAlias = false
        var isCreatingNewChat = false
        public var shieldedBalance = Balance.zero
        @BindingState public var uAddress = ""

        public var isValidForm: Bool {
            shieldedBalance.data.verified.amount > 10_000
            && isValidAddress
            && isValidAlias
            && !isCreatingNewChat
        }
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Action>)
        case binding(BindingAction<State>)
        case newChatCreated(String, String)
        case newChatFailed
        case onAppear
        case onDisappear
        case startChatButtonTapped
        case synchronizerStateChanged(SynchronizerState)
    }
      
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.chatVerification) var chatVerification
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.logger) var logger
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.messages) var messages
    @Dependency(\.sdkSynchronizer) var synchronizer

    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return Effect.publisher {
                    synchronizer.stateStream()
                        .throttle(for: .seconds(0.2), scheduler: mainQueue, latest: true)
                        .map(NewChatReducer.Action.synchronizerStateChanged)
                }
                .cancellable(id: CancelId.timer, cancelInFlight: true)
                
            case .onDisappear:
                return .cancel(id: CancelId.timer)

            case .alert(.presented):
                return .run { _ in
                    await self.dismiss()
                }

            case .alert:
                return .none

            case .binding:
                state.isValidAddress = derivationTool.isUnifiedAddress(state.uAddress, networkType)
                state.isValidAlias = !state.alias.isEmpty
                return .none

            case let .newChatCreated(alias, code):
                state.alert = AlertState.chatCreated(for: alias, with: code)
                state.isCreatingNewChat = false
                return .none

            case .newChatFailed:
                state.alert = AlertState.newChatFailed()
                state.isCreatingNewChat = false
                return .none
                
            case .startChatButtonTapped:
                logger.debug("uAddress: \(state.uAddress), alias: \(state.alias)")
                state.isCreatingNewChat = true
                return .run { [uAddress = state.uAddress, alias = state.alias] send in
                    do {
                        guard let myUA = try await synchronizer.getUnifiedAddress(account: 0)?.stringEncoded else {
                            await send(.newChatFailed)
                            return
                        }
                        let verificationCode = chatVerification.code()
                        try await messages.newChat(
                            fromAddress: myUA,
                            toAddress: uAddress,
                            verificationText: verificationCode,
                            alias: alias
                        )
                        await send(.newChatCreated(alias, verificationCode))
                    } catch {
                        // TODO: Error handling
                        await send(.newChatFailed)
                    }
                }
                
            case .synchronizerStateChanged(let latestState):
                let shieldedBalance = latestState.shieldedBalance
                state.shieldedBalance = shieldedBalance.redacted
                return .none
            }
        }
    }
}

extension AlertState where Action == NewChatReducer.Action {
    static func chatCreated(for alias: String, with code: String) -> Self {
        Self {
            TextState("New Chat Created")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("Confirm")
            }
        } message: {
            TextState("New chat has been successfuly created with alias: \(alias). Share the following verification code with the receiver \n\n \(code) \n\n (you can see it also in the chat as a first message)")
        }
    }
    
    static func newChatFailed() -> Self {
        Self {
            TextState("New Chat Failed")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
        } message: {
            TextState("Creation of the new chat failed.")
        }
    }
}
