//
//  StoreManager.swift
//  dailyplanner
//
//  Created by vili on 29.01.2026.
//

import StoreKit
import SwiftUI

@MainActor
@Observable
class StoreManager {
    static let shared = StoreManager()

    // Product IDs
    enum ProductID: String {
        case coffee = "com.acar.dailyplanner.tip.coffee"
        case lunch = "com.acar.dailyplanner.tip.lunch"

        var emoji: String {
            switch self {
            case .coffee: return "☕️"
            case .lunch: return "🍕"
            }
        }
    }

    private(set) var products: [Product] = []
    private(set) var purchaseState: PurchaseState = .idle

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        case failed(Error)

        static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.purchasing, .purchasing), (.purchased, .purchased):
                return true
            case (.failed, .failed):
                return true
            default:
                return false
            }
        }
    }

    private init() {
        Task {
            await loadProducts()
        }
    }

    func loadProducts() async {
        do {
            let productIds = [ProductID.coffee.rawValue, ProductID.lunch.rawValue]
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async {
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                switch verification {
                case .verified(let transaction):
                    // Transaction is verified, finish it
                    await transaction.finish()
                    purchaseState = .purchased

                case .unverified:
                    purchaseState = .failed(NSError(domain: "StoreKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transaction could not be verified"]))
                }

            case .pending:
                purchaseState = .idle

            case .userCancelled:
                purchaseState = .idle

            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error)
        }
    }

    func resetPurchaseState() {
        purchaseState = .idle
    }
}
