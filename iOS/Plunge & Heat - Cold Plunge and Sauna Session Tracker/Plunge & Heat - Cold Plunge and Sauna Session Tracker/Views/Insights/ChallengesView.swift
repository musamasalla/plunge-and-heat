//
//  ChallengesView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/18.
//

import SwiftUI

// MARK: - Challenges View

struct ChallengesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var selectedTab: ChallengeTab = .active
    @State private var animateCards = false
    
    enum ChallengeTab: String, CaseIterable {
        case active = "Active"
        case upcoming = "Upcoming"
        case completed = "Completed"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector
                    
                    // Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Featured challenge
                            if selectedTab == .active {
                                featuredChallengeCard
                            }
                            
                            // Challenge list
                            challengeList
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.coldPrimary)
                }
            }
            .onAppear {
                withAnimation(.spring().delay(0.2)) {
                    animateCards = true
                }
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ChallengeTab.allCases, id: \.self) { tab in
                Button(action: {
                    HapticFeedback.light()
                    withAnimation(.spring()) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTab == tab ? .white : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == tab ? AppTheme.coldPrimary : Color.clear
                        )
                }
            }
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Featured Challenge Card
    
    private var featuredChallengeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Featured Challenge")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if !subscriptionManager.isPremium {
                    Text("PREMIUM")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            
            let featured = Challenge.thirtyDayChallenge
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppTheme.coldPrimary.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: featured.iconName)
                            .font(.title2)
                            .foregroundColor(AppTheme.coldPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(featured.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            Label("\(featured.participants)", systemImage: "person.2.fill")
                            Label("\(featured.daysRemaining)d left", systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                // Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.surfaceBackground)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.coldPrimary)
                                .frame(width: geometry.size.width * CGFloat(featured.currentProgress) / CGFloat(featured.requirement.target))
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text("\(featured.currentProgress)/\(featured.requirement.target) days")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Spacer()
                        
                        Text("\(Int(Double(featured.currentProgress) / Double(featured.requirement.target) * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.coldPrimary)
                    }
                }
                
                Button(action: {
                    HapticFeedback.medium()
                    // Join challenge
                }) {
                    Text(featured.isJoined ? "View Progress" : "Join Challenge")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.coldPrimary)
                        .cornerRadius(12)
                }
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
                                colors: [AppTheme.coldPrimary.opacity(0.5), AppTheme.coldPrimary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Challenge List
    
    private var challengeList: some View {
        VStack(spacing: 16) {
            ForEach(Array(Challenge.allChallenges.enumerated()), id: \.element.id) { index, challenge in
                ChallengeCard(
                    challenge: challenge,
                    animate: animateCards,
                    delay: Double(index) * 0.1
                )
            }
        }
    }
}

// MARK: - Challenge Card

struct ChallengeCard: View {
    let challenge: Challenge
    let animate: Bool
    var delay: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(challenge.requirement.sessionType?.primaryColor.opacity(0.2) ?? AppTheme.coldPrimary.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: challenge.iconName)
                        .font(.title3)
                        .foregroundColor(challenge.requirement.sessionType?.primaryColor ?? AppTheme.coldPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Text("\(challenge.participants)")
                        .font(.caption)
                }
                .foregroundColor(AppTheme.textTertiary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(challenge.daysRemaining) days left")
                        .font(.caption)
                }
                .foregroundColor(AppTheme.textTertiary)
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.light()
                }) {
                    Text(challenge.isJoined ? "Joined" : "Join")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(challenge.isJoined ? .white : AppTheme.coldPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            challenge.isJoined ?
                            AppTheme.coldPrimary :
                            AppTheme.coldPrimary.opacity(0.2)
                        )
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
        .scaleEffect(animate ? 1 : 0.95)
        .opacity(animate ? 1 : 0)
        .animation(.spring().delay(delay), value: animate)
    }
}

// MARK: - Preview

#Preview {
    ChallengesView()
}
