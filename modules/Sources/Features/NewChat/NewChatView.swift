//
//  NewChatView.swift
//
//
//  Created by Lukáš Korba on 23.11.2023.
//
//  MIT License
//
//  Copyright (c) 2023 Mugeaters
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import ComposableArchitecture
import SwiftUI
import ZcashLightClientKit

import Utils

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
        .applyScreenBackground()
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
