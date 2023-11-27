//
//  RootView.swift
//  
//
//  Created by Lukáš Korba on 20.11.2023.
//

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
            HStack(spacing: 10) {
                Text("Initializing")
                    .foregroundStyle(Asset.Colors.fontPrimary.color)
                ProgressView()
            }
            .applyScreenBackground()
        }
    }
}

#Preview {
    RootView(
        store:
            Store(
                initialState: RootReducer.State()
            ) {
                RootReducer(zcashNetwork: ZcashNetworkBuilder.network(for: .testnet))
                    ._printChanges()
            }
    )
}
