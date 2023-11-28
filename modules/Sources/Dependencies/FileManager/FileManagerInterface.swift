//
//  FileManagerClient.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 07.04.2022.
//

import ComposableArchitecture
import Foundation

@DependencyClient
public struct FileManagerClient {
    public var url: (FileManager.SearchPathDirectory, FileManager.SearchPathDomainMask, URL?, Bool) throws -> URL
    public var fileExists: (String) -> Bool = { _ in false }
    public var removeItem: (URL) throws -> Void
}
