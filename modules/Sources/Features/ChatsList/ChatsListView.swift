//
//  ChatsListView.swift
//
//
//  Created by Lukáš Korba on 23.11.2023.
//

import ComposableArchitecture
import SwiftUI
import ZcashLightClientKit

import ChatDetail
import Generated
import NewChat
import Messages
import Utils

public struct ChatsListView: View {
    let store: StoreOf<ChatsListReducer>
    
    public init(store: StoreOf<ChatsListReducer>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStackStore(
            store.scope(state: \.path, action: { .path($0) })
        ) {
            WithViewStore(self.store, observe: { $0 }) { viewStore in
                ScrollView {
                    if !viewStore.incomingChats.isEmpty {
                        HStack {
                            Text("Chats")
                                .font(.system(size: 36))
                                .fontWeight(.semibold)
                                .foregroundStyle(Asset.Colors.fontPrimary.color)
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                        
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
                        .padding(.horizontal, 30)
                        .padding(.bottom, 15)
                    }
                    
                    //                ForEach(viewStore.incomingChats) { chat in
                    //                    Text("\(Date(timeIntervalSince1970: Double(chat.timestamp)).asHumanReadable())")
                    //                        .font(.system(size: 10))
                    //                        .foregroundStyle(.white)
                    //                        .frame(height: 25)
                    //                        .frame(maxWidth: .infinity)
                    //                        .padding()
                    //                        .background {
                    //                            Capsule()
                    //                                .foregroundStyle(.black)
                    //                        }
                    //                }
                    
                    ForEach(viewStore.verifiedChats) { chat in
                        if let alias = chat.alias {
                            Button {
                                viewStore.send(.chatButtonTapped(chat.chatID))
                            } label: {
                                Text(alias)
                                    .neumorphicButton()
                            }
                            .padding(.horizontal, 30)
                            .padding(.bottom, 15)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewStore.send(.newChatButtonTapped)
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .renderingMode(.template)
                                .tint(Asset.Colors.fontPrimary.color)
                                .neumorphicButton(
                                    // style: .blue
                                    // Asset.Colors.ChatDetail.sent2.color
                                )
                                .tint(.white)
                        }
                    }
                }
                .sheet(
                    store: self.store.scope(
                        state: \.$newChat,
                        action: { .newChat($0) }
                    )
                ) { store in
                    NewChatView(store: store)
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
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChatsListView(
            store:
                Store(
                    initialState: ChatsListReducer.State()
                ) {
                    ChatsListReducer(networkType: ZcashNetworkBuilder.network(for: .testnet).networkType)
                        ._printChanges()
                }
        )
    }
    .preferredColorScheme(.dark)
}
