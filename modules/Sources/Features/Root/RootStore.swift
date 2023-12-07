//
//  RootStore.swift
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

import ChatsList
import CreateAccount
import RestoreAccount

import DatabaseFiles
import Generated
import Messages
import MnemonicClient
import Models
import WalletStorage
import ZcashSDKEnvironment

@Reducer
public struct RootReducer {
    enum CancelId { case timer }

    let zcashNetwork: ZcashNetwork

    public struct State: Equatable {
        public var appInitializationState: InitializationState = .uninitialized
        var isLoading = true
        @PresentationState public var path: Path.State?
        public var storedWallet: StoredWallet?

        public init(isLoading: Bool = true) {
            self.isLoading = isLoading
        }
    }
    
    public enum Action: Equatable {
        public enum AppDelegateAction: Equatable {
            case didFinishLaunching
            case didEnterBackground
            case willEnterForeground
        }
        
        case appDelegate(AppDelegateAction)
        case createAccount
        case initiateAccount
        case initializationFailed
        case initializationSucceeded
        case path(PresentationAction<Path.Action>)
        case restoreAccount
        case retryStart
        case synchronizerStartFailed(ZcashError)
    }
    
    public struct Path: Reducer {
        let networkType: NetworkType

        public enum State: Equatable {
            case chatsList(ChatsListReducer.State)
            case createAccount(CreateAccountReducer.State)
            case restoreAccount(RestoreAccountReducer.State)
        }
        
        public enum Action: Equatable {
            case chatsList(ChatsListReducer.Action)
            case createAccount(CreateAccountReducer.Action)
            case restoreAccount(RestoreAccountReducer.Action)
        }
        
        public init(networkType: NetworkType) {
            self.networkType = networkType
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.chatsList, action: /Action.chatsList) {
                ChatsListReducer(networkType: networkType)
            }
            Scope(state: /State.createAccount, action: /Action.createAccount) {
                CreateAccountReducer()
            }
            Scope(state: /State.restoreAccount, action: /Action.restoreAccount) {
                RestoreAccountReducer(networkType: networkType)
            }
        }
    }
    
    public init(zcashNetwork: ZcashNetwork) {
        self.zcashNetwork = zcashNetwork
    }

    @Dependency(\.databaseFiles) var databaseFiles
    @Dependency(\.messages) var messages
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.sdkSynchronizer) var synchronizer
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appDelegate(.didFinishLaunching):
                return .run { send in
                    try await mainQueue.sleep(for: .seconds(0.02))
                    await send(.initiateAccount)
                }
                
            case .appDelegate(.didEnterBackground):
                synchronizer.stop()
                return .none
                
            case .appDelegate(.willEnterForeground):
                return .run { send in
                    try await mainQueue.sleep(for: .seconds(1))
                    await send(.retryStart)
                }
                
            case .appDelegate:
                return .none
        
            case .createAccount:
                do {
                    // get the random english mnemonic
                    let newRandomPhrase = try mnemonic.randomMnemonic()
                    let birthday = zcashSDKEnvironment.latestCheckpoint(zcashNetwork)
                    
                    // store the wallet to the keychain
                    try walletStorage.importWallet(newRandomPhrase, birthday, .english, true)
                    
                    state.path = .createAccount(CreateAccountReducer.State())
                } catch {
                    // TODO: some error handling
                }
                return .none
                
            case .initiateAccount:
                let walletState = RootReducer.walletInitializationState(
                    databaseFiles: databaseFiles,
                    walletStorage: walletStorage,
                    zcashNetwork: zcashNetwork
                )
                state.appInitializationState = walletState
                if  walletState == .initialized || walletState == .filesMissing {
                    let walletMode = WalletInitMode.existingWallet
                    do {
                        state.storedWallet = try walletStorage.exportWallet()

                        guard let storedWallet = state.storedWallet else {
                            state.appInitializationState = .failed
                            return .send(.initializationFailed)
                        }

                        let birthday = state.storedWallet?.birthday?.value() ?? zcashSDKEnvironment.latestCheckpoint(zcashNetwork)

                        try mnemonic.isValid(storedWallet.seedPhrase.value())
                        let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())
                        
                        return .run { send in
                            do {
                                // TODO: This must be somehow handled and communicated to user that something went seriously wrong.
                                try await messages.initialize(network: zcashNetwork.networkType)
                                try await messages.start(with: seedBytes, birthday: birthday, walletMode: walletMode)
                                
                                try await mainQueue.sleep(for: .seconds(1.5))
                                
                                await send(.initializationSucceeded)
                            } catch {
                                await send(.initializationFailed)
                            }
                        }
                    } catch {
                        return .send(.initializationFailed)
                    }
                }
                return .send(.initializationFailed)

            case .initializationFailed:
                // TODO: some error handling
                state.isLoading = false
                return .none

            case .initializationSucceeded:
                state.appInitializationState = .initialized
                state.path = .chatsList(ChatsListReducer.State(synchronizerStatusSnapshot: SyncStatusSnapshot()))
                return .none

            case .path(.presented(.createAccount(.confirmationButtonTapped))):
                return .send(.initiateAccount)

            case .path(.presented(.restoreAccount(.successfullyRecovered))):
                // TODO: Here I want to pass .restore and act accordingly in the UI
                return .send(.initiateAccount)
                
            case .path(.presented(.restoreAccount(.backButtonTapped))):
                state.path = nil
                return .none
                
            case .path(.presented(.chatsList(.sheetPath(.presented(.funds(.wipeSucceeded)))))):
                state.path = nil
                state.isLoading = true
                return .send(.initiateAccount)
                
            case .path:
                return .none
                
            case .restoreAccount:
                state.path = .restoreAccount(RestoreAccountReducer.State())
                return .none
                
            case .retryStart:
                // Try the start only if the synchronizer has been already prepared
                guard synchronizer.latestState().syncStatus.isPrepared else {
                    return .none
                }
                return .run { send in
                    do {
                        try await synchronizer.start(true)
                    } catch {
                        await send(.synchronizerStartFailed(error.toZcashError()))
                    }
                }

            case .synchronizerStartFailed:
                return .none
            }
        }
        .ifLet(\.$path, action: \.path) {
            Path(networkType: zcashNetwork.networkType)
        }
    }
}

extension RootReducer {
    public static func walletInitializationState(
        databaseFiles: DatabaseFilesClient,
        walletStorage: WalletStorageClient,
        zcashNetwork: ZcashNetwork
    ) -> InitializationState {
        var keysPresent = false
        do {
            keysPresent = try walletStorage.areKeysPresent()
            let databaseFilesPresent = databaseFiles.areDbFilesPresentFor(
                zcashNetwork
            )
            
            switch (keysPresent, databaseFilesPresent) {
            case (false, false):
                return .uninitialized
            case (false, true):
                return .keysMissing
            case (true, false):
                return .filesMissing
            case (true, true):
                return .initialized
            }
        } catch WalletStorage.WalletStorageError.uninitializedWallet {
            if databaseFiles.areDbFilesPresentFor(zcashNetwork) {
                return .keysMissing
            }
        } catch {
            return .failed
        }
        
        return .uninitialized
    }
}
