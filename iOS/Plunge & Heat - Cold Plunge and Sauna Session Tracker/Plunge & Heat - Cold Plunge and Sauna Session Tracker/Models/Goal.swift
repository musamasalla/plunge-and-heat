//
//  Goal.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import Foundation
import SwiftUI

// MARK: - Goal Model

struct Goal: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var targetType: GoalTargetType
    var targetValue: Int
    var currentValue: Int
    var sessionType: SessionType?
    var startDate: Date
    var endDate: Date?
    var isCompleted: Bool
    var completedDate: Date?
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        targetType: GoalTargetType,
        targetValue: Int,
        currentValue: Int = 0,
        sessionType: SessionType? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isCompleted: Bool = false,
        completedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetType = targetType
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.sessionType = sessionType
        self.startDate = startDate
        self.endDate = endDate
        self.isCompleted = isCompleted
        self.completedDate = completedDate
    }
    
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentValue) / Double(targetValue), 1.0)
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var isActive: Bool {
        !isCompleted && (endDate == nil || endDate! > Date())
    }
    
    var remaining: Int {
        max(0, targetValue - currentValue)
    }
}

// MARK: - Goal Target Type

enum GoalTargetType: String, Codable, CaseIterable {
    case sessionsPerWeek = "sessions_per_week"
    case sessionsPerMonth = "sessions_per_month"
    case totalSessions = "total_sessions"
    case streakDays = "streak_days"
    case totalMinutes = "total_minutes"
    case minDuration = "min_duration"
    
    var displayName: String {
        switch self {
        case .sessionsPerWeek: return "Sessions per Week"
        case .sessionsPerMonth: return "Sessions per Month"
        case .totalSessions: return "Total Sessions"
        case .streakDays: return "Streak Days"
        case .totalMinutes: return "Total Minutes"
        case .minDuration: return "Minimum Duration"
        }
    }
    
    var icon: String {
        switch self {
        case .sessionsPerWeek: return "calendar.badge.plus"
        case .sessionsPerMonth: return "calendar"
        case .totalSessions: return "number.circle"
        case .streakDays: return "flame.fill"
        case .totalMinutes: return "clock.fill"
        case .minDuration: return "timer"
        }
    }
    
    var unitLabel: String {
        switch self {
        case .sessionsPerWeek, .sessionsPerMonth, .totalSessions:
            return "sessions"
        case .streakDays:
            return "days"
        case .totalMinutes, .minDuration:
            return "minutes"
        }
    }
}

// MARK: - Achievement Model

struct Achievement: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var iconName: String
    var category: AchievementCategory
    var requirement: Int
    var isUnlocked: Bool
    var unlockedDate: Date?
    var progress: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        iconName: String,
        category: AchievementCategory,
        requirement: Int,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil,
        progress: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.category = category
        self.requirement = requirement
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.progress = progress
    }
    
    var progressPercentage: Double {
        guard requirement > 0 else { return 0 }
        return min(Double(progress) / Double(requirement), 1.0)
    }
}

// MARK: - Achievement Category

enum AchievementCategory: String, Codable, CaseIterable {
    case streak = "Streak"
    case coldPlunge = "Cold Plunge"
    case sauna = "Sauna"
    case duration = "Duration"
    case consistency = "Consistency"
    case total = "Total"
    case special = "Special"
    
    var color: Color {
        switch self {
        case .streak: return .orange
        case .coldPlunge: return AppTheme.coldPrimary
        case .sauna: return AppTheme.heatPrimary
        case .duration: return .purple
        case .consistency: return .green
        case .total: return .yellow
        case .special: return .pink
        }
    }
}

// MARK: - Challenge Model

struct Challenge: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var iconName: String
    var startDate: Date
    var endDate: Date
    var requirement: ChallengeRequirement
    var currentProgress: Int
    var isJoined: Bool
    var isCompleted: Bool
    var participants: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        iconName: String = "flag.fill",
        startDate: Date,
        endDate: Date,
        requirement: ChallengeRequirement,
        currentProgress: Int = 0,
        isJoined: Bool = false,
        isCompleted: Bool = false,
        participants: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.startDate = startDate
        self.endDate = endDate
        self.requirement = requirement
        self.currentProgress = currentProgress
        self.isJoined = isJoined
        self.isCompleted = isCompleted
        self.participants = participants
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let remaining = calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, remaining)
    }
    
    var progress: Double {
        guard requirement.target > 0 else { return 0 }
        return min(Double(currentProgress) / Double(requirement.target), 1.0)
    }
}

// MARK: - Challenge Requirement

struct ChallengeRequirement: Codable {
    var type: GoalTargetType
    var target: Int
    var sessionType: SessionType?
}

// MARK: - Pre-built Achievements

