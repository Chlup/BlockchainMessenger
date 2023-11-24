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

public struct ChatsListView: View {
    let store: StoreOf<ChatsListReducer>
    
    public init(store: StoreOf<ChatsListReducer>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                
            }
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
}
