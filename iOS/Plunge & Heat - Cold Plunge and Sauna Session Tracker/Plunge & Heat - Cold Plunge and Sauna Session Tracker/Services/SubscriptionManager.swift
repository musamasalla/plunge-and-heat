//
//  SubscriptionManager.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import Foundation
import StoreKit
import SwiftUI
import Combine

// MARK: - Subscription Manager

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Product IDs
    
    enum ProductID {
        static let monthlyPremium = "com.plungeheat.premium.monthly"
        static let yearlyPremium = "com.plungeheat.premium.yearly"
    }
    
    // MARK: - Published Properties
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    
    var isPremium: Bool {
        !purchasedProductIDs.isEmpty || SettingsManager.shared.isPremiumUser
    }
    
    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthlyPremium }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id == ProductID.yearlyPremium }
    }
    
    // MARK: - Initialization
    
    private init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
            await listenForTransactions()
        }
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        
        do {
            let productIDs = [ProductID.monthlyPremium, ProductID.yearlyPremium]
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedProducts()
                await transaction.finish()
                isLoading = false
                return true
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                isLoading = false
                return false
                
            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Update Purchased Products
    
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    purchasedProductIDs.insert(transaction.productID)
                    SettingsManager.shared.isPremiumUser = true
                } else {
                    purchasedProductIDs.remove(transaction.productID)
                }
            }
        }
        
        // Update settings manager
        SettingsManager.shared.isPremiumUser = !purchasedProductIDs.isEmpty
    }
    
    // MARK: - Listen for Transactions
    
    func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await updatePurchasedProducts()
                await transaction.finish()
            }
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        isLoading = true
        
        try await AppStore.sync()
        await updatePurchasedProducts()
        
        isLoading = false
    }
    
    // MARK: - Check Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Premium Features Check
    
    func canAccess(feature: PremiumFeature) -> Bool {
        switch feature {
        case .unlimitedSessions:
            return isPremium || SettingsManager.shared.totalSessionsLogged < SettingsManager.shared.freeSessionLimit
        case .fullHistory:
            return isPremium
        case .charts:
            return isPremium
        case .healthInsights:
            return isPremium
        case .protocols:
            return isPremium
        case .exportData:
            return isPremium
        case .cloudSync:
            return isPremium
        }
    }
}

// MARK: - Premium Feature

enum PremiumFeature: String, CaseIterable {
    case unlimitedSessions = "Unlimited Sessions"
    case fullHistory = "Full History Access"
    case charts = "Charts & Analytics"
    case healthInsights = "Health Insights"
    case protocols = "Protocol Library"
    case exportData = "Export Data"
    case cloudSync = "Cloud Sync"
    
    var description: String {
        switch self {
        case .unlimitedSessions:
            return "Log unlimited sessions without restrictions"
        case .fullHistory:
            return "Access your complete session history"
        case .charts:
            return "View detailed charts and progress tracking"
        case .healthInsights:
            return "See correlations with your health data"
        case .protocols:
            return "Access expert wellness protocols"
        case .exportData:
            return "Export your data as CSV"
        case .cloudSync:
            return "Sync across all your devices"
        }
    }
    
    var iconName: String {
        switch self {
        case .unlimitedSessions: return "infinity"
        case .fullHistory: return "calendar"
        case .charts: return "chart.bar.fill"
        case .healthInsights: return "heart.text.square.fill"
        case .protocols: return "list.bullet.clipboard.fill"
        case .exportData: return "square.and.arrow.up"
        case .cloudSync: return "icloud.fill"
        }
    }
}

// MARK: - Subscription Error

enum SubscriptionError: Error {
    case verificationFailed
    case purchaseFailed
    case productNotFound
}

// MARK: - Pricing Display Helper

extension Product {
    var displayPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceFormatStyle.locale
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
    }
    
    var periodDescription: String {
        guard let subscription = subscription else { return "" }
        
        switch subscription.subscriptionPeriod.unit {
        case .month:
            if subscription.subscriptionPeriod.value == 1 {
                return "per month"
            }
            return "per \(subscription.subscriptionPeriod.value) months"
        case .year:
            if subscription.subscriptionPeriod.value == 1 {
                return "per year"
            }
            return "per \(subscription.subscriptionPeriod.value) years"
        case .week:
            return "per week"
        case .day:
            return "per day"
        @unknown default:
            return ""
        }
    }
    
    var hasFreeTrial: Bool {
        subscription?.introductoryOffer?.type == .introductory
    }
    
    var trialDescription: String? {
        guard let trial = subscription?.introductoryOffer,
              trial.type == .introductory else { return nil }
        
        let period = trial.period
        switch period.unit {
        case .day:
            return "\(period.value)-day free trial"
        case .week:
            return "\(period.value)-week free trial"
        case .month:
            return "\(period.value)-month free trial"
        case .year:
            return "\(period.value)-year free trial"
        @unknown default:
            return nil
        }
    }
}
