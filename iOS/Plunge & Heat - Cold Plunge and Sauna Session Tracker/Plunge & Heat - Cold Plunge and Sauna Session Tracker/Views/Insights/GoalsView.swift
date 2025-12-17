//
//  GoalsView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

// MARK: - Goals View

struct GoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var settings = SettingsManager.shared
    
    @State private var showingAddGoal = false
    @State private var selectedTab: GoalTab = .goals
    @State private var animateContent = false
    
    enum GoalTab: String, CaseIterable {
        case goals = "Goals"
        case achievements = "Achievements"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        goalsContent
                            .tag(GoalTab.goals)
                        
                        achievementsContent
                            .tag(GoalTab.achievements)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Goals & Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.coldPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == .goals {
                        Button(action: { showingAddGoal = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppTheme.coldPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView()
            }
            .onAppear {
                withAnimation(.spring().delay(0.2)) {
                    animateContent = true
                }
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(GoalTab.allCases, id: \.self) { tab in
                Button(action: {
                    HapticFeedback.light()
                    withAnimation(.spring()) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: tab == .goals ? "target" : "trophy.fill")
                            Text(tab.rawValue)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTab == tab ? .white : AppTheme.textSecondary)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? AppTheme.coldPrimary : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Goals Content
    
    private var goalsContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Active goals
                if !activeGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionLabel(title: "Active Goals", icon: "flame.fill", color: .orange)
                        
                        ForEach(Array(activeGoals.enumerated()), id: \.element.id) { index, goal in
                            GoalProgressCard(goal: goal, animate: animateContent, delay: Double(index) * 0.1)
                        }
                    }
                }
                
                // Completed goals
                if !completedGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionLabel(title: "Completed", icon: "checkmark.circle.fill", color: .green)
                        
                        ForEach(completedGoals) { goal in
                            CompletedGoalRow(goal: goal)
                        }
                    }
                }
                
                // Empty state
                if activeGoals.isEmpty && completedGoals.isEmpty {
                    EmptyGoalsView {
                        showingAddGoal = true
                    }
                }
                
                // Suggested goals
                suggestedGoalsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Achievements Content
    
    private var achievementsContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Stats summary
                achievementStats
                
                // Unlocked achievements
                if !unlockedAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionLabel(title: "Unlocked", icon: "star.fill", color: .yellow)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(unlockedAchievements) { achievement in
                                AchievementCard(achievement: achievement, isUnlocked: true)
                            }
                        }
                    }
                }
                
                // Locked achievements
                VStack(alignment: .leading, spacing: 16) {
                    SectionLabel(title: "Locked", icon: "lock.fill", color: AppTheme.textTertiary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(lockedAchievements) { achievement in
                            AchievementCard(achievement: achievement, isUnlocked: false)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Achievement Stats
    
    private var achievementStats: some View {
        HStack(spacing: 12) {
            AchievementStatBox(
                value: "\(unlockedAchievements.count)",
                label: "Unlocked",
                icon: "trophy.fill",
                color: .yellow
            )
            
            AchievementStatBox(
                value: "\(lockedAchievements.count)",
                label: "Remaining",
                icon: "lock.fill",
                color: AppTheme.textTertiary
            )
            
            AchievementStatBox(
                value: "\(Int(completionPercentage))%",
                label: "Complete",
                icon: "chart.pie.fill",
                color: .green
            )
        }
    }
    
    // MARK: - Suggested Goals Section
    
    private var suggestedGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(title: "Suggested Goals", icon: "lightbulb.fill", color: .yellow)
            
            VStack(spacing: 12) {
                SuggestedGoalRow(
                    title: "7-Day Streak",
                    description: "Log a session every day for a week",
                    icon: "flame.fill",
                    color: .orange
                ) {
                    // Create goal
                }
                
                SuggestedGoalRow(
                    title: "5 Sessions This Week",
                    description: "Complete 5 sessions by Sunday",
                    icon: "calendar",
                    color: AppTheme.coldPrimary
                ) {
                    // Create goal
                }
                
                SuggestedGoalRow(
                    title: "30 Minutes Total",
                    description: "Accumulate 30 minutes of exposure",
                    icon: "clock.fill",
                    color: .purple
                ) {
                    // Create goal
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var activeGoals: [Goal] {
        dataManager.goals.filter { $0.isActive }
    }
    
    private var completedGoals: [Goal] {
        dataManager.goals.filter { $0.isCompleted }
    }
    
    private var unlockedAchievements: [Achievement] {
        dataManager.achievements.filter { $0.isUnlocked }
    }
    
    private var lockedAchievements: [Achievement] {
        dataManager.achievements.filter { !$0.isUnlocked }
    }
    
    private var completionPercentage: Double {
        let total = dataManager.achievements.count
        guard total > 0 else { return 0 }
        return Double(unlockedAchievements.count) / Double(total) * 100
    }
}

// MARK: - Section Label

struct SectionLabel: View {
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

// MARK: - Goal Progress Card

struct GoalProgressCard: View {
    let goal: Goal
    let animate: Bool
    var delay: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(AppTheme.surfaceBackground, lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: goal.progress)
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(goal.progressPercentage)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.surfaceBackground)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * goal.progress)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(goal.currentValue) / \(goal.targetValue) \(goal.targetType.unitLabel)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    if let endDate = goal.endDate {
                        Text(daysRemaining(until: endDate))
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
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
    
    private var progressColor: Color {
        if goal.progress >= 1 { return .green }
        if goal.progress >= 0.7 { return .yellow }
        return AppTheme.coldPrimary
    }
    
    private func daysRemaining(until date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days <= 0 { return "Ends today" }
        if days == 1 { return "1 day left" }
        return "\(days) days left"
    }
}

// MARK: - Completed Goal Row

struct CompletedGoalRow: View {
    let goal: Goal
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if let completedDate = goal.completedDate {
                    Text("Completed \(formatDate(completedDate))")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Empty Goals View

struct EmptyGoalsView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.textTertiary)
            
            VStack(spacing: 8) {
                Text("No Goals Yet")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Set a goal to stay motivated and track your progress")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Your First Goal")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(AppTheme.coldPrimary)
                .cornerRadius(14)
            }
        }
        .padding(32)
    }
}

// MARK: - Achievement Stat Box

struct AchievementStatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
        )
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ?
                          LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [AppTheme.surfaceBackground], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: isUnlocked ? Color.orange.opacity(0.4) : Color.clear, radius: 8, y: 4)
                
                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? .white : AppTheme.textTertiary)
            }
            
            VStack(spacing: 4) {
                Text(achievement.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .white : AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                
                if !isUnlocked {
                    Text("\(achievement.progress)/\(achievement.requirement)")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
        .opacity(isUnlocked ? 1 : 0.7)
    }
}

// MARK: - Suggested Goal Row

struct SuggestedGoalRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle")
                    .foregroundColor(AppTheme.coldPrimary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
            )
        }
    }
}

