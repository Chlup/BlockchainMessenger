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

import Messages
import Pasteboard
import SDKSynchronizer
import Utils
import WalletStorage

@Reducer
public struct FundsReducer {
    private enum WipeCancelId { case timer }
    let networkType: NetworkType

    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action.Alert>?
        public var sAddress: RedactableString?
        public var uAddress: RedactableString = "".redacted

        public init() {}
    }
    
    public enum Action: Equatable {
        public enum Alert {
            case wipeAccount
        }

        case alert(PresentationAction<Alert>)
        case onAppear
        case onDisappear
        case sAddressResponse(RedactableString)
        case tapToCopyTapped(RedactableString)
        case uAddressResponse(RedactableString)
        case wipeFailed
        case wipeRequested
        case wipeSucceeded
    }
        
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.messages) var messages
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.sdkSynchronizer) var synchronizer
    @Dependency(\.walletStorage) var walletStorage

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

            case .onDisappear:
                return .cancel(id: WipeCancelId.timer)
                
            case .alert(.presented(.wipeAccount)):
                guard let wipePublisher = synchronizer.wipe() else {
                    return .none
                }
                return .publisher {
                    wipePublisher
                        .replaceEmpty(with: Void())
                        .map { _ in return FundsReducer.Action.wipeSucceeded }
                        .replaceError(with: FundsReducer.Action.wipeFailed)
                        .receive(on: mainQueue)
                }
                .cancellable(id: WipeCancelId.timer, cancelInFlight: true)
                
            case .alert:
                return .none

            case .sAddressResponse(let address):
                state.sAddress = address
                return .none

            case .tapToCopyTapped(let text):
                pasteboard.setString(text)
                return .none
                
            case .uAddressResponse(let address):
                state.uAddress = address
                return .none
                
            case .wipeFailed:
                state.alert = AlertState.wipeFailed()
                return .none

            case .wipeRequested:
                state.alert = AlertState.wipeRequest()
                return .none

            case .wipeSucceeded:
                return .run { send in
                    walletStorage.nukeWallet()
                    do {
                        try await messages.wipe()
                    } catch {
                        await send(.wipeFailed)
                    }
                }
            }
        }
    }
}

extension AlertState where Action == FundsReducer.Action.Alert {
    static func wipeRequest() -> Self {
        Self {
            TextState("Wipe the account")
        } actions: {
            ButtonState(role: .destructive, action: .wipeAccount) {
                TextState("yes")
            }
            ButtonState(role: .cancel) {
                TextState("no")
            }
        } message: {
            TextState("Are you sure you want to wipe the account? This action will delete all your data but restore of the account is possible anytime if you have the seed and birthday.")
        }
    }
    
    public static func wipeFailed() -> AlertState {
        AlertState {
            TextState("Wipe of the wallet failed.")
        }
    }
}
