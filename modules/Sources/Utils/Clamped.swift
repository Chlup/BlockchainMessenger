//
//  Clamped.swift
//  secant-testnet
//
//  Created by Francisco Gindre on 10/20/21.
//
// credits: https://iteo.medium.com/swift-property-wrappers-how-to-use-them-right-77095817d1b
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

/**
Limits a value to an enclosing range
*/
@propertyWrapper
public struct Clamped<Value: Comparable> {
    var value: Value
    let range: ClosedRange<Value>
    public var wrappedValue: Value {
        get { value }
        set { value = clamp(newValue, using: range) }
    }

    public init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.value = wrappedValue
        self.range = range
        
        value = clamp(wrappedValue, using: range)
    }
    
    private func clamp(_ value: Value, using range: ClosedRange<Value>) -> Value {
        min(range.upperBound, max(range.lowerBound, wrappedValue))
    }
}
