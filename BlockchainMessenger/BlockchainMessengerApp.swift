//
//  BlockchainMessengerApp.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 17.11.2023.
//

import SwiftUI
import ComposableArchitecture
import ZcashLightClientKit
import SDKSynchronizer
import Utils
import Root
import Messages
import MnemonicSwift
import Dependencies

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
        Task {
            do {
                try await messages.initialize(network: TargetConstants.zcashNetwork.networkType)
            } catch {
                // TODO: This must be somehow handled and communicated to user that something went seriously wrong.
                logger.error("Failed to initialize messages module!!!! This is fatal error. \(error)")
            }

            // Debugging stuff to test stuff
//            do {
//                let seed = """
//                dinner agree envelope cannon process base interest allow mansion magnet hat harvest life capital pyramid clarify type offer leisure \
//                picture section tribe shove hair
//                """
//                let seedBytes = try Mnemonic.deterministicSeedBytes(from: seed)
//                try await messages.start(with: seedBytes, birthday: 2604585, walletMode: .existingWallet)
//
//                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
//                    guard let self = self else { return }
//                    Task {
////                        try? await self.listAllChatsAndMessages()
////                        try? await sendMessageToFirstChat()
////                        try? await createNewChat()
//                    }
//                }
//            } catch {
//                logger.debug("Failed to init SDK: \(error)")
//            }
        }
        rootStore.send(.appDelegate(.didFinishLaunching))

        return true
    }

    func application(
        _ application: UIApplication,
        shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier
    ) -> Bool {
        return extensionPointIdentifier != UIApplication.ExtensionPointIdentifier.keyboard
    }

    // MARK: - Debug

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
            try await messages.sendMessage(chatID: firstChat.chatID, text: "Hello 🐞world")
        } catch {
            logger.debug("Failed to send message: \(error)")
            throw error
        }
    }

    private func createNewChat() async throws {
        do {
            logger.debug("Creating new chat")
            try await messages.newChat(
                fromAddress: """
                utest1exhlew55lcx46lxp8pa8y3qssk848cq56dl6mg9sdrlgaytypresvkkvxgmhsmcz27w9ugmrq2qv7mfam0awctysu9v7zqtgrnqduj7g6qp2gk2lsn\
                f6e0yjx7339jhwvl2f2q4twfy
                """,
                toAddress:"""
                utest1rnyjr8jak3uzw4rylwydw5lkd9x2f4ce0wmnv699nlw5g94x758ah6pg774k0fcqxx98eagp90vqrxemfcxhym44qt54gftl9ff6nh0084hnamtu45\
                l7un362z2rg9ukfjw0qrx4qer
                """,
                verificationText: "612398"
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

