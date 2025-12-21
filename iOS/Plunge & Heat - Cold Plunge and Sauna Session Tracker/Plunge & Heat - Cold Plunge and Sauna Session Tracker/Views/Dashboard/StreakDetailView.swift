//
//  StreakDetailView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/21.
//

import SwiftUI

// MARK: - Streak Detail View

struct StreakDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Main streak display
                    streakHeroSection
                    
                    // Streak stats
                    statsGrid
                    
                    // Weekly activity
                    weeklyActivitySection
                    
                    // Tips for maintaining streak
                    tipsSection
                }
                .padding()
            }
        }
        .navigationTitle("Your Streak")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Hero Section
    
    private var streakHeroSection: some View {
        VStack(spacing: 16) {
            // Animated flame background
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.orange.opacity(0.3), .orange.opacity(0.05)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            VStack(spacing: 4) {
                Text("\(settings.currentStreak)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Day Streak")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            
            if settings.currentStreak > 0 {
                Text("Keep it up! 🔥")
                    .font(.headline)
                    .foregroundColor(.orange)
            } else {
                Text("Start your streak today!")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        HStack(spacing: 16) {
            StreakStatCard(
                icon: "trophy.fill",
                iconColor: .yellow,
                value: "\(settings.longestStreak)",
                label: "Best Streak"
            )
            
            StreakStatCard(
                icon: "calendar",
                iconColor: .cyan,
                value: "\(dataManager.statistics.totalSessions)",
                label: "Total Sessions"
            )
        }
    }
    
    // MARK: - Weekly Activity
    
    private var weeklyActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: -(6 - dayOffset), to: Date()) ?? Date()
                    let hasSession = hasSessionOnDate(date)
                    
                    VStack(spacing: 6) {
                        Text(dayAbbreviation(for: date))
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Circle()
                            .fill(hasSession ? Color.orange : Color.white.opacity(0.1))
                            .frame(width: 32, height: 32)
                            .overlay(
                                hasSession ?
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    : nil
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Tips Section
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streak Tips")
                .font(.headline)
                .foregroundColor(.white)
            
            StreakTipRow(icon: "clock", text: "Log sessions at the same time daily")
            StreakTipRow(icon: "bell", text: "Enable reminders to stay consistent")
            StreakTipRow(icon: "figure.mixed.cardio", text: "Even short sessions count!")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Helpers
    
    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
    
    private func hasSessionOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return dataManager.sessions.contains { session in
            calendar.isDate(session.date, inSameDayAs: date)
        }
    }
}

// MARK: - Streak Stat Card (Local component to avoid conflict)

private struct StreakStatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Streak Tip Row

private struct StreakTipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StreakDetailView()
    }
}
