//
//  DashboardView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var settings = SettingsManager.shared
    
    @State private var showingLogSession = false
    @State private var selectedSessionType: SessionType?
    @State private var showingPaywall = false
    @State private var animateGradient = false
    @State private var pulseAnimation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background
                animatedBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Header with greeting
                        headerSection
                        
                        // Quick stats ribbon
                        quickStatsRibbon
                        
                        // Session buttons - the main attraction
                        sessionButtonsSection
                        
                        // Today's progress ring
                        todayProgressSection
                        
                        // Recent sessions
                        if !dataManager.todaysSessions.isEmpty {
                            recentSessionsSection
                        }
                        
                        // Motivational quote or tip
                        motivationalSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    streakBadge
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    premiumButton
                }
            }
            .sheet(isPresented: $showingLogSession) {
                if let type = selectedSessionType {
                    LogSessionView(sessionType: type)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
    
    // MARK: - Animated Background
    
    private var animatedBackground: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            // Floating orbs
            Circle()
                .fill(AppTheme.coldPrimary.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animateGradient ? -50 : 50, y: animateGradient ? -100 : 100)
            
            Circle()
                .fill(AppTheme.heatPrimary.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: animateGradient ? 100 : -50, y: animateGradient ? 200 : 50)
            
            Circle()
                .fill(AppTheme.coldSecondary.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .offset(x: animateGradient ? -80 : 80, y: animateGradient ? 300 : 400)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Ready to challenge yourself?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }
    
    // MARK: - Quick Stats Ribbon
    
    private var quickStatsRibbon: some View {
        HStack(spacing: 0) {
            QuickStatItem(
                value: "\(dataManager.thisWeeksSessions.count)",
                label: "This Week",
                icon: "calendar",
                color: AppTheme.coldPrimary
            )
            
            Divider()
                .background(Color.white.opacity(0.2))
                .frame(height: 40)
            
            QuickStatItem(
                value: "\(dataManager.statistics.totalSessions)",
                label: "Total",
                icon: "number.circle",
                color: .purple
            )
            
            Divider()
                .background(Color.white.opacity(0.2))
                .frame(height: 40)
            
            QuickStatItem(
                value: formatDuration(dataManager.statistics.averageDuration),
                label: "Avg Time",
                icon: "clock",
                color: .green
            )
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Session Buttons Section
    
    private var sessionButtonsSection: some View {
        VStack(spacing: 16) {
            Text("Start a Session")
                .font(.headline)
                .foregroundColor(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                // Cold Plunge Button
                GlowingSessionButton(
                    sessionType: .coldPlunge,
                    isPulsing: pulseAnimation
                ) {
                    startSession(.coldPlunge)
                }
                
                // Sauna Button
                GlowingSessionButton(
                    sessionType: .sauna,
                    isPulsing: pulseAnimation
                ) {
                    startSession(.sauna)
                }
            }
        }
    }
    
    // MARK: - Today's Progress Section
    
    private var todayProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(dataManager.todaysSessions.count) sessions")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            HStack(spacing: 24) {
                // Cold progress
                TodayProgressRing(
                    type: .coldPlunge,
                    count: dataManager.todaysSessions.filter { $0.type == .coldPlunge }.count,
                    goal: 1
                )
                
                // Sauna progress
                TodayProgressRing(
                    type: .sauna,
                    count: dataManager.todaysSessions.filter { $0.type == .sauna }.count,
                    goal: 1
                )
                
                // Total time
                VStack(spacing: 8) {
                    Text(formatDuration(dataManager.todaysSessions.reduce(0) { $0 + $1.duration }))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Total Time")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.cardBackground)
            )
        }
    }
    
    // MARK: - Recent Sessions Section
    
    private var recentSessionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: HistoryView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.coldPrimary)
                }
            }
            
            ForEach(dataManager.todaysSessions.prefix(3)) { session in
                ModernSessionRow(session: session)
            }
        }
    }
    
    // MARK: - Motivational Section
    
    private var motivationalSection: some View {
        VStack(spacing: 12) {
            if !settings.safetyTipsShown {
                SafetyTipCard {
                    settings.safetyTipsShown = true
                }
            } else {
                MotivationalCard()
            }
        }
    }
    
    // MARK: - Toolbar Items
    
    private var streakBadge: some View {
        NavigationLink(destination: StreakDetailView()) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14, weight: .semibold))
                
                Text("\(settings.currentStreak)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
    
    private var premiumButton: some View {
        Button(action: { showingPaywall = true }) {
            if SubscriptionManager.shared.isPremium {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 18))
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text("PRO")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.yellow)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.yellow.opacity(0.2))
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startSession(_ type: SessionType) {
        if settings.canLogMoreSessions {
            HapticFeedback.medium()
            selectedSessionType = type
            showingLogSession = true
        } else {
            showingPaywall = true
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", secs))"
        }
        return "\(secs)s"
    }
}

