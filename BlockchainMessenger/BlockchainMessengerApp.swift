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
        rootStore.send(.appDelegate(.didFinishLaunching))

//        Task {
//            do {
//                try await messages.initialize()
//                let seed = """
//                burden help grit wheat sustain exit text radar ready wide tribe august post century suspect seminar relax mixed brother old enrich recycle \
//                turtle dice
//                """
//                let seedBytes = try Mnemonic.deterministicSeedBytes(from: seed)
//                try await messages.start(with: seedBytes, birthday: 2604585, walletMode: .existingWallet)
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
