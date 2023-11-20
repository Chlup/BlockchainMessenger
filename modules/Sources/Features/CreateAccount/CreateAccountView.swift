//
//  CreateAccountView.swift
//
//
//  Created by Lukáš Korba on 20.11.2023.
//

import SwiftUI
import ComposableArchitecture

public struct CreateAccountView: View {
    let store: StoreOf<CreateAccountReducer>
    
    public init(store: StoreOf<CreateAccountReducer>) {
        self.store = store
    }
    
    public var body: some View {
        Text("CreateAccountView")
    }
}

#Preview {
    CreateAccountView(
        store:
            Store(
                initialState: CreateAccountReducer.State()
            ) {
                CreateAccountReducer()
                    ._printChanges()
            }
    )
}
