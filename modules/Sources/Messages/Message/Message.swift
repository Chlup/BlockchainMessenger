//
//  Message.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 19.11.2023.
//

import Foundation
import ZcashLightClientKit

struct Message {
    enum State {
        case sent
        case received
    }

    let id: MessageID
    let state: State
    let text: String
    let transactionID: TransactionID
    let transactionHeight: BlockHeight?
}

extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}
