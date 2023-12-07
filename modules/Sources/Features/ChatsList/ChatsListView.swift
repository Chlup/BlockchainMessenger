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
import VerifyChat

public struct ChatsListView: View {
    let store: StoreOf<ChatsListReducer>
    @State var bounceScale: CGFloat = 1

    public init(store: StoreOf<ChatsListReducer>) {
        self.store = store
    }

    func scaleAnimation() {
        withAnimation(Animation.easeOut(duration: 0.1)) {
            bounceScale = 1.05
        }
        withAnimation(Animation.easeOut(duration: 0.1).delay(0.1)) {
            bounceScale = 0.95
        }
        withAnimation(Animation.easeOut(duration: 0.1).delay(0.2)) {
            bounceScale = 1.0
        }
    }
    
    public var body: some View {
        NavigationStackStore(
            store.scope(state: \.path, action: \.path)
        ) {
            WithViewStore(self.store, observe: { $0 }) { viewStore in
                VStack(alignment: .leading) {
                    ProgressView(
                        value: Double(viewStore.availableMessagesCount),
                        total: Double(viewStore.possibleMessagesCount)
                    )
                    .frame(maxWidth: .infinity)

                    if viewStore.isZeroFundsAccount {
                        zeroFundsView(viewStore)
                            .scaleEffect(x: bounceScale, y: bounceScale, anchor: .center)
                    }
                    
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
                            
                            Button {
                                viewStore.send(.chatRequestsButtonTapped)
                            } label: {
                                HStack {
                                    Text("Chat requests")
                                    
                                    Text("\(viewStore.incomingChats.count)")
                                        .foregroundStyle(.white)
                                        .padding(7)
                                        .background {
                                            Circle()
                                                .foregroundStyle(.red)
                                        }
                                }
                            }
                            .neumorphicButton()
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        
                        ForEach(viewStore.verifiedChats) { chat in
                            Button {
                                viewStore.send(.chatButtonTapped(chat))
                            } label: {
                                let alias = chat.alias ?? "no alias - swipe to edit"
                                Text(alias)
                                    .neumorphicButton()
                                    .swipeActions(allowsFullSwipe: false) {
                                        Button {
                                            viewStore.send(.editChatAliasTapped(chat.id))
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.clear)
                                    }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .padding(.horizontal, 10)
                    .refreshable {
                        viewStore.send(.reloadChats)
                    }
                }
                .toolbar {
                    if !viewStore.isZeroFundsAccount && viewStore.availableMessagesCount == 0 {
                        ToolbarItem(placement: .principal) {
                            HStack(spacing: 5) {
                                Text("Syncing")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Asset.Colors.fontPrimary.color)
                                ProgressView()
                                    .scaleEffect(x: 0.75, y: 0.75)
                            }
                            .frame(maxHeight: 20)
                        }
                    }

                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            viewStore.send(.fundsButtonTapped)
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .renderingMode(.template)
                                .tint(Asset.Colors.fontPrimary.color)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewStore.send(.debugButtonTapped)
                        } label: {
                            Image(systemName: "ladybug")
                                .renderingMode(.template)
                                .tint(Asset.Colors.fontPrimary.color)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if viewStore.isZeroFundsAccount {
                                scaleAnimation()
                            } else {
                                viewStore.send(.newChatButtonTapped)
                            }
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .renderingMode(.template)
                                .tint(Asset.Colors.fontPrimary.color)
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
                        case .verifyChat:
                            CaseLet(
                                /ChatsListReducer.SheetPath.State.verifyChat,
                                action: ChatsListReducer.SheetPath.Action.verifyChat,
                                then: VerifyChatView.init(store:)
                            )
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .onAppear { viewStore.send(.onAppear) }
                .onDisappear { viewStore.send(.onDisappear) }
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
    
    @ViewBuilder
    func zeroFundsView(_ viewStore: ViewStoreOf<ChatsListReducer>) -> some View {
        Button {
            viewStore.send(.fundsButtonTapped)
        } label: {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .renderingMode(.template)
                    .tint(.white)

                Text("""
                This account has zero funds at the moment. It's not possible to create a new chat or write any message in existing chats. Tap to \
                receive funds.
                """)
                    .font(.system(size: 13))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.blue)
                .opacity(0.6)
        }
        .padding(.horizontal, 20)
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
