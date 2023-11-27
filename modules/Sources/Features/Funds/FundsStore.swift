//
//  FundsStore.swift
//
//
//  Created by Lukáš Korba on 27.11.2023.
//

import ComposableArchitecture
import ZcashLightClientKit

import Pasteboard
import SDKSynchronizer
import Utils

@Reducer
public struct FundsReducer {
    let networkType: NetworkType

    public struct State: Equatable {
        public var sAddress: RedactableString?
        public var uAddress: RedactableString = "".redacted

        public init() {}
    }
    
    public enum Action: Equatable {
        case onAppear
        case sAddressResponse(RedactableString)
        case tapToCopyTapped(RedactableString)
        case uAddressResponse(RedactableString)
    }
        
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }

    @Dependency(\.sdkSynchronizer) var synchronizer
    @Dependency(\.pasteboard) var pasteboard
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    if networkType == .testnet {
                        if let address = try await synchronizer.getSaplingAddress(0) {
                            await send(.sAddressResponse(address.stringEncoded.redacted))
                        }
                    }
                    if let address = try await synchronizer.getUnifiedAddress(0) {
                        await send(.uAddressResponse(address.stringEncoded.redacted))
                    }
                }

            case .sAddressResponse(let address):
                state.sAddress = address
                return .none

            case .tapToCopyTapped(let text):
                pasteboard.setString(text)
                return .none
                
            case .uAddressResponse(let address):
                state.uAddress = address
                return .none
            }
        }
    }
}
