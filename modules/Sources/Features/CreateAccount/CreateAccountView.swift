//
//  CreateAccountView.swift
//
//
//  Created by Lukáš Korba on 20.11.2023.
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

import Generated
import Utils

public struct CreateAccountView: View {
    let store: StoreOf<CreateAccountReducer>
    
    public init(store: StoreOf<CreateAccountReducer>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationStack {
                VStack(spacing: 50) {
                    Group {
                        Text("Birthday ")
                        + Text(viewStore.birthdayValue ?? "")
                    }
                    .foregroundStyle(Asset.Colors.fontPrimary.color)
                    
                    if let groups = viewStore.phrase?.toGroups() {
                        HStack {
                            ForEach(groups, id: \.startIndex) { group in
                                VStack(alignment: .leading) {
                                    HStack(spacing: 2) {
                                        VStack(alignment: .trailing, spacing: 2) {
                                            ForEach(Array(group.words.enumerated()), id: \.offset) { seedWord in
                                                Text("\(seedWord.offset + group.startIndex + 1).")
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            ForEach(Array(group.words.enumerated()), id: \.offset) { seedWord in
                                                Text("\(seedWord.element.data)")
                                                    .minimumScaleFactor(0.5)
                                            }
                                        }
                                        
                                        if group.startIndex == 0 {
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .foregroundStyle(Asset.Colors.fontPrimary.color)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 15)
                    }
                    
                    Button("I wrote it down") {
                        viewStore.send(.confirmationButtonTapped)
                    }
                    .neumorphicButton()
                }
                
                .padding(.horizontal, 35)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewStore.send(.tapToCopyTapped)
                        } label: {
                            Text("Tap to copy")
                                .foregroundStyle(Asset.Colors.fontPrimary.color)
                                .underline()
                        }
                    }
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
                .applyScreenBackground()
            }
        }
    }
}

#Preview {
    CreateAccountView(
        store:
            Store(
                initialState: CreateAccountReducer.State()
            ) {
                CreateAccountReducer()
                    ._printChanges()
            }
    )
}
