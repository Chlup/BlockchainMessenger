//
//  MnemonicMocks.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 13.11.2022.
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

import Foundation

extension MnemonicClient {
    public static let mock = MnemonicClient(
        randomMnemonic: {
            """
            still champion voice habit trend flight \
            survey between bitter process artefact blind \
            carbon truly provide dizzy crush flush \
            breeze blouse charge solid fish spread
            """
        },
        randomMnemonicWords: {
            let mnemonic = """
                still champion voice habit trend flight \
                survey between bitter process artefact blind \
                carbon truly provide dizzy crush flush \
                breeze blouse charge solid fish spread
                """
            
            return mnemonic.components(separatedBy: " ")
        },
        toSeed: { _ in
            let seedString = Data(
                base64Encoded: "9VDVOZZZOWWHpZtq1Ebridp3Qeux5C+HwiRR0g7Oi7HgnMs8Gfln83+/Q1NnvClcaSwM4ADFL1uZHxypEWlWXg=="
            )!// swiftlint:disable:this force_unwrapping
            
            return [UInt8](seedString)
        },
        asWords: { mnemonic in
            let mnemonic = """
                still champion voice habit trend flight \
                survey between bitter process artefact blind \
                carbon truly provide dizzy crush flush \
                breeze blouse charge solid fish spread
                """
            
            return mnemonic.components(separatedBy: " ")
        },
        isValid: { _ in }
    )
}
