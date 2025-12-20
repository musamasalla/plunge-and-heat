//
//  InsightsView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI
import Charts

// MARK: - Insights View

struct InsightsView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var animateCards = false
    @State private var showingProtocolLibrary = false
    @State private var showingGoalsView = false
    @State private var showingChallengesView = false
    @State private var showingBreathingGuide = false
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Health Metrics Section
                        healthMetricsSection
                        
                        // Quick Actions
                        quickActionsSection
                        
                        // Weekly Trend Chart
                        weeklyTrendSection
                        
                        // Achievements Showcase
                        achievementsSection
                        
                        // Active Challenges
                        challengesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Insights")
            .sheet(isPresented: $showingProtocolLibrary) {
                ProtocolLibraryView()
            }
            .sheet(isPresented: $showingGoalsView) {
                GoalsView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingChallengesView) {
                ChallengesView()
            }
            .sheet(isPresented: $showingBreathingGuide) {
                BreathingSessionView()
            }
            .onAppear {
                withAnimation(.spring().delay(0.2)) {
                    animateCards = true
                }
                loadHealthData()
            }
        }
    }
    
    // MARK: - Health Metrics Section
    
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Health Metrics", icon: "heart.text.square.fill", color: .pink)
            
            if healthKit.isAuthorized {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    HealthMetricCard(
                        title: "HRV",
                        value: healthKit.latestHRV.map { "\(Int($0))" } ?? "--",
                        unit: "ms",
                        icon: "waveform.path.ecg",
                        color: .purple,
                        trend: .up,
                        animate: animateCards
                    )
                    
                    HealthMetricCard(
                        title: "Resting HR",
                        value: healthKit.restingHeartRate.map { "\(Int($0))" } ?? "--",
                        unit: "bpm",
                        icon: "heart.fill",
                        color: .red,
                        trend: .stable,
                        animate: animateCards
                    )
                    
                    HealthMetricCard(
                        title: "Sessions",
                        value: "\(dataManager.thisWeeksSessions.count)",
                        unit: "this week",
                        icon: "flame.fill",
                        color: .orange,
                        trend: .up,
                        animate: animateCards
                    )
                    
                    HealthMetricCard(
                        title: "Avg Duration",
                        value: formatDuration(dataManager.statistics.averageDuration),
                        unit: "",
                        icon: "clock.fill",
                        color: AppTheme.coldPrimary,
                        trend: .up,
                        animate: animateCards
                    )
                }
            } else {
                ConnectHealthCard {
                    Task {
                        try? await healthKit.requestAuthorization()
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            QuickActionCard(
                title: "Protocols",
                icon: "list.bullet.clipboard.fill",
                color: .orange,
                animate: animateCards,
                delay: 0.1
            ) {
                showingProtocolLibrary = true
            }
            
            QuickActionCard(
                title: "Goals",
                icon: "target",
                color: .green,
                animate: animateCards,
                delay: 0.15
            ) {
                showingGoalsView = true
            }
            
            QuickActionCard(
                title: "Breathe",
                icon: "wind",
                color: AppTheme.coldPrimary,
                animate: animateCards,
                delay: 0.2
            ) {
                showingBreathingGuide = true
            }
        }
    }
    
    // MARK: - Weekly Trend Section
    
    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "This Week", icon: "chart.line.uptrend.xyaxis", color: .green)
            
            VStack(spacing: 16) {
                // Mini chart
                if !dataManager.thisWeeksSessions.isEmpty {
                    WeeklyMiniChart(sessions: dataManager.thisWeeksSessions)
                        .frame(height: 120)
                } else {
                    EmptyChartPlaceholder()
                }
                
                // Stats row
                HStack(spacing: 0) {
                    WeekStatItem(
                        value: "\(dataManager.thisWeeksSessions.filter { $0.type == .coldPlunge }.count)",
                        label: "Cold",
                        color: AppTheme.coldPrimary
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .frame(height: 40)
                    
                    WeekStatItem(
                        value: "\(dataManager.thisWeeksSessions.filter { $0.type == .sauna }.count)",
                        label: "Sauna",
                        color: AppTheme.heatPrimary
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .frame(height: 40)
                    
                    WeekStatItem(
                        value: formatDuration(dataManager.thisWeeksSessions.reduce(0) { $0 + $1.duration }),
                        label: "Total",
                        color: .white
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.cardBackground)
            )
        }
    }
    
    // MARK: - Achievements Section
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "Achievements", icon: "trophy.fill", color: .yellow)
                
                Spacer()
                
                NavigationLink(destination: GoalsView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.coldPrimary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(dataManager.achievements.prefix(5)) { achievement in
                        AchievementBadge(achievement: achievement, animate: animateCards)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Challenges Section
    
    private var challengesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "Challenges", icon: "flag.fill", color: .blue)
                
                Spacer()
                
                Button(action: { showingChallengesView = true }) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.coldPrimary)
                }
            }
            
            if dataManager.joinedChallenges.isEmpty {
                JoinChallengeCard {
                    showingChallengesView = true
                }
            } else {
                ForEach(dataManager.joinedChallenges.prefix(2)) { challenge in
                    ChallengeProgressCard(challenge: challenge)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func loadHealthData() {
        Task {
            try? await healthKit.fetchLatestHeartRate()
            try? await healthKit.fetchLatestHRV()
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        if mins < 60 {
            return "\(mins)m"
        }
        let hours = mins / 60
        let remainingMins = mins % 60
        return "\(hours)h \(remainingMins)m"
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Health Metric Card

struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    let animate: Bool
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(animate ? 1 : 0.9)
        .opacity(animate ? 1 : 0)
    }
}

// MARK: - Connect Health Card

struct ConnectHealthCard: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 44))
                .foregroundColor(.pink)
            
            VStack(spacing: 8) {
                Text("Connect Apple Health")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("See how cold and heat therapy affects your heart rate and HRV")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                Text("Connect")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.pink, .red], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
        )
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    var isPremium: Bool = false
    let animate: Bool
    var delay: Double = 0
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                HStack(spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    if isPremium {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
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

// MARK: - Weekly Mini Chart

struct WeeklyMiniChart: View {
    let sessions: [Session]
    
    var body: some View {
        Chart {
            ForEach(chartData, id: \.day) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Sessions", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: item.hasBoth ? [AppTheme.coldPrimary, AppTheme.heatPrimary] :
                               item.hasCold ? [AppTheme.coldPrimary, AppTheme.coldSecondary] :
                               [AppTheme.heatPrimary, AppTheme.heatSecondary],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(AppTheme.textTertiary.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }
    
    private var chartData: [(day: String, count: Int, hasCold: Bool, hasHeat: Bool, hasBoth: Bool)] {
        let calendar = Calendar.current
        let today = Date()
        var data: [(day: String, count: Int, hasCold: Bool, hasHeat: Bool, hasBoth: Bool)] = []
        
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let weekday = calendar.component(.weekday, from: date)
                let dayName = days[weekday - 1]
                let daySessions = sessions.filter { calendar.isDate($0.date, inSameDayAs: date) }
                let hasCold = daySessions.contains { $0.type == .coldPlunge }
                let hasHeat = daySessions.contains { $0.type == .sauna }
                data.append((dayName, daySessions.count, hasCold, hasHeat, hasCold && hasHeat))
            }
        }
        
        return data
    }
}

// MARK: - Empty Chart Placeholder

struct EmptyChartPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.title)
                .foregroundColor(AppTheme.textTertiary)
            
            Text("No sessions this week")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Week Stat Item

struct WeekStatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let achievement: Achievement
    let animate: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ?
                          LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [AppTheme.surfaceBackground, AppTheme.cardBackground], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: achievement.isUnlocked ? Color.orange.opacity(0.4) : Color.clear, radius: 8, y: 4)
                
                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundColor(.white)
                    .grayscale(achievement.isUnlocked ? 0 : 1)
            }
            
            Text(achievement.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(achievement.isUnlocked ? .white : AppTheme.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
    }
}

// MARK: - Join Challenge Card

struct JoinChallengeCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "flag.fill")
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Join a Challenge")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Compete with the community")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.cardBackground)
            )
        }
    }
}

// MARK: - Challenge Progress Card

struct ChallengeProgressCard: View {
    let challenge: Challenge
    
    private var progress: Double {
        min(Double(challenge.currentProgress) / Double(challenge.requirement.target), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(challenge.participants) participants")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.coldPrimary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.surfaceBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.coldPrimary, AppTheme.coldSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(challenge.currentProgress)/\(challenge.requirement.target)")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
                
                Spacer()
                
                Text("\(challenge.daysRemaining) days left")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
    }
}

// MARK: - Preview

#Preview {
    InsightsView()
}
