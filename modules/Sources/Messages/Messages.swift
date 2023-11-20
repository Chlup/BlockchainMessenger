//
//  Messages.swift
//
//
//  Created by Michal Fousek on 20.11.2023.
//

import Foundation
import Dependencies
import ZcashLightClientKit

public protocol Messages {
    func start(with seed: String, birthday: BlockHeight, walletMode: WalletInitMode) async throws
}

struct MessagesImpl {
    @Dependency(\.transactionsProcessor) var transactionsProcessor
}

extension MessagesImpl: Messages {
    func start(with seed: String, birthday: BlockHeight, walletMode: WalletInitMode) async throws {
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

        //        TransactionsProcessor = TransactionsProcessorImpl(
        //            synchronizer: sdkManager.synchronizer,
        //            foundTransactionsStream: sdkManager.transactionsStream
        //        )
        //        TransactionsProcessor.start()
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
    }
}

private enum MessagesClientKey: DependencyKey {
    static let liveValue: Messages = MessagesImpl()
}

extension DependencyValues {
    public var messages: Messages {
        get { self[MessagesClientKey.self] }
        set { self[MessagesClientKey.self] = newValue }
    }
}