extension Achievement {
    static let firstPlunge = Achievement(
        name: "First Plunge",
        description: "Complete your first cold plunge session",
        iconName: "snowflake",
        category: .coldPlunge,
        requirement: 1
    )
    
    static let iceBear = Achievement(
        name: "Ice Bear",
        description: "Complete 50 cold plunge sessions",
        iconName: "figure.pool.swim",
        category: .coldPlunge,
        requirement: 50
    )
    
    static let heatSeeker = Achievement(
        name: "Heat Seeker",
        description: "Complete 50 sauna sessions",
        iconName: "flame.fill",
        category: .sauna,
        requirement: 50
    )
    
    static let weekWarrior = Achievement(
        name: "Week Warrior",
        description: "Maintain a 7-day streak",
        iconName: "7.circle.fill",
        category: .streak,
        requirement: 7
    )
    
    static let monthlyMaster = Achievement(
        name: "Monthly Master",
        description: "Maintain a 30-day streak",
        iconName: "30.circle.fill",
        category: .streak,
        requirement: 30
    )
    
    static let centurion = Achievement(
        name: "Centurion",
        description: "Complete 100 total sessions",
        iconName: "100.circle.fill",
        category: .total,
        requirement: 100
    )
    
    static let earlyBird = Achievement(
        name: "Early Bird",
        description: "Complete 10 sessions before 7 AM",
        iconName: "sunrise.fill",
        category: .special,
        requirement: 10
    )
    
    static let nightOwl = Achievement(
        name: "Night Owl",
        description: "Complete 10 sessions after 9 PM",
        iconName: "moon.stars.fill",
        category: .special,
        requirement: 10
    )
    
    static let coldWarrior = Achievement(
        name: "Cold Warrior",
        description: "Log 1 hour total cold exposure",
        iconName: "timer",
        category: .coldPlunge,
        requirement: 60 // minutes
    )
    
    static let saunaMaster = Achievement(
        name: "Sauna Master",
        description: "Log 5 hours total sauna time",
        iconName: "thermometer.sun.fill",
        category: .sauna,
        requirement: 300 // minutes
    )
    
    static let consistentChampion = Achievement(
        name: "Consistent Champion",
        description: "Complete 4 sessions per week for 4 weeks",
        iconName: "calendar.badge.checkmark",
        category: .streak,
        requirement: 16
    )
    
    static let extremeExplorer = Achievement(
        name: "Extreme Explorer",
        description: "Complete a session below 40°F / 5°C",
        iconName: "wind.snow",
        category: .coldPlunge,
        requirement: 1
    )
    
    static let allAchievements: [Achievement] = [
        .firstPlunge,
        .iceBear,
        .heatSeeker,
        .weekWarrior,
        .monthlyMaster,
        .centurion,
        .earlyBird,
        .nightOwl,
        .coldWarrior,
        .saunaMaster,
        .consistentChampion,
        .extremeExplorer
    ]
}

// MARK: - Sample Challenges

extension Challenge {
    static let thirtyDayChallenge = Challenge(
        name: "30-Day Cold Plunge Challenge",
        description: "Complete a cold plunge every day for 30 days",
        iconName: "snowflake.circle.fill",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
        requirement: ChallengeRequirement(type: .streakDays, target: 30, sessionType: .coldPlunge),
        participants: 1247
    )
    
    static let saunaSprint = Challenge(
        name: "Sauna Sprint",
        description: "Complete 10 sauna sessions this week",
        iconName: "flame.circle.fill",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
        requirement: ChallengeRequirement(type: .sessionsPerWeek, target: 10, sessionType: .sauna),
        participants: 892
    )
    
    static let contrastKing = Challenge(
        name: "Contrast King",
        description: "Complete 5 contrast sessions (cold + sauna same day)",
        iconName: "arrow.triangle.swap",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
        requirement: ChallengeRequirement(type: .totalSessions, target: 5, sessionType: nil),
        participants: 643
    )
    
    static let weekendWarrior = Challenge(
        name: "Weekend Warrior",
        description: "Complete 4 sessions every weekend for a month",
        iconName: "calendar.badge.plus",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 28, to: Date())!,
        requirement: ChallengeRequirement(type: .totalSessions, target: 16, sessionType: nil),
        participants: 1089
    )
    
    static let mindfulMinutes = Challenge(
        name: "Mindful Minutes",
        description: "Accumulate 60 minutes of cold exposure",
        iconName: "brain.head.profile",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 21, to: Date())!,
        requirement: ChallengeRequirement(type: .totalMinutes, target: 60, sessionType: .coldPlunge),
        participants: 756
    )
    
    static let allChallenges: [Challenge] = [
        .thirtyDayChallenge,
        .saunaSprint,
        .contrastKing,
        .weekendWarrior,
        .mindfulMinutes
    ]
}
