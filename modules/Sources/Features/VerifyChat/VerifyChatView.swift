//
//  VerifyChatView.swift
//
//
//  Created by Lukáš Korba on 07.12.2023.
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

public struct VerifyChatView: View {
    let store: StoreOf<VerifyChatReducer>
    
    public init(store: StoreOf<VerifyChatReducer>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading) {
                Text("Enter the address of a sender you expect messages from")
                TextEditor(text: viewStore.$uAddress)
                    .frame(height: 150)
                    .padding(1)
                    .background {
                        Color.black
                    }
                    .padding(.bottom, 20)
                
                TextField("verification code", text: viewStore.$verificationText)
                    .padding(5)
                    .background {
                        Rectangle()
                            .stroke()
                    }
                    .padding(.bottom, 20)
                
                TextField("alias", text: viewStore.$alias)
                    .padding(5)
                    .background {
                        Rectangle()
                            .stroke()
                    }
                    .padding(.bottom, 20)

                Button {
                    viewStore.send(.verifyButtonTapped)
                } label: {
                    HStack(spacing: 10) {
                        Text("Verify")

                        if viewStore.isVerifying {
                            ProgressView()
                        }
                    }
                }
                .disabled(!viewStore.isValidForm)
                
                Spacer()
            }
            .padding()
            .navigationBarBackButtonHidden()
        }
        .applyScreenBackground()
        .alert(
            store: self.store.scope(state: \.$alert, action: \.alert)
        )
    }
}

#Preview {
    NavigationStack {
        VerifyChatView(
            store:
                Store(
                    initialState: VerifyChatReducer.State()
                ) {
                    VerifyChatReducer(networkType: ZcashNetworkBuilder.network(for: .testnet).networkType)
                        ._printChanges()
                }
        )
        .preferredColorScheme(.dark)
    }
}
