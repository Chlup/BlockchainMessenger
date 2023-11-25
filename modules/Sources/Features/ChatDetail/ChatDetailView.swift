//
//  ChatDetailView.swift
//
//
//  Created by Lukáš Korba on 25.11.2023.
//

import ComposableArchitecture
import SwiftUI
import ZcashLightClientKit

import Generated
import Messages
import Utils

public struct ChatDetailView: View {
    let store: StoreOf<ChatDetailReducer>
    
    public init(store: StoreOf<ChatDetailReducer>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            List {
                ForEach(viewStore.messages) { message in
                    HStack {
                        if message.isSent {
                            Spacer()
                        }
                        
                        Text(message.text)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .padding()
                            .background {
                                UnevenRoundedRectangle(
                                    cornerRadii: .init(
                                        topLeading: 15,
                                        bottomLeading: message.isSent ? 15 : 0,
                                        bottomTrailing: message.isSent ? 0 : 15,
                                        topTrailing: 15
                                    )
                                )
                                .foregroundColor(message.isSent ? .blue : .gray)
                            }
                        
                        if !message.isSent {
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
        }
        .applyScreenBackground()
    }
}

#Preview {
    NavigationStack {
        ChatDetailView(
            store:
                Store(
                    initialState: ChatDetailReducer.State(chatId: 1)
                ) {
                    ChatDetailReducer(networkType: ZcashNetworkBuilder.network(for: .testnet).networkType)
                        ._printChanges()
                }
        )
    }
    .preferredColorScheme(.dark)
}
