//
//  RootView.swift
//  
//
//  Created by Lukáš Korba on 20.11.2023.
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
import SwiftUI
import ZcashLightClientKit

import ChatDetail
import ChatsList
import CreateAccount
import Generated
import RestoreAccount

public struct RootView: View {
    let store: StoreOf<RootReducer>
    
    public init(store: StoreOf<RootReducer>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            IfLetStore(
                store.scope(state: \.$path, action: \.path)
            ) { store in
                SwitchStore(store) {
                    switch $0 {
                    case .chatsList:
                        CaseLet(
                            /RootReducer.Path.State.chatsList,
                             action: RootReducer.Path.Action.chatsList,
                             then: ChatsListView.init(store:)
                        )
                    case .createAccount:
                        CaseLet(
                            /RootReducer.Path.State.createAccount,
                             action: RootReducer.Path.Action.createAccount,
                             then: CreateAccountView.init(store:)
                        )
                    case .restoreAccount:
                        CaseLet(
                            /RootReducer.Path.State.restoreAccount,
                             action: RootReducer.Path.Action.restoreAccount,
                             then: RestoreAccountView.init(store:)
                        )
                    }
                }
            } else: {
                if viewStore.isLoading {
                    HStack(spacing: 10) {
                        Text("Initializing")
                            .foregroundStyle(Asset.Colors.fontPrimary.color)
                        ProgressView()
                    }
                    .applyScreenBackground()
                } else {
                    VStack(spacing: 30) {
                        Button {
                            viewStore.send(.createAccount)
                        } label: {
                            Text("Create account")
                        }
                        .neumorphicButton()

                        Button {
                            viewStore.send(.restoreAccount)
                        } label: {
                            Text("Restore account")
                        }
                        .neumorphicButton()
                    }
                    .padding(.horizontal, 35)
                    .applyScreenBackground()
                }
            }
        }
    }
}

#Preview {
    RootView(
        store:
            Store(
                initialState: RootReducer.State(isLoading: false)
            ) {
                RootReducer(zcashNetwork: ZcashNetworkBuilder.network(for: .testnet))
                    ._printChanges()
            }
    )
}
