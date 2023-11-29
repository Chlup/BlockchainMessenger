//
//  ChatsListView.swift
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

import ComposableArchitecture
import SwiftUI
import ZcashLightClientKit

import ChatDetail
import Funds
import Generated
import Messages
import Models
import NewChat
import TransactionsDebug
import Utils

public struct ChatsListView: View {
    let store: StoreOf<ChatsListReducer>
    
    public init(store: StoreOf<ChatsListReducer>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStackStore(
            store.scope(state: \.path, action: \.path)
        ) {
            WithViewStore(self.store, observe: { $0 }) { viewStore in
                VStack(alignment: .leading) {
                    // TODO: temporary development debug info of the synchronizer
                    VStack(alignment: .leading) {
                        HStack {
                            Text("verified \(viewStore.shieldedBalance.data.verified.decimalZashiFormatted()) TAZ")
                            Text("total \(viewStore.shieldedBalance.data.total.decimalZashiFormatted()) TAZ")
                        }

                        Text("Synchronizer: \(viewStore.synchronizerStatusSnapshot.message)")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .font(.system(size: 11))
                    .foregroundStyle(Asset.Colors.fontPrimary.color)

                    List {
                        if !viewStore.incomingChats.isEmpty {
                            HStack {
                                Text("Chats")
                                    .font(.system(size: 36))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Asset.Colors.fontPrimary.color)
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            
                            HStack {
                                Text("Incoming chats")
                                
                                Text("\(viewStore.incomingChats.count)")
                                    .foregroundStyle(.white)
                                    .padding(7)
                                    .background {
                                        Circle()
                                            .foregroundStyle(.red)
                                    }
                            }
                            .neumorphicButton()
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        
                        ForEach(viewStore.verifiedChats) { chat in
                            Button {
                                viewStore.send(.chatButtonTapped(chat.chatID))
                            } label: {
                                // TODO: This alias work is just hack to show new chats for now.
                                Text(chat.alias ?? "unknown")
                                    .neumorphicButton()
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        viewStore.send(.reloadChats)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            viewStore.send(.fundsButtonTapped)
                        } label: {
                            Group {
                                Text("Funds for")
                                    .foregroundColor(Asset.Colors.fontPrimary.color)
                                + Text(" \(viewStore.availableMessagesCount)/\(viewStore.possibleMessagesCount) messages")
                                    .foregroundColor(.white)
                            }
                            .font(.system(size: 15))
                        }
                        .padding(.leading, 5)
                        .padding(.horizontal, 5)
                        .neumorphicShape()
                        .padding(.leading, 15)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewStore.send(.debugButtonTapped)
                        } label: {
                            Image(systemName: "ladybug")
                                .renderingMode(.template)
                                .tint(Asset.Colors.fontPrimary.color)
                            //                                .neumorphicButton(
                            //                                    // style: .blue
                            //                                    // Asset.Colors.ChatDetail.sent2.color
                            //                                )
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewStore.send(.newChatButtonTapped)
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .renderingMode(.template)
                                .tint(Asset.Colors.fontPrimary.color)
//                                .neumorphicButton(
//                                    // style: .blue
//                                    // Asset.Colors.ChatDetail.sent2.color
//                                )
                        }
                    }
                }
                .sheet(
                    store: self.store.scope(
                        state: \.$sheetPath,
                        action: \.sheetPath
                    )
                ) { store in
                    SwitchStore(store) {
                        switch $0 {
                        case .funds:
                            CaseLet(
                                /ChatsListReducer.SheetPath.State.funds,
                                action: ChatsListReducer.SheetPath.Action.funds,
                                then: FundsView.init(store:)
                            )
                        case .newChat:
                            CaseLet(
                                /ChatsListReducer.SheetPath.State.newChat,
                                action: ChatsListReducer.SheetPath.Action.newChat,
                                then: NewChatView.init(store:)
                            )
                        }
                    }
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
                .onDisappear {
                    viewStore.send(.onDisappear)
                }
            }
            .applyScreenBackground()
        } destination: { state in
            switch state {
            case .chatsDetail:
                CaseLet(
                    /ChatsListReducer.Path.State.chatsDetail,
                    action: ChatsListReducer.Path.Action.chatsDetail,
                    then: ChatDetailView.init(store:)
                )

            case .transactionsDebug:
                CaseLet(
                    /ChatsListReducer.Path.State.transactionsDebug,
                    action: ChatsListReducer.Path.Action.transactionsDebug,
                    then: TransactionsDebugView.init(store:)
                )
            }
        }
    }
}

#Preview {
    ChatsListView(
        store:
            Store(
                initialState: ChatsListReducer.State(
                    synchronizerStatusSnapshot: .placeholder
                )
            ) {
                ChatsListReducer(
                    networkType: ZcashNetworkBuilder.network(for: .testnet).networkType
                )
                ._printChanges()
            }
    )
}
