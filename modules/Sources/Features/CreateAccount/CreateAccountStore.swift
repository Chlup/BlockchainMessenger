//
//  CreateAccountStore.swift
//
//
//  Created by Lukáš Korba on 20.11.2023.
//

import ComposableArchitecture

import Models
import Utils
import WalletStorage

public struct CreateAccountReducer: Reducer {
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
