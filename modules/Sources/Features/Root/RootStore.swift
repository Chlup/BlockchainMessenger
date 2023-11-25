//
//  RootStore.swift
//
//
//  Created by Lukáš Korba on 20.11.2023.
//

import ComposableArchitecture
import ZcashLightClientKit

import ChatDetail
import ChatsList
import CreateAccount
import RestoreAccount

import DatabaseFiles
import Messages
import MnemonicClient
import Models
import WalletStorage
import ZcashSDKEnvironment
import Generated

public struct RootReducer: Reducer {
    enum CancelId { case timer }

    let zcashNetwork: ZcashNetwork

    public struct State: Equatable {
        public var appInitializationState: InitializationState = .uninitialized
        var isLoading = true
        @PresentationState public var path: Path.State?
        //var path = StackState<Path.State>()
        public var storedWallet: StoredWallet?

        public init(
            //path: StackState<Path.State> = StackState<Path.State>()
        ) {
            //self.path = path
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
        //case path(StackAction<Path.State, Path.Action>)
        case restoreAccount
    }
    
    public struct Path: Reducer {
        let networkType: NetworkType

        public enum State: Equatable {
            case chatsDetail(ChatDetailReducer.State)
            case chatsList(ChatsListReducer.State)
            case createAccount(CreateAccountReducer.State)
            case restoreAccount(RestoreAccountReducer.State)
        }
        
        public enum Action: Equatable {
            case chatsDetail(ChatDetailReducer.Action)
            case chatsList(ChatsListReducer.Action)
            case createAccount(CreateAccountReducer.Action)
            case restoreAccount(RestoreAccountReducer.Action)
        }
        
        public init(networkType: NetworkType) {
            self.networkType = networkType
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.chatsDetail, action: /Action.chatsDetail) {
                ChatDetailReducer(networkType: networkType)
            }
            Scope(state: /State.chatsList, action: /Action.chatsList) {
                ChatsListReducer(networkType: networkType)
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
    @Dependency(\.messages) var messages
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.mnemonic) var mnemonic
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
                
            case .appDelegate:
                return .none
            
            case .createAccount:
                do {
                    // get the random english mnemonic
                    let newRandomPhrase = try mnemonic.randomMnemonic()
                    let birthday = zcashSDKEnvironment.latestCheckpoint(zcashNetwork)
                    
                    // store the wallet to the keychain
                    try walletStorage.importWallet(newRandomPhrase, birthday, .english, true)
                    
//                    state.path.append(.createAccount(CreateAccountReducer.State()))
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
//                state.path.append(.chatsList(ChatsListReducer.State()))
                state.path = .chatsList(ChatsListReducer.State())
                return .none

//            case .path(.element(id: _, action: .chatsList(.chatButtonTapped(let chatId)))):
//                state.path.append(.chatsDetail(ChatDetailReducer.State(chatId: chatId)))
//                return .none
//
//            case .path(.element(id: _, action: .createAccount(.confirmationButtonTapped))):
//                state.path.append(.chatsList(ChatsListReducer.State()))
//                return .none
//                
            case .path:
                return .none
                
            case .restoreAccount:
//                state.path.append(.restoreAccount(RestoreAccountReducer.State()))
                state.path = .restoreAccount(RestoreAccountReducer.State())
                return .none
            }
        }
        .ifLet(\.$path, action: /Action.path) {
            Path(networkType: zcashNetwork.networkType)
        }
//        .forEach(\.path, action: /Action.path) {
//            Path(networkType: zcashNetwork.networkType)
//        }
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
