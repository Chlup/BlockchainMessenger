//
//  FundsView.swift
//
//
//  Created by Lukáš Korba on 27.11.2023.
//

import ComposableArchitecture
import SwiftUI
import ZcashLightClientKit

import Generated
import Utils

public struct FundsView: View {
    let store: StoreOf<FundsReducer>
    
    public init(store: StoreOf<FundsReducer>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 20) {
                Text("Address of your account")
                
                Text(viewStore.uAddress.data)
                    .font(.system(size: 13))
                    .foregroundStyle(Asset.Colors.fontPrimary.color)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(Asset.Colors.buttonBackground.color)
                            .neumorphicShape(cornerRadius: 10)
                    }
                
                Button {
                    viewStore.send(.tapToCopyTapped(viewStore.uAddress))
                } label: {
                    Text("Tap to copy")
                        .underline()
                }

                if let sAddress = viewStore.sAddress {
                    Text(sAddress.data)
                        .font(.system(size: 13))
                        .foregroundStyle(Asset.Colors.fontPrimary.color)
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(Asset.Colors.buttonBackground.color)
                                .neumorphicShape(cornerRadius: 10)
                        }
                    
                    Button {
                        viewStore.send(.tapToCopyTapped(sAddress))
                    } label: {
                        Text("Tap to copy")
                            .underline()
                    }
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                viewStore.send(.onAppear)
            }
            .foregroundStyle(Asset.Colors.fontPrimary.color)
        }
        .applyScreenBackground()
    }
}

#Preview {
    FundsView(
        store:
            Store(
                initialState: FundsReducer.State()
            ) {
                FundsReducer(networkType: ZcashNetworkBuilder.network(for: .testnet).networkType)
                    ._printChanges()
            }
    )
}
