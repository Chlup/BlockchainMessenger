//
//  RootView.swift
//  
//
//  Created by Lukáš Korba on 20.11.2023.
//

import SwiftUI
import ComposableArchitecture
import CreateAccount
import RestoreAccount

public struct RootView: View {
    let store: StoreOf<RootReducer>
    
    public init(store: StoreOf<RootReducer>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStackStore(
            store.scope(state: \.path, action: { .path($0) })
        ) {
            VStack(spacing: 40) {
                NavigationLink(
                    state: RootReducer.Path.State.createAccount(CreateAccountReducer.State())
                ) {
                    Text("create new account")
                }
                NavigationLink(
                    state: RootReducer.Path.State.restoreAccount(RestoreAccountReducer.State())
                ) {
                    Text("restore account")
                }
            }
        } destination: { state in
            switch state {
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
    }
}

#Preview {
    RootView(
        store:
            Store(
                initialState: RootReducer.State()
            ) {
                RootReducer()
                    ._printChanges()
            }
    )
}
