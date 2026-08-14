//
//  TipsView.swift
//  dailyplanner
//
//  Created by vili on 29.01.2026.
//

import SwiftUI
import StoreKit

struct TipsView: View {
    @State private var store = StoreManager.shared
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Header
                    VStack(spacing: 12) {
                        Text("💝")
                            .font(.system(size: 60))

                        Text("tips.header.title".localized)
                            .font(.title2.bold())

                        VStack(spacing: 10) {
                            Text("tips.header.intro".localized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            Text("tips.header.message".localized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            Text("tips.header.thanks".localized)
                                .font(.subheadline)
                                .foregroundStyle(.green)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 12)

                    // Products section
                    VStack(spacing: 10) {
                        // Header
                        VStack(spacing: 2) {
                            Text("tips.products.header".localized)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)

                        // Products
                        if store.products.isEmpty {
                            ProgressView()
                                .padding()
                        } else {
                            VStack(spacing: 16) {
                                ForEach(store.products, id: \.id) { product in
                                    TipButton(product: product, store: store)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Success/Error Messages
                    if case .purchased = store.purchaseState {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.green)

                            Text("tips.success.title".localized)
                                .font(.title3.bold())

                            Text("tips.success.message".localized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                    }

                    if case .failed(let error) = store.purchaseState {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.orange)

                            Text("tips.error.title".localized)
                                .font(.headline)

                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }

                    Spacer()
                }
            }
            .navigationTitle("tips.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                store.resetPurchaseState()
            }
            .onChange(of: store.purchaseState) { _, newState in
                if case .purchased = newState {
                    showConfetti = true
                    // Add haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }

            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
    }
}

struct TipButton: View {
    let product: Product
    let store: StoreManager

    private var emoji: String {
        if product.id == StoreManager.ProductID.coffee.rawValue {
            return "☕️"
        } else {
            return "🍕"
        }
    }

    var body: some View {
        Button {
            Task {
                await store.purchase(product)
            }
        } label: {
            HStack {
                Text(emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)

                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if case .purchasing = store.purchaseState {
                    ProgressView()
                } else {
                    Text(product.displayPrice)
                        .font(.headline)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(store.purchaseState == .purchasing)
    }
}

#Preview {
    TipsView()
}
