//
//  ChatsListView.swift
//
//
//  Created by Lukáš Korba on 23.11.2023.
//

import ComposableArchitecture
import SwiftUI

public struct ChatsListView: View {
    let store: StoreOf<ChatsListReducer>
    
    public init(store: StoreOf<ChatsListReducer>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            Text("ChatsListView")
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    ChatsListView(
        store:
            Store(
                initialState: ChatsListReducer.State()
            ) {
                ChatsListReducer()
                    ._printChanges()
            }
    )
}
