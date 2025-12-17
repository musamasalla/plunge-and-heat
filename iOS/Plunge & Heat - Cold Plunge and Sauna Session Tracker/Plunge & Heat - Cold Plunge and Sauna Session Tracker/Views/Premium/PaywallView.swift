//
//  PaywallView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI
import StoreKit

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var animateGradient = false
    @State private var showFeatures = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium gradient background
                premiumBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Header with crown
                        headerSection
                        
                        // Feature list
                        featuresSection
                        
                        // Pricing cards
                        pricingSection
                        
                        // Purchase button
                        purchaseButton
                        
                        // Restore & Legal
                        footerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
            withAnimation(.spring().delay(0.3)) {
                showFeatures = true
            }
            // Select default product
            if let yearly = subscriptionManager.yearlyProduct {
                selectedProduct = yearly
            } else if let monthly = subscriptionManager.monthlyProduct {
                selectedProduct = monthly
            }
        }
    }
    
    // MARK: - Premium Background
    
    private var premiumBackground: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            // Golden gradient orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 2)
                .offset(x: animateGradient ? -50 : 50, y: animateGradient ? -150 : -100)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 2)
                .offset(x: animateGradient ? 80 : -30, y: animateGradient ? 400 : 350)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Crown icon with glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .blur(radius: 30)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .shadow(color: Color.orange.opacity(0.5), radius: 15, y: 8)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Unlock Premium")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Take your practice to the next level")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            ForEach(Array(PremiumFeature.allCases.enumerated()), id: \.element) { index, feature in
                PremiumFeatureRow(feature: feature)
                    .offset(x: showFeatures ? 0 : -100)
                    .opacity(showFeatures ? 1 : 0)
                    .animation(.spring().delay(Double(index) * 0.08), value: showFeatures)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.1), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                    .padding()
            } else {
                // Yearly (Best Value)
                if let yearly = subscriptionManager.yearlyProduct {
                    PricingCard(
                        product: yearly,
                        isSelected: selectedProduct?.id == yearly.id,
                        isBestValue: true
                    ) {
                        HapticFeedback.light()
                        withAnimation(.spring()) {
                            selectedProduct = yearly
                        }
                    }
                }
                
                // Monthly
                if let monthly = subscriptionManager.monthlyProduct {
                    PricingCard(
                        product: monthly,
                        isSelected: selectedProduct?.id == monthly.id,
                        isBestValue: false
                    ) {
                        HapticFeedback.light()
                        withAnimation(.spring()) {
                            selectedProduct = monthly
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        Button(action: purchase) {
            HStack(spacing: 12) {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "lock.open.fill")
                        .font(.headline)
                    Text("Unlock Premium")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color.yellow, Color.orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.orange.opacity(0.4), radius: 15, y: 8)
        }
        .disabled(isPurchasing || selectedProduct == nil)
        .opacity(selectedProduct == nil ? 0.6 : 1)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            // Restore purchases
            Button(action: restorePurchases) {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            // Legal text
            VStack(spacing: 4) {
                Text("Subscription auto-renews. Cancel anytime.")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textTertiary)
                
                HStack(spacing: 16) {
                    Link("Privacy Policy", destination: URL(string: "https://plungeheat.app/privacy")!)
                    Text("•")
                    Link("Terms of Use", destination: URL(string: "https://plungeheat.app/terms")!)
                }
                .font(.caption2)
                .foregroundColor(AppTheme.textTertiary)
            }
        }
    }
    
    // MARK: - Actions
    
    private func purchase() {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        HapticFeedback.medium()
        
        Task {
            do {
                let success = try await subscriptionManager.purchase(product)
                if success {
                    HapticFeedback.success()
                    dismiss()
                }
            } catch {
                HapticFeedback.error()
            }
            isPurchasing = false
        }
    }
    
    private func restorePurchases() {
        Task {
            try? await subscriptionManager.restorePurchases()
            if subscriptionManager.isPremium {
                HapticFeedback.success()
                dismiss()
            }
        }
    }
}

// MARK: - Premium Feature Row

struct PremiumFeatureRow: View {
    let feature: PremiumFeature
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(featureColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: feature.iconName)
                    .font(.title3)
                    .foregroundColor(featureColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
    
    private var featureColor: Color {
        switch feature {
        case .unlimitedSessions: return .purple
        case .fullHistory: return .blue
        case .charts: return .green
        case .healthInsights: return .pink
        case .protocols: return .orange
        case .exportData: return .cyan
        case .cloudSync: return .indigo
        }
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if isBestValue {
                    HStack {
                        Spacer()
                        Text("BEST VALUE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let trial = product.trialDescription {
                            Text(trial)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(product.periodDescription)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .yellow : AppTheme.textTertiary)
                        .padding(.leading, 8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ?
                                LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [AppTheme.textTertiary.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
