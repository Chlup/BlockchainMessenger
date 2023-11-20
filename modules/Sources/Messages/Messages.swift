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
    @Dependency(\.sdkManager) var sdkManager
    @Dependency(\.logger) var logger
}

extension MessagesImpl: Messages {
    func start(with seed: String, birthday: BlockHeight, walletMode: WalletInitMode) async throws {
//        do {
//            let encoded = try ChatProtocol.encodeMessage(chatID: 21768, message: .text("Hello 🐞world"))
//            switch encoded {
//            case let .text(text):
//                logger.debug(text)
//                logger.debug("decoding")
//                let decoded = try ChatProtocol.decode(message: text)
//                logger.debug(decoded)
//            }
//
//        } catch {
//            logger.debug("Error while encoding/decoding message: \(error)")
//        }

        transactionsProcessor.start()
        try await sdkManager.start(with: seed, birthday: birthday, walletMode: walletMode)
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
