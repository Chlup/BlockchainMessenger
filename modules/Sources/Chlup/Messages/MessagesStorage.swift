//
//  MessagesStorage.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 19.11.2023.
//

import Foundation
import ZcashLightClientKit

public typealias TransactionID = String
public typealias MessageID = String

public protocol MessagesStorage {
    func store(transaction: Transaction) async throws
}

public actor MessagesStorageImpl {
    private var messages: [TransactionID: Message] = [:]
    private var messagesList: [Message] = []

    let synchronizer: Synchronizer
    init(synchronizer: Synchronizer) {
        self.synchronizer = synchronizer
    }

    private func processTransactionForExistingMessage(transaction: Transaction, existingMessage: Message) {
        // Previously we stored message from transaction which wasn't mined. Now we have the same transaction but is mined. We should update
        // height of message.
        if  let minedHeight = transaction.minedHeight,
            existingMessage.transactionHeight == nil,
            let messageIndex = messagesList.firstIndex(of: existingMessage) {

            let newMessage = Message(
                id: existingMessage.id,
                state: existingMessage.state,
                text: existingMessage.text,
                transactionID: existingMessage.transactionID,
                transactionHeight: minedHeight
            )

            messages[existingMessage.transactionID] = newMessage
            messagesList[messageIndex] = newMessage
        }
    }

    private func processNewTransaction(_ transaction: Transaction) async throws {
        print("Storing new transaction")
        // Transaction must have memo
        guard transaction.memoCount > 0 else {
            print("Transaction doesn't have memos count")
            return
        }
        let memos = try await synchronizer.getMemos(for: transaction.rawID)
        // Memo must be text and text of memo must be recognized as chat message.
        guard let memo = memos.first else {
            print("Transaction doesn't have memos")
            return
        }

        guard let text = memo.toString() else {
            print("Memo for transaction can't be converted to text.")
            return
        }

        guard doesMemoContainChatMessage(text: text) else { return }

        print("Storing!!!!")

        let message = Message(
            id: UUID().uuidString,
            state: transaction.isSentTransaction ? .sent : .received,
            text: text,
            transactionID: transaction.rawID.sha256,
            transactionHeight: transaction.minedHeight
        )

        messages[message.transactionID] = message
        messagesList.append(message)
    }

    private func doesMemoContainChatMessage(text: String) -> Bool {
        // Here we must do some test for memo text to recognize chat messages. We need to distinguish between chat messages and regular financial
        // transactions with memos.
        return true
    }
}

extension MessagesStorageImpl: MessagesStorage {
    public func store(transaction: Transaction) async throws {
        print("Storing transaction in storage")
        let transactionID = transaction.rawID.sha256
        if let existingMessage = messages[transactionID] {
            processTransactionForExistingMessage(transaction: transaction, existingMessage: existingMessage)
        } else {
            try await processNewTransaction(transaction)
        }

        print("Messages list: \(messagesList.count)")
        if messagesList.count > 0 {
            for message in messagesList {
                var output = message.state == .sent ? "S: " : "R: "
                output += message.text
                print(output)
            }
            
            print("Raw messages:")
            messagesList.forEach { print($0) }
        }
    }
}
