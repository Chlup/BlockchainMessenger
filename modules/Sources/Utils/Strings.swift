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

// TODO: [#695] This should have a #DEBUG tag, but if so, it's not possible to compile this on release mode and submit it to testflight https://github.com/zcash/ZcashLightClientKit/issues/695
extension String {
    init<T>(dumping value: T) {
        var output = String()
        dump(value, to: &output)
        self.init(stringLiteral: output)
    }
}

extension String: Error {}

extension String {
    private static let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
    private static let phoneRegex = "^^\\+(?:[0-9]?){6,14}[0-9]$"

    public enum ValidationType: Equatable {
        case customFloatingPoint(NumberFormatter)
        case custom(String)
        case email
        case floatingPoint
        case maxLength(Int)
        case minLength(Int)
        case phoneNumber

        func isValid(text: String) -> Bool {
            switch self {
            case .customFloatingPoint(let numberFormatter):
                return text.validate(using: numberFormatter)

            case .custom(let regex):
                return text.validate(using: regex)

            case .email:
                return text.validate(using: .emailRegex)

            case .floatingPoint:
                return NumberFormatter.zcashNumberFormatter.number(from: text) != nil

            case .maxLength(let length):
                return text.count <= length && !text.isEmpty

            case .minLength(let length):
                return text.count >= length

            case .phoneNumber:
                return text.validate(using: .phoneRegex)
            }
        }
    }

    private func validate(using numberFormatter: NumberFormatter) -> Bool {
        numberFormatter.number(from: self) != nil
    }

    private func validate(using regex: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: regex) else { return false }

        return regex.firstMatch(
            in: self,
            options: [],
            range: NSRange(location: 0, length: self.utf16.count)
        ) != nil
    }

    public func isValid(for validationType: ValidationType?) -> Bool {
        guard let validationType else { return true }

        return validationType.isValid(text: self)
    }
}
