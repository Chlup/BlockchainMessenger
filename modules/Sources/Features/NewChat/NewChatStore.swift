//
//  NewChatStore.swift
//
//
//  Created by Lukáš Korba on 24.11.2023.
//

import ComposableArchitecture
import ZcashLightClientKit

import DerivationTool

public struct NewChatReducer: Reducer {
    let networkType: NetworkType

    public struct State: Equatable {
        var isValidAddress = false
        var isValidAlias = false
        var isValidForm = false
        @BindingState public var uAddress = ""
        @BindingState public var alias = ""

        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case startChatButtonTapped
    }
      
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.derivationTool) var derivationTool
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                state.isValidAddress = derivationTool.isUnifiedAddress(state.uAddress, networkType)
                state.isValidAlias = !state.alias.isEmpty
                state.isValidForm = state.isValidAddress && state.isValidAlias
                return .none
                
            case .startChatButtonTapped:
                return .none
            }
        }
    }
}
