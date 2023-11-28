//
//  ChatDetailView.swift
//
//
//  Created by Lukáš Korba on 25.11.2023.
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
                Section {
                    HStack {
                        Spacer()
                        Text("Today")
                            .font(.system(size: 14))
                            .foregroundStyle(Asset.Colors.fontPrimary.color)
                        Spacer()
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
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
                                .foregroundColor(
                                    message.isSent 
                                    ? .blue//Asset.Colors.ChatDetail.sent2.color // .blue
                                    : Asset.Colors.ChatDetail.received.color
                                )
                                .shadow(
                                    color: .black.opacity(0.7),
                                    radius: 4,
                                    x: 4,
                                    y: 4
                                )
                                .shadow(
                                    color: .white.opacity(0.15),
                                    radius: 4,
                                    x: -4,
                                    y: -4
                                )
                                .overlay(
                                    UnevenRoundedRectangle(
                                        cornerRadii: .init(
                                            topLeading: 15,
                                            bottomLeading: message.isSent ? 15 : 0,
                                            bottomTrailing: message.isSent ? 0 : 15,
                                            topTrailing: 15
                                        )
                                    )
                                    .inset(by: 0.5)
                                    .stroke(
                                        LinearGradient(
                                            stops: [
                                                Gradient.Stop(
                                                    color: .white.opacity(0.35),
                                                    location: 0.0
                                                ),
                                                Gradient.Stop(
                                                    color: .black.opacity(0.7),
                                                    location: 1.0
                                                ),
                                            ],
                                            startPoint: UnitPoint(x: 0.49, y: 0.01),
                                            endPoint: UnitPoint(x: 0.51, y: 0.99)
                                        ),
                                        lineWidth: 1
                                    )
                                )
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
