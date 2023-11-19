//
//  BlockchainMessengerApp.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 17.11.2023.
//

import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    let sdkManager = SDKManagerImpl()
    var messagesManager: MessagesManagerImpl!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        do {
            let encoded = try ChatProtocol.encodeMessage(chatID: 21768, message: .text("Hello 🐞world"))
            switch encoded {
            case let .text(text):
                print(text)
                print("decoding")
                let decoded = try ChatProtocol.decode(message: text)
                print(decoded)
            }

        } catch {
            print("Error while encoding/decoding message: \(error)")
        }

//        messagesManager = MessagesManagerImpl(
//            synchronizer: sdkManager.synchronizer,
//            foundTransactionsStream: sdkManager.transactionsStream
//        )
//        messagesManager.start()
//
//        Task {
//            let seed = """
//            vault stage draft bomb sport actor phrase sunset filter yellow coral jealous loan exact spot announce dragon federal congress false \
//            link either frown economy
//            """
//
//            do {
//                try await sdkManager.start(with: seed, birthday: 2115000, walletMode: .existingWallet)
//            } catch {
//                print("Init or sync failed with error: \(error)")
//            }
//        }

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
