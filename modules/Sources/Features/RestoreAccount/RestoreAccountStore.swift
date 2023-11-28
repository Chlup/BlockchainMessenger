//
//  RestoreAccountStore.swift
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
import ZcashLightClientKit

import Logger
import MnemonicClient
import Utils
import WalletStorage

@Reducer
public struct RestoreAccountReducer {
    let networkType: NetworkType

    public struct State: Equatable {
        @BindingState public var importedData = ""
        
        public var importedSeedPhrase: RedactableString {
            importedData.split(separator: " ").dropFirst().joined(separator: " ").redacted
        }
        
        public var birthdayHeightValue: RedactableBlockHeight? {
            if let bdAsString = importedData.split(separator: " ").first, let bdAsInt = Int(bdAsString) {
                return RedactableBlockHeight(BlockHeight(bdAsInt))
            }
            
            return nil
        }
        
        public init() {}
    }
    
    public enum Action: Equatable, BindableAction {
        case backButtonTapped
        case binding(BindingAction<State>)
        case restoreButtonTaped
        case successfullyRecovered
    }
        
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }

    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.logger) var logger

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .none

            case .binding:
                return .none
                
            case .restoreButtonTaped:
                do {
                    logger.debug("seed: \(state.importedSeedPhrase.data)")
                    logger.debug("BD: \(state.birthdayHeightValue)")

                    try mnemonic.isValid(state.importedSeedPhrase.data)
                    let birthday = state.birthdayHeightValue ?? RedactableBlockHeight(networkType == .testnet ? 280_000 : 419_200)
                    try walletStorage.importWallet(state.importedSeedPhrase.data, birthday.data, .english, false)
                    state.importedData = ""
                    
                    return .send(.successfullyRecovered)
                } catch {
                    // TODO: error handling
                }
                return .none
                
            case .successfullyRecovered:
                return .none
            }
        }
    }
}
