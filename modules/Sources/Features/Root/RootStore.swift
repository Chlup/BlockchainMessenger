//
//  RootStore.swift
//
//
//  Created by Lukáš Korba on 20.11.2023.
//

import ComposableArchitecture
import ZcashLightClientKit

import ChatsList
import CreateAccount
import RestoreAccount

import DatabaseFiles
import MnemonicClient
import Models
import SDKSynchronizer
import WalletStorage
import ZcashSDKEnvironment

public struct RootReducer: Reducer {
    enum CancelId { case timer }

    let zcashNetwork: ZcashNetwork

    public struct State: Equatable {
        public var appInitializationState: InitializationState = .uninitialized
        var path = StackState<Path.State>()
        public var storedWallet: StoredWallet?

        public init(path: StackState<Path.State> = StackState<Path.State>()) {
            self.path = path
        }
    }
    
    public enum Action: Equatable {
        public enum AppDelegateAction: Equatable {
            case didFinishLaunching
            case didEnterBackground
            case willEnterForeground
        }
        
        case appDelegate(AppDelegateAction)
        case checkBackupPhraseValidation
        case checkWalletInitialization
        case createAccount
        case initializationSuccessfullyDone(UnifiedAddress?)
        case initializeSDK(WalletInitMode)
        case path(StackAction<Path.State, Path.Action>)
        case respondToWalletInitializationState(InitializationState)
        case restoreAccount
    }
    
    public struct Path: Reducer {
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
        
        public init() {}
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.chatsList, action: /Action.chatsList) {
                ChatsListReducer()
            }
            Scope(state: /State.createAccount, action: /Action.createAccount) {
                CreateAccountReducer()
            }
            Scope(state: /State.restoreAccount, action: /Action.restoreAccount) {
                RestoreAccountReducer()
            }
        }
    }
    
    public init(zcashNetwork: ZcashNetwork) {
        self.zcashNetwork = zcashNetwork
    }

    @Dependency(\.databaseFiles) var databaseFiles
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.mnemonic) var mnemonic
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.zcashSDKEnvironment) var zcashSDKEnvironment

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appDelegate(.didFinishLaunching):
                return .run { send in
                    try await mainQueue.sleep(for: .seconds(0.02))
                    await send(.checkWalletInitialization)
                }
                
            case .appDelegate:
                return .none
            
            case .checkBackupPhraseValidation:
                guard let _ = state.storedWallet else {
                    state.appInitializationState = .failed
                    //state.alert = AlertState.cantLoadSeedPhrase()
                    return .none
                }

                state.appInitializationState = .initialized
                state.path.append(.chatsList(ChatsListReducer.State()))
                return .none

            case .checkWalletInitialization:
                let walletState = RootReducer.walletInitializationState(
                    databaseFiles: databaseFiles,
                    walletStorage: walletStorage,
                    zcashNetwork: zcashNetwork
                )
                return Effect.send(.respondToWalletInitializationState(walletState))

            case .createAccount:
                do {
                    // get the random english mnemonic
                    let newRandomPhrase = try mnemonic.randomMnemonic()
                    let birthday = zcashSDKEnvironment.latestCheckpoint(zcashNetwork)
                    
                    // store the wallet to the keychain
                    try walletStorage.importWallet(newRandomPhrase, birthday, .english, true)
                    
                    state.path.append(.createAccount(CreateAccountReducer.State()))
                } catch {
//                    state.alert = AlertState.cantCreateNewWallet(error.toZcashError())
                }
                return .none

            case .initializationSuccessfullyDone(let uAddress):
                return .none

            case .initializeSDK(let walletMode):
                do {
                    state.storedWallet = try walletStorage.exportWallet()

                    guard let storedWallet = state.storedWallet else {
                        state.appInitializationState = .failed
                        //state.alert = AlertState.cantLoadSeedPhrase()
                        return .none
                    }

                    let birthday = state.storedWallet?.birthday?.value() ?? zcashSDKEnvironment.latestCheckpoint(zcashNetwork)

                    try mnemonic.isValid(storedWallet.seedPhrase.value())
                    let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())
                    
                    return .run { send in
                        do {
                            try await sdkSynchronizer.prepareWith(seedBytes, birthday, walletMode)
                            try await sdkSynchronizer.start(false)

                            let uAddress = try? await sdkSynchronizer.getUnifiedAddress(0)
                            await send(.initializationSuccessfullyDone(uAddress))
                        } catch {
                            //await send(.initializationFailed(error.toZcashError()))
                        }
                    }
                } catch {
                    //return Effect.send(.initializationFailed(error.toZcashError()))
                    return .none
                }
            
            case .path(.element(id: _, action: .createAccount(.confirmationButtonTapped))):
                state.path.append(.chatsList(ChatsListReducer.State()))
                return .none
                
            case .path:
                return .none

            case .respondToWalletInitializationState(let walletState):
                switch walletState {
                case .failed:
                    state.appInitializationState = .failed
                    //state.alert = AlertState.walletStateFailed(walletState)
                    return .none
                case .keysMissing:
                    state.appInitializationState = .keysMissing
                    //state.alert = AlertState.walletStateFailed(walletState)
                    return .none
                case .initialized, .filesMissing:
                    if walletState == .filesMissing {
                        state.appInitializationState = .filesMissing
                    }
                    return .concatenate(
                        Effect.send(.initializeSDK(.existingWallet)),
                        Effect.send(.checkBackupPhraseValidation)
                    )
                case .uninitialized:
                    state.appInitializationState = .uninitialized
                    return .none
                }
                
            case .restoreAccount:
                state.path.append(.restoreAccount(RestoreAccountReducer.State()))
                //state.path = StackState([.restoreAccount(RestoreAccountReducer.State())])
                return .none
            }
        }
        .forEach(\.path, action: /Action.path) {
            Path()
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
