//
//  ScreenBackground.swift
//  secant-testnet
//
//  Created by Francisco Gindre on 10/18/21.
//

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
