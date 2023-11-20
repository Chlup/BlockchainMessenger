//
//  SDKSynchronizerBuilder.swift
//
//
//  Created by Michal Fousek on 20.11.2023.
//

import Foundation
import ZcashLightClientKit
import Dependencies

fileprivate enum SDKSynchronizerBuilder {
    enum Constants {
        static let zcashNetwork = ZcashNetworkBuilder.network(for: .testnet)
        static let host = /*ZcashSDK.isMainnet ? "mainnet.lightwalletd.com" : */"lightwalletd.testnet.electriccoin.co"
        static let port: Int = 9067
    }

    static func buildLive() -> Synchronizer {
        // We need to use some kind of DI here in future
        let initializer = Initializer(
            cacheDbURL: nil,
            fsBlockDbRoot: Self.fsBlockDbRootURLHelper(),
            generalStorageURL: Self.generalStorageURLHelper(),
            dataDbURL: Self.dataDbURLHelper(),
            endpoint: LightWalletEndpoint(address: Constants.host, port: Constants.port, secure: true, streamingCallTimeoutInMillis: 10 * 60 * 60 * 1000),
            network: Constants.zcashNetwork,
            spendParamsURL: Self.spendParamsURLHelper(),
            outputParamsURL: Self.outputParamsURLHelper(),
            saplingParamsSourceURL: SaplingParamsSourceURL.default,
            enableBackendTracing: true
        )

        return SDKSynchronizer(initializer: initializer)
    }

    private static func documentsDirectoryHelper() -> URL {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            // This is not super clean but this is second best thing when the above call fails.
            return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
        }
    }

    private static func fsBlockDbRootURLHelper() -> URL {
        Self.documentsDirectoryHelper()
            .appendingPathComponent(Constants.zcashNetwork.networkType.chainName)
            .appendingPathComponent(
                ZcashSDK.defaultFsCacheName,
                isDirectory: true
            )
    }

    private static func generalStorageURLHelper() -> URL {
        Self.documentsDirectoryHelper()
            .appendingPathComponent(Constants.zcashNetwork.networkType.chainName)
            .appendingPathComponent(
                "general_storage",
                isDirectory: true
            )
    }

    private static func cacheDbURLHelper() -> URL {
        Self.documentsDirectoryHelper()
            .appendingPathComponent(
                Constants.zcashNetwork.constants.defaultDbNamePrefix + ZcashSDK.defaultCacheDbName,
                isDirectory: false
            )
    }

    private static func dataDbURLHelper() -> URL {
        Self.documentsDirectoryHelper()
            .appendingPathComponent(
                Constants.zcashNetwork.constants.defaultDbNamePrefix + ZcashSDK.defaultDataDbName,
                isDirectory: false
            )
    }

    private static func spendParamsURLHelper() -> URL {
        Self.documentsDirectoryHelper().appendingPathComponent("sapling-spend.params")
    }

    private static func outputParamsURLHelper() -> URL {
        Self.documentsDirectoryHelper().appendingPathComponent("sapling-output.params")
    }
}

private enum SDKSynchronizerKey: DependencyKey {
    static let liveValue = SDKSynchronizerBuilder.buildLive()
}

extension DependencyValues {
    var sdkSynchronizer: Synchronizer {
        get { self[SDKSynchronizerKey.self] }
        set { self[SDKSynchronizerKey.self] = newValue }
    }
}
