//
//  FundsStore.swift
//
//
//  Created by Lukáš Korba on 27.11.2023.
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
