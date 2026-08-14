//
//  ViewModifiers.swift
//  dailyplanner
//
//  Created by vili on 26.01.2026.
//

import SwiftUI

struct WiggleModifier: ViewModifier {
    let active: Bool

    @State private var rotation: Double = 0
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(active ? rotation : 0))
            .offset(x: active ? offset : 0, y: 0)
            .onChange(of: active) { _, newValue in
                if newValue {
                    startWiggle()
                } else {
                    rotation = 0
                    offset = 0
                }
            }
    }

    private func startWiggle() {
        // Hafif rotasyon animasyonu
        withAnimation(
            Animation.easeInOut(duration: 0.13)
                .repeatForever(autoreverses: true)
        ) {
            rotation = Double.random(in: -2.5...2.5)
        }

        // Hafif yatay hareket
        withAnimation(
            Animation.easeInOut(duration: 0.11)
                .repeatForever(autoreverses: true)
        ) {
            offset = CGFloat.random(in: -2...2)
        }
    }
}

extension View {
    func wiggle(active: Bool) -> some View {
        self.modifier(WiggleModifier(active: active))
    }
}
