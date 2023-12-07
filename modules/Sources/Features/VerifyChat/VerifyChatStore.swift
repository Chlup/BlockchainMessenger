//
//  VerifyChatStore.swift
//
//
//  Created by Lukáš Korba on 07.12.2023.
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

import DerivationTool
import Messages
import Utils

@Reducer
public struct VerifyChatReducer {
    private enum CancelId { case timer }
    let networkType: NetworkType

    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action>?
        @BindingState public var alias = ""
        var isValidAlias = false
        var isValidVerificationText = false
        var isVerifying = false
        @BindingState public var uAddress = ""
        @BindingState public var verificationText = ""

        public var isValidForm: Bool {
            isValidAlias
            && isValidVerificationText
            && !isVerifying
        }
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Action>)
        case binding(BindingAction<State>)
        case chatVerified(Chat)
        case noneChatHasBeenVerified
        case verifyButtonTapped
    }
      
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.logger) var logger
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.messages) var messages

    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
//            case .alert(.presented):
//                return .run { _ in
//                    await self.dismiss()
//                }

            case .alert:
                return .none

            case .binding:
                state.isValidAlias = !state.alias.isEmpty
                state.isValidVerificationText = !state.verificationText.isEmpty
                return .none
                
            case .chatVerified:
                state.isVerifying = false
                return .none

            case .noneChatHasBeenVerified:
                state.alert = AlertState.noneChatHasBeenVerified()
                state.isVerifying = false
                return .none

            case .verifyButtonTapped:
                state.isVerifying = true
                return .run { [uAddress = state.uAddress, alias = state.alias, verificationText = state.verificationText] send in
                    do {
                        let chat = try await messages.verifyChat(
                            fromAddress: uAddress,
                            verificationText: verificationText,
                            alias: alias
                        )
                        await send(.chatVerified(chat))
                    } catch {
                        await send(.noneChatHasBeenVerified)
                    }
                }
            }
        }
    }
}

extension AlertState where Action == VerifyChatReducer.Action {
    static func noneChatHasBeenVerified() -> Self {
        Self {
            TextState("No chat found")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
        } message: {
            TextState("We haven't found any chat that correspond to the data you provided.")
        }
    }
}
