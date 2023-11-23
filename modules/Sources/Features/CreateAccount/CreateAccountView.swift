//
//  CreateAccountView.swift
//
//
//  Created by Lukáš Korba on 20.11.2023.
//

import ComposableArchitecture
import SwiftUI

public struct CreateAccountView: View {
    let store: StoreOf<CreateAccountReducer>
    
    public init(store: StoreOf<CreateAccountReducer>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                Text(viewStore.birthdayValue ?? "")
                
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
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 15)
                }

                Button("I wrote it down") {
                    viewStore.send(.confirmationButtonTapped)
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
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
