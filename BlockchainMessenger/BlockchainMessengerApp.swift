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
        print("DB path \(databaseFiles.messagesDBURL())")
        Task {
            do {
                try await messages.initialize(network: TargetConstants.zcashNetwork.networkType)
            } catch {
                // TODO: This must be somehow handled and communicated to user that something went seriously wrong.
                logger.error("Failed to initialize messages module!!!! This is fatal error. \(error)")
            }

//            do {
//                let seed = """
//                dinner agree envelope cannon process base interest allow mansion magnet hat harvest life capital pyramid clarify type offer leisure \
//                picture section tribe shove hair
//                """
//                let seedBytes = try Mnemonic.deterministicSeedBytes(from: seed)
//                try await messages.start(with: seedBytes, birthday: 2604585, walletMode: .existingWallet)

//                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
//                    guard let self = self else { return }
//                    Task {
//                        do {
//                            self.logger.debug("Creating new chat")
//                            try await self.messages.newChat(
//                                fromAddress: """
//                                utest1exhlew55lcx46lxp8pa8y3qssk848cq56dl6mg9sdrlgaytypresvkkvxgmhsmcz27w9ugmrq2qv7mfam0awctysu9v7zqtgrnqduj7g6qp2gk2lsn\
//                                f6e0yjx7339jhwvl2f2q4twfy
//                                """,
//                                toAddress:"""
//                                utest1rnyjr8jak3uzw4rylwydw5lkd9x2f4ce0wmnv699nlw5g94x758ah6pg774k0fcqxx98eagp90vqrxemfcxhym44qt54gftl9ff6nh0084hnamtu45\
//                                l7un362z2rg9ukfjw0qrx4qer
//                                """,
//                                verificationText: "612398"
//                            )
//                        } catch {
//                            self.logger.debug("Failed to create new chat: \(error)")
//                        }
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
}

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
