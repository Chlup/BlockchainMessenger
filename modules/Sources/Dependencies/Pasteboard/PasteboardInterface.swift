//
//  PasteboardInterface.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 13.11.2022.
//

import ComposableArchitecture
import Utils

extension DependencyValues {
    public var pasteboard: PasteboardClient {
        get { self[PasteboardClient.self] }
        set { self[PasteboardClient.self] = newValue }
    }
}

@DependencyClient
public struct PasteboardClient {
    public var setString: (RedactableString) -> Void
    public var getString: () -> RedactableString?
}
