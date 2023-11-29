//
//  TransactionsDebugStore.swift
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
import Foundation
import ZcashLightClientKit
import Messages

import Models
import Pasteboard
import SDKSynchronizer
import Utils
import WalletStorage

@Reducer
public struct TransactionsDebugReducer {
    public struct TransactionDebug: Equatable, Identifiable {
        public var id: String { state.id }
        public let state: TransactionState
        public let chatMessage: ChatProtocol.ChatMessage?
    }

    public struct State: Equatable {
        public var transactions: [TransactionDebug]
        public init(transactions: [TransactionDebug]) {
            self.transactions = transactions
        }
    }

    public enum Action: Equatable {
        case onAppear
        case transactionsLoaded([TransactionDebug])
    }

    public init() {}

    @Dependency(\.sdkSynchronizer) var synchronizer
    @Dependency(\.chatProtocol) var chatProtocol

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let transactions = try await synchronizer.getAllTransactions()
                    var debug: [TransactionDebug] = []

                    for transaction in transactions {
                        var chatProtocolMessage: ChatProtocol.ChatMessage?
                        for memo in (transaction.memos ?? []) {
                            do {
                                let memoBytes = try memo.asMemoBytes().bytes
                                chatProtocolMessage = try chatProtocol.decode(memoBytes)
                            } catch {
                                continue
                            }
                        }
                        debug.append(TransactionDebug(state: transaction, chatMessage: chatProtocolMessage))
                    }
                    
                    await send(.transactionsLoaded(debug))
                }

            case .transactionsLoaded(let transactions):
                state.transactions = transactions
                return .none
            }
        }
    }
}
