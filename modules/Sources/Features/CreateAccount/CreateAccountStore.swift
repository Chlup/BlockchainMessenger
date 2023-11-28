//
//  CreateAccountStore.swift
//
//
//  Created by Lukáš Korba on 20.11.2023.
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

import Models
import Utils
import WalletStorage

@Reducer
public struct CreateAccountReducer {
    public struct State: Equatable {
        public var birthday: Birthday?
        public var birthdayValue: String?
        public var phrase: RecoveryPhrase?

        public init() {}
    }
    
    public enum Action: Equatable {
        case onAppear
        case confirmationButtonTapped
    }
      
    public init() {}
    
    @Dependency(\.walletStorage) var walletStorage
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                do {
                    let storedWallet = try walletStorage.exportWallet()
                    state.birthday = storedWallet.birthday
                    if let value = state.birthday?.value() {
                        state.birthdayValue = "\(String(describing: value))"
                    }
                    let seedWords = storedWallet.seedPhrase.value().split(separator: " ").map { RedactableString(String($0)) }
                    state.phrase = RecoveryPhrase(words: seedWords)
                } catch {
                    //state.alert = AlertState.storedWalletFailure(error.toZcashError())
                }
                return .none
                
            case .confirmationButtonTapped:
                return .none
            }
        }
    }
}
