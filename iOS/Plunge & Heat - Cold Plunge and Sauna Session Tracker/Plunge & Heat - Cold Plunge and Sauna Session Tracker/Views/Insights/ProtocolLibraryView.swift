//
//  ProtocolLibraryView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

// MARK: - Protocol Library View

struct ProtocolLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: ProtocolCategory? = nil
    @State private var selectedProtocol: WellnessProtocol?
    @State private var animateCards = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Category filter
                        categoryFilter
                        
                        // Featured protocol
                        if selectedCategory == nil {
                            featuredSection
                        }
                        
                        // Protocol grid
                        protocolGrid
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Protocols")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.coldPrimary)
                }
            }
            .sheet(item: $selectedProtocol) { proto in
                ProtocolDetailView(protocol: proto)
            }
            .onAppear {
                withAnimation(.spring().delay(0.2)) {
                    animateCards = true
                }
            }
        }
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    color: .purple
                ) {
                    HapticFeedback.light()
                    withAnimation(.spring()) {
                        selectedCategory = nil
                    }
                }
                
                ForEach(ProtocolCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        color: category.color
                    ) {
                        HapticFeedback.light()
                        withAnimation(.spring()) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Featured Section
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Featured")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            FeaturedProtocolCard(protocol: .wimHofMethod) {
                selectedProtocol = .wimHofMethod
            }
        }
    }
    
    // MARK: - Protocol Grid
    
    private var protocolGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Protocols")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(Array(filteredProtocols.enumerated()), id: \.element.id) { index, proto in
                    ProtocolCard(protocol: proto, animate: animateCards, delay: Double(index) * 0.05) {
                        selectedProtocol = proto
                    }
                }
            }
        }
    }
    
    private var filteredProtocols: [WellnessProtocol] {
        if let category = selectedCategory {
            return WellnessProtocol.allProtocols.filter { $0.category == category }
        }
        return WellnessProtocol.allProtocols
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? color : AppTheme.cardBackground)
                )
        }
    }
}

// MARK: - Featured Protocol Card

struct FeaturedProtocolCard: View {
    let `protocol`: WellnessProtocol
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(`protocol`.category.color.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: `protocol`.iconName)
                            .font(.title2)
                            .foregroundColor(`protocol`.category.color)
                    }
                    
                    Spacer()
                    
                    // Category badge
                    Text(`protocol`.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(`protocol`.category.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(`protocol`.category.color.opacity(0.2))
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(`protocol`.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(`protocol`.description)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 16) {
                    Label("\(`protocol`.targetDuration.formatted)", systemImage: "clock")
                    Label("\(`protocol`.steps.count) steps", systemImage: "list.number")
                }
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [`protocol`.category.color.opacity(0.5), `protocol`.category.color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}

// MARK: - Protocol Card

struct ProtocolCard: View {
    let `protocol`: WellnessProtocol
    let animate: Bool
    var delay: Double = 0
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(`protocol`.category.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: `protocol`.iconName)
                        .font(.title3)
                        .foregroundColor(`protocol`.category.color)
                }
                
                Text(`protocol`.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(`protocol`.category.rawValue)
                        .font(.caption2)
                        .foregroundColor(`protocol`.category.color)
                    
                    Spacer()
                    
                    Image(systemName: `protocol`.sessionType.icon)
                        .font(.caption)
                        .foregroundColor(`protocol`.sessionType.primaryColor)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.cardBackground)
            )
        }
        .scaleEffect(animate ? 1 : 0.9)
        .opacity(animate ? 1 : 0)
        .animation(.spring().delay(delay), value: animate)
    }
}

// MARK: - Protocol Detail View

struct ProtocolDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let `protocol`: WellnessProtocol
    
    @State private var showSteps = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Benefits
                        benefitsSection
                        
                        // Steps
                        stepsSection
                        
                        // Tips
                        if !`protocol`.tips.isEmpty {
                            tipsSection
                        }
                        
                        // Start button
                        startButton
                    }
                    .padding(.horizontal, 20)
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
            .onAppear {
                withAnimation(.spring().delay(0.3)) {
                    showSteps = true
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(`protocol`.category.color.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: `protocol`.iconName)
                    .font(.system(size: 44))
                    .foregroundColor(`protocol`.category.color)
            }
            
            VStack(spacing: 8) {
                Text(`protocol`.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(`protocol`.description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 24) {
                DetailInfoBadge(icon: "clock.fill", value: `protocol`.targetDuration.formatted, color: .blue)
                DetailInfoBadge(icon: "list.number", value: "\(`protocol`.steps.count) steps", color: .purple)
                DetailInfoBadge(icon: "chart.bar.fill", value: `protocol`.category.rawValue, color: `protocol`.category.color)
            }
        }
        .padding(.top, 20)
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Benefits")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(`protocol`.benefits, id: \.self) { benefit in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text(benefit)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
    }
    
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Steps")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(Array(`protocol`.steps.enumerated()), id: \.offset) { index, step in
                ProtocolStepRow(
                    stepNumber: index + 1,
                    step: step,
                    color: `protocol`.category.color
                )
                .opacity(showSteps ? 1 : 0)
                .offset(x: showSteps ? 0 : -50)
                .animation(.spring().delay(Double(index) * 0.1), value: showSteps)
            }
        }
    }
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Tips")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ForEach(`protocol`.tips, id: \.self) { tip in
                Text("• \(tip)")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var startButton: some View {
        Button(action: {
            HapticFeedback.medium()
            dismiss()
        }) {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Protocol")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(`protocol`.category.color)
            .cornerRadius(16)
            .shadow(color: `protocol`.category.color.opacity(0.4), radius: 15, y: 8)
        }
    }
}

// MARK: - Detail Info Badge

struct DetailInfoBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Protocol Step Row

struct ProtocolStepRow: View {
    let stepNumber: Int
    let step: ProtocolStep
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                
                Text("\(stepNumber)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(step.description)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                if let duration = step.durationSeconds, duration > 0 {
                    let mins = Int(duration) / 60
                    let secs = Int(duration) % 60
                    Text(mins > 0 ? "\(mins) min \(secs) sec" : "\(secs) sec")
                        .font(.caption)
                        .foregroundColor(color)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
        )
    }
}

// MARK: - Preview

#Preview {
    ProtocolLibraryView()
}
