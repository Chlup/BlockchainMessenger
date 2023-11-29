//
//  SDKSynchronizerTest.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 15.11.2022.
//
//  MIT License
//
//  Copyright (c) 2023 Zcash
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Combine
import ComposableArchitecture
import Foundation
import ZcashLightClientKit
import Models
import Utils

extension SDKSynchronizerClient: TestDependencyKey {
    public static let previewValue = Self.noOp
    public static let testValue = Self()
}

extension SDKSynchronizerClient {
    public static let noOp = Self(
        stateStream: { Empty().eraseToAnyPublisher() },
        eventStream: { Empty().eraseToAnyPublisher() },
        latestState: { .zero },
        prepareWith: { _, _, _ in },
        start: { _ in },
        stop: { },
        isSyncing: { false },
        isInitialized: { false },
        rewind: { _ in Empty<Void, Error>().eraseToAnyPublisher() },
        getShieldedBalance: { .zero },
        getTransparentBalance: { .zero },
        getAllTransactions: { [] },
        getMemos: { _ in [] },
        getUnifiedAddress: { _ in nil },
        getTransparentAddress: { _ in nil },
        getSaplingAddress: { _ in nil },
        getTransaction: { _ in nil },
        sendTransaction: { _, _, _, _ in return Data() },
//        shieldFunds: { _, _, _ in return .placeholder() },
        wipe: { Empty<Void, Error>().eraseToAnyPublisher() }
    )

    public static let mock = Self.mocked()
}

