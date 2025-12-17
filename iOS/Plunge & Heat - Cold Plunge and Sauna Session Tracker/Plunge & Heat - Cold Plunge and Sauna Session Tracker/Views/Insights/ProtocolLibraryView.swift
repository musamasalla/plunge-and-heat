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
    @State private var selectedCategory: ProtocolCategory?
    @State private var selectedProtocol: WellnessProtocol?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Category filter
                        categoryFilter
                        
                        // Protocols list
                        protocolsList
                    }
                    .padding()
                }
            }
            .navigationTitle("Protocol Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.coldPrimary)
                }
            }
            .sheet(item: $selectedProtocol) { protocol_ in
                ProtocolDetailView(protocol_: protocol_)
            }
        }
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    color: AppTheme.coldPrimary
                ) {
                    selectedCategory = nil
                }
                
                ForEach(ProtocolCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        color: category.color
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }
    
    // MARK: - Protocols List
    
    private var protocolsList: some View {
        VStack(spacing: 16) {
            ForEach(filteredProtocols) { protocol_ in
                ProtocolListCard(protocol_: protocol_) {
                    selectedProtocol = protocol_
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

// MARK: - Protocol List Card

struct ProtocolListCard: View {
    let protocol_: WellnessProtocol
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(protocol_.sessionType.primaryColor.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: protocol_.iconName)
                            .font(.title2)
                            .foregroundColor(protocol_.sessionType.primaryColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(protocol_.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if protocol_.isPremium {
                                PremiumBadge()
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Text(protocol_.category.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(protocol_.category.color.opacity(0.2))
                                .foregroundColor(protocol_.category.color)
                                .cornerRadius(4)
                            
                            Text(protocol_.sessionType.displayName)
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.textTertiary)
                }
                
                Text(protocol_.description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
                
                // Details
                HStack(spacing: 16) {
                    Label(protocol_.targetDuration.formatted, systemImage: "clock")
                    Label(protocol_.targetTemperature.formatted, systemImage: "thermometer.medium")
                    Label("\(protocol_.frequencyPerWeek)x/week", systemImage: "calendar")
                }
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusLarge)
        }
    }
}

// MARK: - Protocol Detail View

struct ProtocolDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let protocol_: WellnessProtocol
    
    @State private var showingStartSession = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Overview
                        overviewSection
                        
                        // Steps
                        stepsSection
                        
                        // Benefits
                        benefitsSection
                        
                        // Tips
                        tipsSection
                        
                        // Start button
                        startButton
                    }
                    .padding()
                }
            }
            .navigationTitle(protocol_.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.coldPrimary)
                }
            }
            .sheet(isPresented: $showingStartSession) {
                LogSessionView(sessionType: protocol_.sessionType)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(protocol_.sessionType.gradient)
                    .frame(width: 80, height: 80)
                
                Image(systemName: protocol_.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 8) {
                Text(protocol_.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(protocol_.category.color.opacity(0.2))
                    .foregroundColor(protocol_.category.color)
                    .cornerRadius(4)
                
                Text(protocol_.sessionType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(protocol_.sessionType.primaryColor.opacity(0.2))
                    .foregroundColor(protocol_.sessionType.primaryColor)
                    .cornerRadius(4)
            }
            
            Text(protocol_.description)
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Overview
    
    private var overviewSection: some View {
        HStack(spacing: 16) {
            OverviewCard(icon: "thermometer.medium", title: "Temperature", value: protocol_.targetTemperature.formatted)
            OverviewCard(icon: "clock", title: "Duration", value: protocol_.targetDuration.formatted)
            OverviewCard(icon: "calendar", title: "Frequency", value: "\(protocol_.frequencyPerWeek)x/week")
        }
    }
    
    // MARK: - Steps
    
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Steps")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(protocol_.steps) { step in
                StepRow(step: step, sessionType: protocol_.sessionType)
            }
        }
    }
    
    // MARK: - Benefits
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Benefits")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(protocol_.benefits, id: \.self) { benefit in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text(benefit)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusMedium)
        }
    }
    
    // MARK: - Tips
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(protocol_.tips, id: \.self) { tip in
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusMedium)
        }
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        Button(action: {
            HapticFeedback.medium()
            showingStartSession = true
        }) {
            HStack {
                Image(systemName: "play.fill")
                Text("Start This Protocol")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(protocol_.sessionType.gradient)
            .cornerRadius(AppTheme.cornerRadiusMedium)
        }
    }
}

// MARK: - Overview Card

struct OverviewCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.coldPrimary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
    }
}

// MARK: - Step Row

struct StepRow: View {
    let step: ProtocolStep
    let sessionType: SessionType
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(sessionType.primaryColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Text("\(step.order)")
                    .font(.headline)
                    .foregroundColor(sessionType.primaryColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(step.description)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                if let duration = step.durationSeconds {
                    Text("\(Int(duration))s")
                        .font(.caption)
                        .foregroundColor(sessionType.primaryColor)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
    }
}

// MARK: - Preview

#Preview {
    ProtocolLibraryView()
}
