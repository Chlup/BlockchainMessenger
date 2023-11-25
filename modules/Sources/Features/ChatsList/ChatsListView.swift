//
//  ChatsListView.swift
//
//
//  Created by Lukáš Korba on 23.11.2023.
//

import ComposableArchitecture
import SwiftUI
import ZcashLightClientKit

import NewChat
import Messages
import Utils

public struct ChatsListView: View {
    let store: StoreOf<ChatsListReducer>
    
    public init(store: StoreOf<ChatsListReducer>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                if !viewStore.incomingChats.isEmpty {
                    HStack {
                        Text("Incoming chats")
                        
                        Text("\(viewStore.incomingChats.count)")
                            .padding(7)
                            .background {
                                Circle()
                                    .foregroundStyle(.red)
                            }
                    }
                    .foregroundStyle(.white)
                    .frame(height: 25)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background {
                        Capsule()
                            .stroke()
                            .foregroundStyle(.white)
                    }
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

                if !viewStore.incomingChats.isEmpty {
                    Text("Verified chats")
                        .padding(.top)
                }

                ForEach(viewStore.verifiedChats) { chat in
                    if let alias = chat.alias {
                        Button {
                            viewStore.send(.chatButtonTapped(chat.chatID))
                        } label: {
                            Text(alias)
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .frame(height: 25)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background {
                                    Capsule()
                                        .foregroundStyle(.blue)
                                }
                        }
                    }
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewStore.send(.newChatButtonTapped)
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .navigationBarBackButtonHidden()
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
