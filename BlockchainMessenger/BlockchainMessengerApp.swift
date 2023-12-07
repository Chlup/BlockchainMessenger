//
//  BlockchainMessengerApp.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 17.11.2023.
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
import Dependencies
import Foundation
import Messages
import MnemonicSwift
import Root
import SDKSynchronizer
import SQLite
import SwiftUI
import Utils
import ZcashLightClientKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    @Dependency(\.logger) var logger
    @Dependency(\.messages) var messages
    @Dependency(\.databaseFiles) var databaseFiles

    let rootStore = StoreOf<RootReducer>(
        initialState: RootReducer.State()
    ) {
        RootReducer(zcashNetwork: TargetConstants.zcashNetwork)
            ._printChanges()
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.debug("DB path \(databaseFiles.messagesDBURL())")

        rootStore.send(.appDelegate(.didFinishLaunching))

//        Task {

//            do {
//                try await messages.initialize(network: TargetConstants.zcashNetwork.networkType)
//            } catch {
//                // TODO: This must be somehow handled and communicated to user that something went seriously wrong.
//                logger.error("Failed to initialize messages module!!!! This is fatal error. \(error)")
//            }

            // Debugging stuff to test stuff
//            do {
//                let seed = """
//                burden help grit wheat sustain exit text radar ready wide tribe august post century suspect seminar relax mixed brother old enrich \
//                recycle turtle dice
//                """
//                let seedBytes = try Mnemonic.deterministicSeedBytes(from: seed)
//                try await messages.start(with: seedBytes, birthday: 2604585, walletMode: .existingWallet)

//                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
//                    guard let self = self else { return }
//                    Task {
//                          try? await self.verifyFirstUnverifiedChat()
////                        try? await self.updateAliasForFirstChat()
////                        try? await self.listAllChatsAndMessages()
////                        try? await self.sendMessageToFirstChat()
////                        try? await self.createNewChat()
//                    }
//                }
//            } catch {
//                logger.debug("Failed to init SDK: \(error)")
//            }
//        }
        return true
    }

    func application(
        _ application: UIApplication,
        shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier
    ) -> Bool {
        return extensionPointIdentifier != UIApplication.ExtensionPointIdentifier.keyboard
    }

    // MARK: - Debug

    private func verifyFirstUnverifiedChat() async throws {
        do {
            var chats = try await self.messages.allChats()
            guard let unverifiedChat = chats.first(where: { !$0.verified }) else {
                logger.debug("All chats are verified")
                return
            }
            logger.debug("\(unverifiedChat)")

            let verifiedChat = try await messages.verifyChat(
                fromAddress: "something",
                verificationText: "some", 
                alias: "Barbucha"
            )
            logger.debug("Verified: \(verifiedChat)")

            chats = try await self.messages.allChats()
            logger.debug("\(chats)")

        } catch {
            logger.debug("Failed to verify caht chat: \(error)")
            throw error
        }
    }

    private func updateAliasForFirstChat() async throws {
        do {
            var chats = try await self.messages.allChats()
            logger.debug("\(chats)")

            guard let chat = chats.first else {
                logger.debug("No chats found")
                return
            }

            try await messages.updateAlias(for: chat.chatID, alias: "New alias \(Int.random(in: 0...1000))")
            chats = try await self.messages.allChats()
            logger.debug("\(chats)")

        } catch {
            logger.debug("Failed to update alias for first chat: \(error)")
            throw error
        }
    }

    private func listAllChatsAndMessages() async throws {
        do {
            let chats = try await self.messages.allChats()

            if chats.count == 0 {
                logger.debug("No chats found")
            }

            for chat in chats {
                logger.debug("Chat: \(chat)")
                let messages = try await self.messages.allMessages(for: chat.chatID)
                messages.forEach { self.logger.debug("Message: \($0)") }
            }
        } catch {
            logger.debug("Failed to get chats: \(error)")
            throw error
        }
    }

    private func sendMessageToFirstChat() async throws {
        do {
            let chats = try await messages.allChats()

            guard let firstChat = chats.first else {
                logger.debug("No chats found")
                return
            }

            logger.debug("Sending message")
            _ = try await messages.sendMessage(chatID: firstChat.chatID, text: "Hello 🐞world")
        } catch {
            logger.debug("Failed to send message: \(error)")
            throw error
        }
    }

    private func createNewChat() async throws {
        do {
            logger.debug("Creating new chat")
            try await messages.newChat(
                toAddress:"""
                utest1rnyjr8jak3uzw4rylwydw5lkd9x2f4ce0wmnv699nlw5g94x758ah6pg774k0fcqxx98eagp90vqrxemfcxhym44qt54gftl9ff6nh0084hnamtu45\
                l7un362z2rg9ukfjw0qrx4qer
                """,
                verificationText: "612398",
                alias: "New chat"
            )
        } catch {
            logger.debug("Failed to create new chat: \(error)")
            throw error
        }
    }
}


// MARK: - Main app
@main
struct BlockchainMessengerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment (\.scenePhase) private var scenePhase
    
    init() {
        //FontFamily.registerAllCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                store: appDelegate.rootStore
            )
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                appDelegate.rootStore.send(.appDelegate(.willEnterForeground))
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                appDelegate.rootStore.send(.appDelegate(.didEnterBackground))
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: Zcash Network global type

public enum TargetConstants {
    public static var zcashNetwork: ZcashNetwork {
#if _MAINNET
    return ZcashNetworkBuilder.network(for: .mainnet)
#elseif _TESTNET
    return ZcashNetworkBuilder.network(for: .testnet)
#else
    fatalError("SECANT_MAINNET or SECANT_TESTNET flags not defined on Swift Compiler custom flags of your build target.")
#endif
    }
}

extension SDKSynchronizerClient: DependencyKey {
    public static let liveValue: SDKSynchronizerClient = Self.live(network: TargetConstants.zcashNetwork)
}

// MARK: - Debug

