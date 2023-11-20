//
//  RootStore.swift
//
//
//  Created by Lukáš Korba on 20.11.2023.
//

import ComposableArchitecture
import CreateAccount
import RestoreAccount

public struct RootReducer: Reducer {
    public struct State: Equatable {
        var path = StackState<Path.State>()
        
        public init(path: StackState<Path.State> = StackState<Path.State>()) {
            self.path = path
        }
    }
    
    public enum Action: Equatable {
        case path(StackAction<Path.State, Path.Action>)
    }
    
    public struct Path: Reducer {
        public enum State: Equatable {
            case createAccount(CreateAccountReducer.State)
            case restoreAccount(RestoreAccountReducer.State)
        }
        
        public enum Action: Equatable {
            case createAccount(CreateAccountReducer.Action)
            case restoreAccount(RestoreAccountReducer.Action)
        }
        
        public init() {}
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.createAccount, action: /Action.createAccount) {
                CreateAccountReducer()
            }
            Scope(state: /State.restoreAccount, action: /Action.restoreAccount) {
                RestoreAccountReducer()
            }
        }
    }
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: /Action.path) {
            Path()
        }
    }
}
