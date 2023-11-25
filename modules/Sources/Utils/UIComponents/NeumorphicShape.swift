//
//  SwiftUIView.swift
//  
//
//  Created by Lukáš Korba on 25.11.2023.
//

import SwiftUI

import Generated

public struct NeumorphicShapeModifier<S>: ViewModifier where S: ShapeStyle {
    let cornerRadius: CGFloat
    let shapeStyle: S
    
    public func body(content: Content) -> some View {
        content
            .background {
                Rectangle()
                    .foregroundStyle(
                        shapeStyle
                    )
                    .cornerRadius(cornerRadius)
                    .shadow(
                        color: .black.opacity(0.7),
                        radius: 4,
                        x: 4,
                        y: 4
                    )
                    .shadow(
                        color: .white.opacity(0.15),
                        radius: 4,
                        x: -4,
                        y: -4
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
    public func neumorphicShape<S>(
        cornerRadius: CGFloat = 43,
        style: S = Asset.Colors.buttonBackground.color
    ) -> some View where S: ShapeStyle {
        self.modifier(
            NeumorphicShapeModifier(
                cornerRadius: cornerRadius,
                shapeStyle: style
            )
        )
    }
}

public struct NeumorphicButtonModifier<S>: ViewModifier where S: ShapeStyle {
    let cornerRadius: CGFloat
    let shapeStyle: S

    public func body(content: Content) -> some View {
        content
            .font(.system(size: 16))
            .foregroundStyle(Asset.Colors.fontPrimary.color)
            .frame(height: 25)
            .frame(maxWidth: .infinity)
            .padding()
            .neumorphicShape(style: shapeStyle)
    }
}

extension View {
    public func neumorphicButton<S>(
        cornerRadius: CGFloat = 43,
        style: S = Asset.Colors.buttonBackground.color
    ) -> some View where S: ShapeStyle {
        self.modifier(
            NeumorphicButtonModifier(
                cornerRadius: cornerRadius,
                shapeStyle: style
            )
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
