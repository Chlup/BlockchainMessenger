//
//  NewChatView.swift
//
//
//  Created by Lukáš Korba on 23.11.2023.
//

import ComposableArchitecture
import SwiftUI
import ZcashLightClientKit

public struct NewChatView: View {
    let store: StoreOf<NewChatReducer>
    
    public init(store: StoreOf<NewChatReducer>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading) {
                Text("Enter the address of a recipient")
                TextEditor(text: viewStore.$uAddress)
                    .frame(height: 150)
                    .padding(1)
                    .background {
                        Color.black
                    }
                    .padding(.bottom, 10)
                
                TextField("alias", text: viewStore.$alias)
                    .padding(5)
                    .background {
                        Rectangle()
                            .stroke()
                            
                    }
                    .padding(.bottom, 10)

                Button("Start chat") {
                    viewStore.send(.startChatButtonTapped)
                }
                .disabled(!viewStore.isValidForm)
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "square.and.pencil")
                }
            }
            .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    NavigationStack {
        NewChatView(
            store:
                Store(
                    initialState: NewChatReducer.State()
                ) {
                    NewChatReducer(networkType: ZcashNetworkBuilder.network(for: .testnet).networkType)
                        ._printChanges()
                }
        )
        .preferredColorScheme(.dark)
    }
}
