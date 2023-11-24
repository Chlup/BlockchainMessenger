//
//  ChatsListStore.swift
//
//
//  Created by Lukáš Korba on 23.11.2023.
//

import ComposableArchitecture
import ZcashLightClientKit

import NewChat

public struct ChatsListReducer: Reducer {
    let networkType: NetworkType

    public struct State: Equatable {
        @PresentationState public var newChat: NewChatReducer.State?

        public init() {
        }
    }
    
    public enum Action: Equatable {
        case newChat(PresentationAction<NewChatReducer.Action>)
        case newChatButtonTapped
    }
      
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .newChat(.presented(.startChatButtonTapped)):
                if let uAddress = state.newChat?.uAddress {
                    // TODO: here we know what UA user wants to initiate chat with
                    print(uAddress)
                }
                state.newChat = nil
                return .none
                
            case .newChat:
                return .none
            
            case .newChatButtonTapped:
                state.newChat = NewChatReducer.State()
                return .none
            }
        }
        .ifLet(\.$newChat, action: /Action.newChat) {
            NewChatReducer(networkType: networkType)
        }
    }
}
