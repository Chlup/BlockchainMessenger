//
//  QRCodeGenerator.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 04.07.2022.
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
import Combine
import CoreImage.CIFilterBuiltins
import SwiftUI

public enum QRCodeGenerator {
    public enum QRCodeError: Error {
        case failedToGenerate
    }
    
    public static func generate(from string: String) -> Future<CGImage, QRCodeError> {
        Future<CGImage, QRCodeError> { promise in
            DispatchQueue.global().async {
                guard let image = generate(from: string) else {
                    promise(.failure(QRCodeGenerator.QRCodeError.failedToGenerate))
                    return
                }
                
                return promise(.success(image))
            }
        }
    }
    
    public static func generate(from string: String, scale: CGFloat = 15) -> CGImage? {
        let data = string.data(using: String.Encoding.utf8)
        
        let context = CIContext()
        let filter = CoreImage.CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        
        guard let output = filter.outputImage?.transformed(by: transform) else {
            return nil
        }
        
        return context.createCGImage(output, from: output.extent)
    }
}
