//
//  MessagesSender.swift
//
//
//  Created by Michal Fousek on 24.11.2023.
//

import Foundation
import Dependencies
import SDKSynchronizer
import DerivationTool
import ZcashLightClientKit

protocol MessagesSender: Actor {
    func setNetwork(_ network: NetworkType) async
    func setSeedBytes(_ seedBytes: [UInt8]) async
    func newChat(fromAddress: String, toAddress: String, verificationText: String) async throws
    func sendMessage(chatID: Int, text: String) async throws
}

actor MessagesSenderImpl {
    @Dependency(\.sdkSynchronizer) var synchronizer
    @Dependency(\.messagesStorage) var storage
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.chatProtocol) var chatProtocol
    @Dependency(\.logger) var logger

    var network: NetworkType = .testnet
    var seedBytes: [UInt8] = []

    private func send(message: ChatProtocol.ChatMessage, toAddress: String) async throws {
        let encodedMessage = try chatProtocol.encode(message)
        logger.debug("Encoded: \(encodedMessage)")

        guard derivationTool.isUnifiedAddress(toAddress, network) else {
            throw MessagesError.invalidToAddressWhenCreatingChat
        }

        let spendingKey = try derivationTool.deriveSpendingKey(seedBytes, 0, network)
        let memo: Memo
        do {
            memo = try Memo(bytes: encodedMessage)
        } catch {
            throw MessagesError.cantCreateMemoFromMessageWhenCreatingChat(error)
        }

        let recipient: Recipient
        do {
            recipient = try Recipient(toAddress, network: network)
        } catch {
            throw MessagesError.cantCreateRecipientWhenCreatingChat(error)
        }

        try await synchronizer.sendTransaction(spendingKey, Constants.messagePrice, recipient, memo)
    }
}

extension MessagesSenderImpl: MessagesSender {
    private enum Constants {
        static let messagePrice = Zatoshi(1)
    }

    func setSeedBytes(_ seedBytes: [UInt8]) async {
        self.seedBytes = seedBytes
    }

    func setNetwork(_ network: NetworkType) async {
        self.network = network
    }

    func newChat(fromAddress: String, toAddress: String, verificationText: String) async throws {
        let newChat = Chat.createNew(alias: nil, fromAddress: fromAddress, toAddress: toAddress, verificationText: verificationText)
        let protocolMessage = ChatProtocol.ChatMessage(
            chatID: newChat.chatID,
            timestmap: newChat.timestamp,
            messageID: newChat.chatID,
            content: .initialisation(fromAddress, toAddress, verificationText)
        )

        guard derivationTool.isUnifiedAddress(fromAddress, network) else {
            throw MessagesError.invalidFromAddressWhenCreatingChat
        }

        try await send(message: protocolMessage, toAddress: toAddress)

        try await storage.storeChat(newChat)
    }
    
    func sendMessage(chatID: Int, text: String) async throws {

    }
}

private enum MessagesSenderClientKey: DependencyKey {
    static let liveValue: MessagesSender = MessagesSenderImpl()
}

extension DependencyValues {
    var messagesSender: MessagesSender {
        get { self[MessagesSenderClientKey.self] }
        set { self[MessagesSenderClientKey.self] = newValue }
    }
}

