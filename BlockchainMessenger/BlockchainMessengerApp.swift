//
//  BlockchainMessengerApp.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 17.11.2023.
//

import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    let sdkManager = SDKManagerImpl()

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
                try await sdkManager.start(with: seed, birthday: 2500000, walletMode: .existingWallet)
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
            ContentView()
        }
    }
}
