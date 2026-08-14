//
//  ConfettiView.swift
//  dailyplanner
//
//  Created by vili on 30.01.2026.
//

import SwiftUI

struct ConfettiView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                ConfettiPiece(animate: animate)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    let animate: Bool

    // Random properties for each piece
    private let color: Color = [.red, .blue, .green, .yellow, .orange, .pink, .purple].randomElement()!
    private let startX: CGFloat = CGFloat.random(in: -20...UIScreen.main.bounds.width + 20)
    private let startY: CGFloat = CGFloat.random(in: -50...0)
    private let endY: CGFloat = UIScreen.main.bounds.height + 50
    private let endX: CGFloat = CGFloat.random(in: -100...100)
    private let duration: Double = Double.random(in: 2.0...4.0)
    private let delay: Double = Double.random(in: 0...0.5)
    private let rotation: Double = Double.random(in: 0...720)
    private let size: CGFloat = CGFloat.random(in: 4...12)

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
            .cornerRadius(2)
            .position(
                x: animate ? startX + endX : startX,
                y: animate ? endY : startY
            )
            .rotationEffect(.degrees(animate ? rotation : 0))
            .opacity(animate ? 0 : 1)
            .animation(
                .easeIn(duration: duration)
                    .delay(delay),
                value: animate
            )
    }
}

#Preview {
    ConfettiView()
}