extension SDKSynchronizerClient {
    public static func mocked(
        stateStream: @escaping () -> AnyPublisher<SynchronizerState, Never> = { Just(.zero).eraseToAnyPublisher() },
        eventStream: @escaping () -> AnyPublisher<SynchronizerEvent, Never> = { Empty().eraseToAnyPublisher() },
        latestState: @escaping () -> SynchronizerState = { .zero },
        latestScannedHeight: @escaping () -> BlockHeight = { 0 },
        prepareWith: @escaping ([UInt8], BlockHeight, WalletInitMode) throws -> Void = { _, _, _ in },
        start: @escaping (_ retry: Bool) throws -> Void = { _ in },
        stop: @escaping () -> Void = { },
        isSyncing: @escaping () -> Bool = { false },
        isInitialized: @escaping () -> Bool = { false },
        rewind: @escaping (RewindPolicy) -> AnyPublisher<Void, Error> = { _ in return Empty<Void, Error>().eraseToAnyPublisher() },
        getShieldedBalance: @escaping () -> WalletBalance? = { WalletBalance(verified: Zatoshi(12345000), total: Zatoshi(12345000)) },
        getTransparentBalance: @escaping () -> WalletBalance? = { WalletBalance(verified: Zatoshi(12345000), total: Zatoshi(12345000)) },
        getAllTransactions: @escaping () -> [TransactionState] = {
            let mockedCleared: [TransactionStateMockHelper] = [
                TransactionStateMockHelper(date: 1651039202, amount: Zatoshi(1), status: .paid, uuid: "aa11"),
                TransactionStateMockHelper(date: 1651039101, amount: Zatoshi(2), uuid: "bb22"),
                TransactionStateMockHelper(date: 1651039000, amount: Zatoshi(3), status: .paid, uuid: "cc33"),
                TransactionStateMockHelper(date: 1651039505, amount: Zatoshi(4), uuid: "dd44"),
                TransactionStateMockHelper(date: 1651039404, amount: Zatoshi(5), uuid: "ee55")
            ]

            var clearedTransactions = mockedCleared
                .map {
                    let transaction = TransactionState.placeholder(
                        amount: $0.amount,
                        fee: Zatoshi(10),
                        shielded: $0.shielded,
                        status: $0.status,
                        timestamp: $0.date,
                        uuid: $0.uuid
                    )
                    return transaction
                }
        
            let mockedPending: [TransactionStateMockHelper] = [
                TransactionStateMockHelper(
                    date: 1651039606,
                    amount: Zatoshi(6),
                    status: .paid,
                    uuid: "ff66"
                ),
                TransactionStateMockHelper(date: 1651039303, amount: Zatoshi(7), uuid: "gg77"),
                TransactionStateMockHelper(date: 1651039707, amount: Zatoshi(8), status: .paid, uuid: "hh88"),
                TransactionStateMockHelper(date: 1651039808, amount: Zatoshi(9), uuid: "ii99")
            ]

            let pendingTransactions = mockedPending
                .map {
                    let transaction = TransactionState.placeholder(
                        amount: $0.amount,
                        fee: Zatoshi(10),
                        shielded: $0.shielded,
                        status: $0.amount.amount > 5 ? .sending : $0.status,
                        timestamp: $0.date,
                        uuid: $0.uuid
                    )
                    return transaction
                }
            
            clearedTransactions.append(contentsOf: pendingTransactions)

            return clearedTransactions
        },
        getMemos: @escaping (_ transactionRawID: Data) async throws -> [Memo] = { _ in return [] },
        getUnifiedAddress: @escaping (_ account: Int) -> UnifiedAddress? = { _ in
            // swiftlint:disable:next force_try
            try! UnifiedAddress(
                encoding: """
                utest1zkkkjfxkamagznjr6ayemffj2d2gacdwpzcyw669pvg06xevzqslpmm27zjsctlkstl2vsw62xrjktmzqcu4yu9zdhdxqz3kafa4j2q85y6mv74rzjcgjg8c0ytrg7d\
                wyzwtgnuc76h
                """,
                network: .testnet
            )
        },
        getTransparentAddress: @escaping (_ account: Int) -> TransparentAddress? = { _ in return nil },
        getSaplingAddress: @escaping (_ accountIndex: Int) async -> SaplingAddress? = { _ in
            // swiftlint:disable:next force_try
            try! SaplingAddress(
                encoding: "ztestsapling1edm52k336nk70gxqxedd89slrrf5xwnnp5rt6gqnk0tgw4mynv6fcx42ym6x27yac5amvfvwypz",
                network: .testnet
            )
        },
        getTransaction: @escaping (_ rawID: Data) async throws -> ZcashTransaction.Overview? = { _ in nil },
        sendTransaction:
        @escaping (UnifiedSpendingKey, Zatoshi, Recipient, Memo?) async throws -> Data = { _, _, _, _ in
            return Data()
        },
//        shieldFunds: @escaping (UnifiedSpendingKey, Memo, Zatoshi) async throws -> TransactionState = { _, memo, _  in
//            TransactionState(
//                expiryHeight: 40,
//                memos: [memo],
//                minedHeight: 50,
//                shielded: true,
//                zAddress: "tteafadlamnelkqe",
//                fee: Zatoshi(10),
//                id: "id",
//                status: .paid,
//                timestamp: 1234567,
//                zecAmount: Zatoshi(10)
//            )
//        },
        wipe: @escaping () -> AnyPublisher<Void, Error>? = { Fail(error: "Error").eraseToAnyPublisher() }
    ) -> SDKSynchronizerClient {
        SDKSynchronizerClient(
            stateStream: stateStream,
            eventStream: eventStream,
            latestState: latestState,
            prepareWith: prepareWith,
            start: start,
            stop: stop,
            isSyncing: isSyncing,
            isInitialized: isInitialized,
            rewind: rewind,
            getShieldedBalance: getShieldedBalance,
            getTransparentBalance: getTransparentBalance,
            getAllTransactions: getAllTransactions,
            getMemos: getMemos,
            getUnifiedAddress: getUnifiedAddress,
            getTransparentAddress: getTransparentAddress,
            getSaplingAddress: getSaplingAddress,
            getTransaction: getTransaction,
            sendTransaction: sendTransaction,
//            shieldFunds: shieldFunds,
            wipe: wipe
        )
    }
}
