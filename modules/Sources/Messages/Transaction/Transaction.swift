//
//  Transaction.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 19.11.2023.
//

import Foundation
import ZcashLightClientKit

struct Transaction {
    typealias ID = String

    let id: ID
    let rawID: Data
    let isSentTransaction: Bool
    let minedHeight: BlockHeight?
    let memoCount: Int

    init(id: ID, rawID: Data, isSentTransaction: Bool, minedHeight: BlockHeight?, memoCount: Int) {
        self.id = id
        self.rawID = rawID
        self.isSentTransaction = isSentTransaction
        self.minedHeight = minedHeight
        self.memoCount = memoCount
    }

    init(zcashTransaction: ZcashTransaction.Overview) {
        self.id = zcashTransaction.rawID.sha256
        self.rawID = zcashTransaction.rawID
        self.isSentTransaction = zcashTransaction.isSentTransaction
        self.minedHeight = zcashTransaction.minedHeight
        self.memoCount = zcashTransaction.memoCount
    }
}
