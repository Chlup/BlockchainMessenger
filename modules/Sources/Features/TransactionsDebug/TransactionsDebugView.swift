//
//  TransactionsDebugView.swift
//
//
//  Created by Michal Fousek on 29.11.2023.
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

import Messages
import Utils

public struct TransactionsDebugView: View {
    let store: StoreOf<TransactionsDebugReducer>

    public init(store: StoreOf<TransactionsDebugReducer>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            List {
                ForEach(viewStore.transactions) { transaction in
                    let foreground: Color = transaction.chatMessage == nil ?
                        .red : (transaction.state.isSentTransaction ? .blue : .green)

                    VStack(alignment: .leading) {
                        Text("\(transaction.state.title) - \(transaction.state.dateString ?? "-")")

                        if let message = transaction.chatMessage {
                            let date = Date(timeIntervalSince1970: TimeInterval(message.timestmap)).asHumanReadable()
                            Text("Msg date: \(date)")
                            switch message.content {
                            case .initialisation:
                                Text("Msg: Create chat")
                            case .text(let text):
                                Text("Msg:\n\(text)")
                            }
                        }
                    }
                    .foregroundColor(foreground)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.visible)
                }
            }
            .listStyle(.plain)
            .onAppear {
                viewStore.send(.onAppear)
            }
            .applyScreenBackground()
        }
    }
}

#Preview {
    TransactionsDebugView(
        store:
            Store(
                initialState: TransactionsDebugReducer.State(transactions: [])
            ) {
                TransactionsDebugReducer()
                ._printChanges()
            }
    )
}
