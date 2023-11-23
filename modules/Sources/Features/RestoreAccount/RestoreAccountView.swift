//
//  RestoreAccountView.swift
//
//
//  Created by Lukáš Korba on 20.11.2023.
//

import ComposableArchitecture
import SwiftUI

public struct RestoreAccountView: View {
    let store: StoreOf<RestoreAccountReducer>
    
    public init(store: StoreOf<RestoreAccountReducer>) {
        self.store = store
    }
    
    public var body: some View {
        Text("RestoreAccountView")
    }
}


#Preview {
    RestoreAccountView(
        store:
            Store(
                initialState: RestoreAccountReducer.State()
            ) {
                RestoreAccountReducer()
                    ._printChanges()
            }
    )
}