// MARK: - Add Goal View

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = DataManager.shared
    
    @State private var title = ""
    @State private var targetType: GoalTargetType = .sessionsPerWeek
    @State private var targetValue = 5
    @State private var sessionType: SessionType?
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(86400 * 7)
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Goal title
                        FormSection(title: "Goal Name") {
                            TextField("e.g., Weekly cold plunge challenge", text: $title)
                                .foregroundColor(.white)
                        }
                        
                        // Goal type
                        FormSection(title: "Goal Type") {
                            Picker("Type", selection: $targetType) {
                                ForEach(GoalTargetType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                        }
                        
                        // Target value
                        FormSection(title: "Target") {
                            HStack {
                                Button(action: { if targetValue > 1 { targetValue -= 1 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(AppTheme.coldPrimary)
                                }
                                
                                Spacer()
                                
                                Text("\(targetValue)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text(targetType.unitLabel)
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                Spacer()
                                
                                Button(action: { targetValue += 1 }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(AppTheme.coldPrimary)
                                }
                            }
                        }
                        
                        // Session type filter
                        FormSection(title: "Session Type (Optional)") {
                            HStack(spacing: 12) {
                                SessionTypeButton(
                                    type: nil,
                                    label: "Both",
                                    isSelected: sessionType == nil
                                ) { sessionType = nil }
                                
                                SessionTypeButton(
                                    type: .coldPlunge,
                                    label: "Cold",
                                    isSelected: sessionType == .coldPlunge
                                ) { sessionType = .coldPlunge }
                                
                                SessionTypeButton(
                                    type: .sauna,
                                    label: "Sauna",
                                    isSelected: sessionType == .sauna
                                ) { sessionType = .sauna }
                            }
                        }
                        
                        // Deadline
                        FormSection(title: "Deadline") {
                            Toggle("Set deadline", isOn: $hasDeadline)
                                .tint(AppTheme.coldPrimary)
                            
                            if hasDeadline {
                                DatePicker("End date", selection: $deadline, displayedComponents: .date)
                                    .tint(AppTheme.coldPrimary)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
                
                // Save button
                VStack {
                    Spacer()
                    
                    Button(action: saveGoal) {
                        Text("Create Goal")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppTheme.coldPrimary)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                    .disabled(title.isEmpty)
                    .opacity(title.isEmpty ? 0.6 : 1)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }
    
    private func saveGoal() {
        let goal = Goal(
            title: title.isEmpty ? "\(targetType.displayName) Goal" : title,
            description: "Target: \(targetValue) \(targetType.unitLabel)",
            targetType: targetType,
            targetValue: targetValue,
            sessionType: sessionType,
            endDate: hasDeadline ? deadline : nil
        )
        
        dataManager.addGoal(goal)
        HapticFeedback.success()
        dismiss()
    }
}

// MARK: - Form Section

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
        )
    }
}

// MARK: - Session Type Button

struct SessionTypeButton: View {
    let type: SessionType?
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: 6) {
                if let t = type {
                    Image(systemName: t.icon)
                }
                Text(label)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? (type?.primaryColor ?? AppTheme.coldPrimary) : AppTheme.surfaceBackground)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    GoalsView()
}
