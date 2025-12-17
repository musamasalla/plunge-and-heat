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
    @ObservedObject var dataManager = DataManager.shared
    
    @State private var showingAddGoal = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab picker
                    Picker("View", selection: $selectedTab) {
                        Text("Goals").tag(0)
                        Text("Achievements").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    ScrollView {
                        if selectedTab == 0 {
                            goalsContent
                        } else {
                            achievementsContent
                        }
                    }
                }
            }
            .navigationTitle("Goals & Badges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.coldPrimary)
                }
                
                if selectedTab == 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddGoal = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(AppTheme.coldPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView()
            }
        }
    }
    
    // MARK: - Goals Content
    
    private var goalsContent: some View {
        VStack(spacing: 16) {
            if dataManager.goals.isEmpty {
                EmptyStateView(
                    iconName: "target",
                    title: "No Goals Yet",
                    message: "Set personal goals to stay motivated and track your progress.",
                    actionTitle: "Create Goal"
                ) {
                    showingAddGoal = true
                }
                .padding(.top, 60)
            } else {
                // Active goals
                if !activeGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Goals")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ForEach(activeGoals) { goal in
                            GoalDetailCard(goal: goal)
                                .padding(.horizontal)
                        }
                    }
                }
                
                // Completed goals
                if !completedGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Completed")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ForEach(completedGoals) { goal in
                            GoalDetailCard(goal: goal)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    private var activeGoals: [Goal] {
        dataManager.goals.filter { !$0.isCompleted }
    }
    
    private var completedGoals: [Goal] {
        dataManager.goals.filter { $0.isCompleted }
    }
    
    // MARK: - Achievements Content
    
    private var achievementsContent: some View {
        VStack(spacing: 24) {
            // Summary
            HStack(spacing: 16) {
                SummaryCard(
                    value: "\(unlockedCount)",
                    label: "Unlocked",
                    color: .green
                )
                
                SummaryCard(
                    value: "\(lockedCount)",
                    label: "Locked",
                    color: AppTheme.textTertiary
                )
            }
            .padding(.horizontal)
            
            // Achievements grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(dataManager.achievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private var unlockedCount: Int {
        dataManager.achievements.filter { $0.isUnlocked }.count
    }
    
    private var lockedCount: Int {
        dataManager.achievements.filter { !$0.isUnlocked }.count
    }
}

// MARK: - Goal Detail Card

struct GoalDetailCard: View {
    let goal: Goal
    @ObservedObject var dataManager = DataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: goal.targetType.icon)
                    .font(.title2)
                    .foregroundColor(goal.isCompleted ? .green : AppTheme.coldPrimary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(goal.targetType.displayName)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Menu {
                        Button(role: .destructive) {
                            dataManager.deleteGoal(goal)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.surfaceBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(goal.isCompleted ? Color.green : AppTheme.coldPrimary)
                        .frame(width: geometry.size.width * goal.progress, height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(goal.currentValue)/\(goal.targetValue) \(goal.targetType.unitLabel)")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                Text("\(goal.progressPercentage)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(goal.isCompleted ? .green : .white)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusLarge)
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.category.color.opacity(0.2) : AppTheme.surfaceBackground)
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundColor(achievement.isUnlocked ? achievement.category.color : AppTheme.textTertiary)
                
                if !achievement.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                        .offset(x: 20, y: 20)
                }
            }
            
            VStack(spacing: 4) {
                Text(achievement.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(achievement.isUnlocked ? .white : AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Progress for locked achievements
            if !achievement.isUnlocked {
                ProgressView(value: achievement.progressPercentage, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: achievement.category.color))
                
                Text("\(achievement.progress)/\(achievement.requirement)")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - Add Goal View

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager = DataManager.shared
    
    @State private var title = ""
    @State private var targetType: GoalTargetType = .sessionsPerWeek
    @State private var targetValue = 3
    @State private var sessionType: SessionType? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Goal Title", text: $title)
                    }
                    
                    Section("Goal Type") {
                        Picker("Type", selection: $targetType) {
                            ForEach(GoalTargetType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                    }
                    
                    Section("Target") {
                        Stepper("\(targetValue) \(targetType.unitLabel)", value: $targetValue, in: 1...100)
                    }
                    
                    Section("Session Type (Optional)") {
                        Picker("Session Type", selection: $sessionType) {
                            Text("Any").tag(SessionType?.none)
                            ForEach(SessionType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(SessionType?.some(type))
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveGoal() {
        let goal = Goal(
            title: title,
            targetType: targetType,
            targetValue: targetValue,
            sessionType: sessionType
        )
        
        dataManager.addGoal(goal)
        HapticFeedback.success()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    GoalsView()
}
