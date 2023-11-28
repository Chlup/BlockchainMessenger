//
//  ScreenBackground.swift
//  secant-testnet
//
//  Created by Francisco Gindre on 10/18/21.
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

import SwiftUI
import Generated

public struct ScreenBackgroundModifier: ViewModifier {
    public func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                stops: [
                    Gradient.Stop(
                        color: Asset.Colors.screenBackgroundTopLeading.color,
                        location: 0.00
                    ),
                    Gradient.Stop(
                        color: Asset.Colors.screenBackgroundBottomTrailing.color,
                        location: 1.00
                    ),
                ],
                startPoint: UnitPoint(x: 0, y: 0.01),
                endPoint: UnitPoint(x: 1, y: 0.99)
            )
            .edgesIgnoringSafeArea(.all)
            
            content
        }
    }
}

extension View {
    public func applyScreenBackground() -> some View {
        self.modifier(
            ScreenBackgroundModifier()
        )
    }
}

struct ScreenBackground_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello")
        }
        .applyScreenBackground()
    }
}
