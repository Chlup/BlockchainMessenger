//
//  SwiftUIView.swift
//  
//
//  Created by Lukáš Korba on 25.11.2023.
//

import SwiftUI

import Generated

public struct NeumorphicShapeModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    public func body(content: Content) -> some View {
        content
            .background {
                Rectangle()
                    .foregroundStyle(
                        Asset.Colors.buttonBackground.color
                    )
                    .cornerRadius(cornerRadius)
                    .shadow(
                        color: .black.opacity(0.33),
                        radius: 6,
                        x: 6,
                        y: 6
                    )
                    .shadow(
                        color: Asset.Colors.screenBackgroundTopLeading.color.opacity(0.8),
                        radius: 6,
                        x: -6,
                        y: -6
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .inset(by: 0.5)
                            .stroke(
                                LinearGradient(
                                    stops: [
                                        Gradient.Stop(
                                            color: Asset.Colors.screenBackgroundTopLeading.color,
                                            location: 0.0
                                        ),
                                        Gradient.Stop(
                                            color: Asset.Colors.screenBackgroundBottomTrailing.color,
                                            location: 1.0
                                        ),
                                    ],
                                    startPoint: UnitPoint(x: 0.49, y: 0.01),
                                    endPoint: UnitPoint(x: 0.51, y: 0.99)
                                ),
                                lineWidth: 1
                            )
                        
                    )
            }
    }
}

extension View {
    public func neumorphicShape(cornerRadius: CGFloat = 43) -> some View {
        self.modifier(
            NeumorphicShapeModifier(cornerRadius: cornerRadius)
        )
    }
}

public struct NeumorphicButtonModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    public func body(content: Content) -> some View {
        content
            .font(.system(size: 16))
            .foregroundStyle(Asset.Colors.fontPrimary.color)
            .frame(height: 25)
            .frame(maxWidth: .infinity)
            .padding()
            .neumorphicShape()
    }
}

extension View {
    public func neumorphicButton(cornerRadius: CGFloat = 43) -> some View {
        self.modifier(
            NeumorphicButtonModifier(cornerRadius: cornerRadius)
        )
    }
}

#Preview {
    VStack {
        Text("hello")
            .foregroundStyle(.gray)
            .padding()
            .neumorphicShape()
            .padding()

        Text("hello")
            .foregroundStyle(.gray)
            .padding()
            .neumorphicShape(cornerRadius: 10)
    }
    .applyScreenBackground()
}
