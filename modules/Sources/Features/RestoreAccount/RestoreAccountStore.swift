//
//  RestoreAccountStore.swift
//  
//
//  Created by Lukáš Korba on 20.11.2023.
//

import ComposableArchitecture

public struct RestoreAccountReducer: Reducer {
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
    }
        
    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            }
        }
    }
}
