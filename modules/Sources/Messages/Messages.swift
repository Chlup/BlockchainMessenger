//
//  Messages.swift
//
//
//  Created by Michal Fousek on 20.11.2023.
//

import Foundation
import Dependencies
import ZcashLightClientKit

public enum MessagesError: Error {
    case chatEntityInit(Error)
    case messageEntityInit(Error)
    case simpleConnectionProvider(Error)
    case synchronizerInitFailed(Error)
    case messagesStorageQueryExecute(Error)
    case messagesStorageEntityNotFound
}

public protocol Messages {
    func initialize() async throws
    func start(with seedBytes: [UInt8], birthday: BlockHeight, walletMode: WalletInitMode) async throws
}

struct MessagesImpl {
    @Dependency(\.transactionsProcessor) var transactionsProcessor
    @Dependency(\.sdkManager) var sdkManager
    @Dependency(\.logger) var logger
    @Dependency(\.chatProtocol) var chatProtocol
    @Dependency(\.chatIDBuilder) var chatIDBuilder
    @Dependency(\.timestampBuilder) var timestampBuilder
    @Dependency(\.messagesStorage) var messagesStorage
}

extension MessagesImpl: Messages {
    func initialize() async throws {
        try await messagesStorage.initialize()
    }

    func start(with seedBytes: [UInt8], birthday: BlockHeight, walletMode: WalletInitMode) async throws {
//        do {
//            let message = ChatProtocol.Message(
//                chatID: chatIDBuilder.buildForNow(),
//                timestmap: timestampBuilder.now(),
//                content: .text("Hello 🐞world")
//            )
//
//            let encoded = try chatProtocol.encode(message)
//
//            let decoded = try chatProtocol.decode(encoded)
//            logger.debug("Decoded message \(decoded)")
//
//        } catch {
//            logger.debug("Error while encoding/decoding message: \(error)")
//        }

        await transactionsProcessor.start()
        try await sdkManager.start(with: seedBytes, birthday: birthday, walletMode: walletMode)
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