// MARK: - Glowing Session Button

struct GlowingSessionButton: View {
    let sessionType: SessionType
    let isPulsing: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(sessionType.gradient)
                        .frame(width: 70, height: 70)
                        .blur(radius: isPulsing ? 20 : 15)
                        .opacity(isPulsing ? 0.8 : 0.5)
                    
                    // Icon circle
                    Circle()
                        .fill(sessionType.gradient)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: sessionType.icon)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        )
                        .shadow(color: sessionType.primaryColor.opacity(0.5), radius: 10, y: 5)
                }
                
                Text(sessionType.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(sessionType == .coldPlunge ? "Ice bath" : "Heat therapy")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [sessionType.primaryColor.opacity(0.5), sessionType.primaryColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: sessionType.primaryColor.opacity(0.2), radius: 15, y: 8)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Quick Stat Item

struct QuickStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Today Progress Ring

struct TodayProgressRing: View {
    let type: SessionType
    let count: Int
    let goal: Int
    
    var progress: Double {
        min(Double(count) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(type.primaryColor.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(type.gradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(type.primaryColor)
            }
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Modern Session Row

struct ModernSessionRow: View {
    let session: Session
    
    var body: some View {
        HStack(spacing: 14) {
            // Type Icon
            ZStack {
                Circle()
                    .fill(session.type.gradient)
                    .frame(width: 44, height: 44)
                
                Image(systemName: session.type.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(session.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Label(session.durationFormatted, systemImage: "clock")
                    
                    if let temp = session.temperatureFormatted {
                        Label(temp, systemImage: "thermometer.medium")
                    }
                }
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Time
            Text(formatTime(session.date))
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Safety Tip Card

struct SafetyTipCard: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("Safety First")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                        .padding(8)
                        .background(Circle().fill(AppTheme.surfaceBackground))
                }
            }
            
            Text("Start with shorter sessions (1-2 min for cold, 10-15 min for sauna). Listen to your body and exit immediately if you feel dizzy or unwell.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Motivational Card

struct MotivationalCard: View {
    private static let quotes = [
        ("The cold doesn't build character, it reveals it.", "Unknown"),
        ("Embrace the discomfort. That's where growth happens.", "Wim Hof"),
        ("Your body can withstand almost anything. It's your mind you have to convince.", "Unknown"),
        ("The obstacle is the way.", "Marcus Aurelius"),
        ("What stands in the way becomes the way.", "Marcus Aurelius"),
        ("Discipline is the bridge between goals and accomplishment.", "Jim Rohn"),
        ("The body benefits from movement, and the mind benefits from stillness.", "Sakyong Mipham")
    ]
    
    @State private var selectedQuote: (String, String) = Self.quotes.randomElement() ?? Self.quotes[0]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.title2)
                    .foregroundColor(AppTheme.coldPrimary)
                
                Spacer()
            }
            
            Text(selectedQuote.0)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineSpacing(4)
            
            Text("— \(selectedQuote.1)")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.coldPrimary.opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
