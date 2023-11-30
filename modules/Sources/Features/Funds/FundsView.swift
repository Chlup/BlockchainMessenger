//
//  FundsView.swift
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
            ScrollView(.vertical) {
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

                    Text("""
                    LICENSE:

                    MIT License

                    Copyright (c) 2023 Mugeaters

                    Permission is hereby granted, free of charge, to any person obtaining a copy
                    of this software and associated documentation files (the "Software"), to deal
                    in the Software without restriction, including without limitation the rights
                    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
                    copies of the Software, and to permit persons to whom the Software is
                    furnished to do so, subject to the following conditions:

                    The above copyright notice and this permission notice shall be included in all
                    copies or substantial portions of the Software.

                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
                    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
                    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
                    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
                    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
                    SOFTWARE.
                    """)

                    Spacer()
                }
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
