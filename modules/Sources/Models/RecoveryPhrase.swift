//
//  RecoveryPhrase.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 12.05.2022.
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

import Foundation
import ZcashLightClientKit
import Utils

public enum RecoveryPhraseError: Error {
    /// This error is thrown then the Recovery Phrase can't be generated
    case unableToGeneratePhrase
}

public struct RecoveryPhrase: Equatable, Redactable {
    public struct Group: Hashable {
        public var startIndex: Int
        public var words: [RedactableString]
    }

    public let words: [RedactableString]
    
    private let groupSize = 6

    public init(words: [RedactableString]) {
        self.words = words
    }
    
    public func toGroups() -> [Group] {
        let chunks = words.count / 2

        var res: [Group] = []
        
        for i in 0..<2 {
            var subwords: [RedactableString] = []
            for j in (i * chunks)..<((i + 1) * chunks) {
                subwords.append(words[j])
            }
            res.append(Group(startIndex: i * chunks, words: subwords))
        }
        
        return res
    }

    public func toString() -> RedactableString {
        let result = words
            .map { $0.data }
            .joined(separator: " ")
        return result.redacted
    }
}

// TODO: [#695] This should have a #DEBUG tag, but if so, it's not possible to compile this on release mode and submit it to testflight https://github.com/zcash/ZcashLightClientKit/issues/695
extension RecoveryPhrase {
    public static let testPhrase = [
        // 1
        "bring", "salute", "thank",
        "require", "spirit", "toe",
        // 7
        "boil", "hill", "casino",
        "trophy", "drink", "frown",
        // 13
        "bird", "grit", "close",
        "morning", "bind", "cancel",
        // 19
        "daughter", "salon", "quit",
        "pizza", "just", "garlic"
    ]

    public static let placeholder = RecoveryPhrase(words: testPhrase.map { $0.redacted })
    public static let initial = RecoveryPhrase(words: [])
}

extension RecoveryPhrase.Group {
    /// Returns an array of words where the word at the missing index will be an empty string
    func words(with missingIndex: Int) -> [RedactableString] {
        assert(missingIndex >= 0)
        assert(missingIndex < self.words.count)

        var wordsApplyingMissing = self.words

        wordsApplyingMissing[missingIndex] = "".redacted
        
        return wordsApplyingMissing
    }
}
