//
//  SDKManager.swift
//  BlockchainMessenger
//
//  Created by Michal Fousek on 19.11.2023.
//
//  MIT License
//
//  Copyright (c) 2023 Mugeaters
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
import Dependencies
import Foundation
import MnemonicSwift
import SDKSynchronizer
import ZcashLightClientKit

protocol SDKManager: AnyObject {
    var importantSDKEventsStream: AnyPublisher<Void, Never> { get }

    func start(with seedBytes: [UInt8], birthday: BlockHeight, walletMode: WalletInitMode) async throws
}

final class SDKManagerImpl {
    @Dependency(\.sdkSynchronizer) var synchronizer
    @Dependency(\.logger) var logger

    private var cancellables: [AnyCancellable] = []

    var importantSDKEventsStream: AnyPublisher<Void, Never> {
        let eventStreamSignal: AnyPublisher<Void, Never> = synchronizer.eventStream()
            .compactMap { event in
                switch event {
                case .foundTransactions:
                    return Void()

                default:
                    return nil
                }
            }
            .eraseToAnyPublisher()

        let syncFinishedSignalStream: AnyPublisher<Void, Never> = synchronizer.stateStream()
            .compactMap { state in
                switch state.syncStatus {
                case .upToDate:
                    return Void()
                default:
                    return nil
                }
            }
            .eraseToAnyPublisher()

        return Publishers.Merge(eventStreamSignal, syncFinishedSignalStream)
            .eraseToAnyPublisher()
    }

    // MARK: - Subscribe to SDK combine API

    private func subscribeToSynchronizer() {
        cancellables.forEach { $0.cancel() }
        cancellables = []
        synchronizer.stateStream()
            .sink(
                receiveValue: { [weak self] state in
                    self?.logger.debug("State:\n\(state)")
                }
            )
            .store(in: &cancellables)

        synchronizer.eventStream()
            .sink(
                receiveValue: { [weak self] event in
                    switch event {
                    case .foundTransactions:
                        self?.logger.debug("Found transactions !!! Manager")
                    default:
                        break
                    }
                    self?.logger.debug("Event:\n\(event)")
                }
            )
            .store(in: &cancellables)
    }
}

extension SDKManagerImpl: SDKManager {
    func start(with seedBytes: [UInt8], birthday: BlockHeight, walletMode: WalletInitMode) async throws {
        if synchronizer.latestState().syncStatus == .unprepared {
            do {
                try await synchronizer.prepareWith(seedBytes, birthday, walletMode)
            } catch {
                throw MessagesError.synchronizerInitFailed(error)
            }
        }

        subscribeToSynchronizer()
        try await synchronizer.start(false)
    }
}

private enum SDKManagerKey: DependencyKey {
    static let liveValue: SDKManager = SDKManagerImpl()
}

extension DependencyValues {
    var sdkManager: SDKManager {
        get { self[SDKManagerKey.self] }
        set { self[SDKManagerKey.self] = newValue }
    }
}
