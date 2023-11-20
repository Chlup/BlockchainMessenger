//
//  BlockchainMessengerApp.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 17.11.2023.
//

import SwiftUI
import ComposableArchitecture
import Messages
import Root
import Dependencies

final class AppDelegate: NSObject, UIApplicationDelegate {
    @Dependency(\.messages) var messages

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task {
            let seed = """
            vault stage draft bomb sport actor phrase sunset filter yellow coral jealous loan exact spot announce dragon federal congress false \
            link either frown economy
            """

            do {
                try await messages.start(with: seed, birthday: 2115000, walletMode: .existingWallet)
            } catch {
                print("Init or sync failed with error: \(error)")
            }
        }

        return true
    }
}

@main
struct BlockchainMessengerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView(
                store:
                    Store(
                        initialState: RootReducer.State()
                    ) {
                        RootReducer()
                            ._printChanges()
                    }
            )
        }
    }
}
