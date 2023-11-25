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
            store.scope(state: \.$path, action: { .path($0) })
        ) { store in
            SwitchStore(store) {
                switch $0 {
                case .chatsDetail:
                    CaseLet(
                        /RootReducer.Path.State.chatsDetail,
                         action: RootReducer.Path.Action.chatsDetail,
                         then: ChatDetailView.init(store:)
                    )
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
//        WithViewStore(self.store, observe: { $0 }) { viewStore in
//            if let state = viewStore.path.optional {
//                switch state {
//                case .chatsDetail:
//                    CaseLet(
//                        /RootReducer.Path.State.chatsDetail,
//                         action: RootReducer.Path.Action.chatsDetail,
//                         then: ChatDetailView.init(store:)
//                    )
//                case .chatsList:
//                    CaseLet(
//                        /RootReducer.Path.State.chatsList,
//                         action: RootReducer.Path.Action.chatsList,
//                         then: ChatsListView.init(store:)
//                    )
//                case .createAccount:
//                    CaseLet(
//                        /RootReducer.Path.State.createAccount,
//                         action: RootReducer.Path.Action.createAccount,
//                         then: CreateAccountView.init(store:)
//                    )
//                case .restoreAccount:
//                    CaseLet(
//                        /RootReducer.Path.State.restoreAccount,
//                         action: RootReducer.Path.Action.restoreAccount,
//                         then: RestoreAccountView.init(store:)
//                    )
//                }
//            }
//        }
        
//        NavigationStackStore(
//            store.scope(state: \.path, action: { .path($0) })
//        ) {
//            WithViewStore(self.store, observe: \.isLoading) { viewStore in
//                VStack(spacing: 40) {
//                    if viewStore.state {
//                        Text("Loading...")
//                    } else {
//                        Button("create new account") {
//                            store.send(.createAccount)
//                        }
//                        Button("restore account") {
//                            store.send(.restoreAccount)
//                        }
//                    }
//                    //                NavigationLink(
//                    //                    state: RootReducer.Path.State.createAccount(CreateAccountReducer.State())
//                    //                ) {
//                    //                    Text("create new account")
//                    //                }
//                    //                NavigationLink(
//                    //                    state: RootReducer.Path.State.restoreAccount(RestoreAccountReducer.State())
//                    //                ) {
//                    //                    Text("restore account")
//                    //                }
//                }
//            }
//        } destination: { state in
//            switch state {
//            case .chatsDetail:
//                CaseLet(
//                    /RootReducer.Path.State.chatsDetail,
//                     action: RootReducer.Path.Action.chatsDetail,
//                     then: ChatDetailView.init(store:)
//                )
//            case .chatsList:
//                CaseLet(
//                    /RootReducer.Path.State.chatsList,
//                     action: RootReducer.Path.Action.chatsList,
//                     then: ChatsListView.init(store:)
//                )
//            case .createAccount:
//                CaseLet(
//                    /RootReducer.Path.State.createAccount,
//                     action: RootReducer.Path.Action.createAccount,
//                     then: CreateAccountView.init(store:)
//                )
//            case .restoreAccount:
//                CaseLet(
//                    /RootReducer.Path.State.restoreAccount,
//                     action: RootReducer.Path.Action.restoreAccount,
//                     then: RestoreAccountView.init(store:)
//                )
//            }
//        }
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
