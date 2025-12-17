//
//  SettingsManager.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Settings Manager

@MainActor
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let temperatureUnit = "temperatureUnit"
        static let dailyReminderEnabled = "dailyReminderEnabled"
        static let dailyReminderTime = "dailyReminderTime"
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
        static let breathingGuideEnabled = "breathingGuideEnabled"
        static let safetyTipsShown = "safetyTipsShown"
        static let isPremiumUser = "isPremiumUser"
        static let totalSessionsLogged = "totalSessionsLogged"
        static let freeSessionLimit = "freeSessionLimit"
        static let lastStreakDate = "lastStreakDate"
        static let currentStreak = "currentStreak"
        static let longestStreak = "longestStreak"
        static let selectedBreathingTechnique = "selectedBreathingTechnique"
    }
    
    // MARK: - Published Properties
    
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }
    
    @Published var temperatureUnit: TemperatureUnit {
        didSet { 
            defaults.set(temperatureUnit.rawValue, forKey: Keys.temperatureUnit) 
        }
    }
    
    @Published var dailyReminderEnabled: Bool {
        didSet { defaults.set(dailyReminderEnabled, forKey: Keys.dailyReminderEnabled) }
    }
    
    @Published var dailyReminderTime: Date {
        didSet { defaults.set(dailyReminderTime, forKey: Keys.dailyReminderTime) }
    }
    
    @Published var hapticFeedbackEnabled: Bool {
        didSet { defaults.set(hapticFeedbackEnabled, forKey: Keys.hapticFeedbackEnabled) }
    }
    
    @Published var breathingGuideEnabled: Bool {
        didSet { defaults.set(breathingGuideEnabled, forKey: Keys.breathingGuideEnabled) }
    }
    
    @Published var safetyTipsShown: Bool {
        didSet { defaults.set(safetyTipsShown, forKey: Keys.safetyTipsShown) }
    }
    
    @Published var isPremiumUser: Bool {
        didSet { defaults.set(isPremiumUser, forKey: Keys.isPremiumUser) }
    }
    
    @Published var totalSessionsLogged: Int {
        didSet { defaults.set(totalSessionsLogged, forKey: Keys.totalSessionsLogged) }
    }
    
    @Published var currentStreak: Int {
        didSet { defaults.set(currentStreak, forKey: Keys.currentStreak) }
    }
    
    @Published var longestStreak: Int {
        didSet { defaults.set(longestStreak, forKey: Keys.longestStreak) }
    }
    
    // MARK: - Constants
    
    let freeSessionLimit = 30
    let freeDaysHistoryAccess = 7
    
    // MARK: - Initialization
    
    private init() {
        // Load from UserDefaults
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        
        if let unitString = defaults.string(forKey: Keys.temperatureUnit),
           let unit = TemperatureUnit(rawValue: unitString) {
            self.temperatureUnit = unit
        } else {
            self.temperatureUnit = .fahrenheit
        }
        
        self.dailyReminderEnabled = defaults.bool(forKey: Keys.dailyReminderEnabled)
        
        if let reminderTime = defaults.object(forKey: Keys.dailyReminderTime) as? Date {
            self.dailyReminderTime = reminderTime
        } else {
            // Default to 7:00 AM
            var components = DateComponents()
            components.hour = 7
            components.minute = 0
            self.dailyReminderTime = Calendar.current.date(from: components) ?? Date()
        }
        
        self.hapticFeedbackEnabled = defaults.object(forKey: Keys.hapticFeedbackEnabled) as? Bool ?? true
        self.breathingGuideEnabled = defaults.object(forKey: Keys.breathingGuideEnabled) as? Bool ?? true
        self.safetyTipsShown = defaults.bool(forKey: Keys.safetyTipsShown)
        self.isPremiumUser = defaults.bool(forKey: Keys.isPremiumUser)
        self.totalSessionsLogged = defaults.integer(forKey: Keys.totalSessionsLogged)
        self.currentStreak = defaults.integer(forKey: Keys.currentStreak)
        self.longestStreak = defaults.integer(forKey: Keys.longestStreak)
    }
    
    // MARK: - Computed Properties
    
    var canLogMoreSessions: Bool {
        isPremiumUser || totalSessionsLogged < freeSessionLimit
    }
    
    var remainingFreeSessions: Int {
        max(0, freeSessionLimit - totalSessionsLogged)
    }
    
    var hasReachedFreeLimit: Bool {
        !isPremiumUser && totalSessionsLogged >= freeSessionLimit
    }
    
    // MARK: - Methods
    
    func incrementSessionCount() {
        totalSessionsLogged += 1
    }
    
    func updateStreak(hasSessionToday: Bool) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastDate = defaults.object(forKey: Keys.lastStreakDate) as? Date {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDifference == 0 {
                // Same day, no change
                return
            } else if daysDifference == 1 && hasSessionToday {
                // Consecutive day with session
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else if daysDifference > 1 && hasSessionToday {
                // Gap in days, reset streak
                currentStreak = 1
            } else if !hasSessionToday {
                // No session today, streak breaks if it's a new day
                currentStreak = 0
            }
        } else if hasSessionToday {
            // First session ever
            currentStreak = 1
            longestStreak = max(longestStreak, 1)
        }
        
        if hasSessionToday {
            defaults.set(today, forKey: Keys.lastStreakDate)
        }
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
    
    func resetAllData() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
        
        // Reinitialize
        hasCompletedOnboarding = false
        temperatureUnit = .fahrenheit
        dailyReminderEnabled = false
        hapticFeedbackEnabled = true
        breathingGuideEnabled = true
        safetyTipsShown = false
        isPremiumUser = false
        totalSessionsLogged = 0
        currentStreak = 0
        longestStreak = 0
    }
}

// MARK: - Haptic Feedback Helper

struct HapticFeedback {
    static func light() {
        guard SettingsManager.shared.hapticFeedbackEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        guard SettingsManager.shared.hapticFeedbackEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func heavy() {
        guard SettingsManager.shared.hapticFeedbackEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    static func success() {
        guard SettingsManager.shared.hapticFeedbackEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func warning() {
        guard SettingsManager.shared.hapticFeedbackEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    static func error() {
        guard SettingsManager.shared.hapticFeedbackEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}
