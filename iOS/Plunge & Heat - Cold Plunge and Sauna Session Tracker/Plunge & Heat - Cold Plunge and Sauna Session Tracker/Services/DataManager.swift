//
//  DataManager.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import Foundation
import SwiftUI
import Combine
import CoreData

// MARK: - Data Manager

@MainActor
final class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // MARK: - Published Properties
    
    @Published var sessions: [Session] = []
    @Published var goals: [Goal] = []
    @Published var achievements: [Achievement] = Achievement.allAchievements
    @Published var joinedChallenges: [Challenge] = []
    
    // MARK: - Core Data
    
    private let coreData = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Legacy UserDefaults Keys (for migration)
    
    private let sessionsKey = "saved_sessions"
    private let goalsKey = "saved_goals"
    private let achievementsKey = "saved_achievements"
    private let challengesKey = "saved_challenges"
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    
    private init() {
        // Migrate existing UserDefaults data to Core Data
        migrateUserDefaultsToCoreData()
        
        // Load data from Core Data
        loadData()
        
        // Listen for remote CloudKit changes
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Migration from UserDefaults
    
    private func migrateUserDefaultsToCoreData() {
        let defaults = UserDefaults.standard
        
        // Check if migration already done
        if defaults.bool(forKey: "coreDataMigrationComplete") {
            return
        }
        
        // Migrate sessions
        if let data = defaults.data(forKey: sessionsKey),
           let legacySessions = try? decoder.decode([Session].self, from: data) {
            for session in legacySessions {
                _ = coreData.createSession(
                    type: session.type,
                    date: session.date,
                    duration: session.duration,
                    temperature: session.temperature,
                    temperatureUnit: session.temperatureUnit,
                    heartRate: session.heartRate.map { Int16($0) },
                    notes: session.notes,
                    protocolUsed: session.protocolUsed,
                    breathingTechnique: session.breathingTechnique
                )
            }
            // Clear old data
            defaults.removeObject(forKey: sessionsKey)
        }
        
        // Mark migration complete
        defaults.set(true, forKey: "coreDataMigrationComplete")
        print("✅ Migration from UserDefaults to Core Data complete")
    }
    
    // MARK: - Data Persistence (Core Data)
    
    private func loadData() {
        // Load sessions from Core Data
        let sessionEntities = coreData.fetchAllSessions()
        sessions = sessionEntities.map { $0.toSession() }.sorted { $0.date > $1.date }
        
        // Goals still use UserDefaults for now (keeping achievements/challenges simpler)
        if let data = UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? decoder.decode([Goal].self, from: data) {
            goals = decoded
        }
        
        // Load achievements
        if let data = UserDefaults.standard.data(forKey: achievementsKey),
           let decoded = try? decoder.decode([Achievement].self, from: data) {
            achievements = decoded
        }
        
        // Load challenges
        if let data = UserDefaults.standard.data(forKey: challengesKey),
           let decoded = try? decoder.decode([Challenge].self, from: data) {
            joinedChallenges = decoded
        }
    }
    
    private func saveGoals() {
        if let data = try? encoder.encode(goals) {
            UserDefaults.standard.set(data, forKey: goalsKey)
        }
    }
    
    private func saveAchievements() {
        if let data = try? encoder.encode(achievements) {
            UserDefaults.standard.set(data, forKey: achievementsKey)
        }
    }
    
    private func saveChallenges() {
        if let data = try? encoder.encode(joinedChallenges) {
            UserDefaults.standard.set(data, forKey: challengesKey)
        }
    }
    
    // MARK: - Session CRUD
    
    func addSession(_ session: Session) {
        // Save to Core Data (syncs via CloudKit for premium)
        _ = coreData.createSession(
            type: session.type,
            date: session.date,
            duration: session.duration,
            temperature: session.temperature,
            temperatureUnit: session.temperatureUnit,
            heartRate: session.heartRate.map { Int16($0) },
            notes: session.notes,
            protocolUsed: session.protocolUsed,
            breathingTechnique: session.breathingTechnique
        )
        
        // Update local cache
        sessions.insert(session, at: 0)
        
        // Update settings
        SettingsManager.shared.incrementSessionCount()
        SettingsManager.shared.updateStreak(hasSessionToday: true)
        
        // Check achievements
        checkAchievements()
        
        // Update challenges
        updateChallengeProgress(for: session)
    }
    
    func updateSession(_ session: Session) {
        // For now, update local cache - Core Data update would need entity reference
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            // Note: Full Core Data update would require fetching and updating the entity
        }
    }
    
    func deleteSession(_ session: Session) {
        // Delete from local cache
        sessions.removeAll { $0.id == session.id }
        
        // Delete from Core Data
        let entities = coreData.fetchAllSessions()
        if let entity = entities.first(where: { $0.id == session.id }) {
            coreData.deleteSession(entity)
        }
    }
    
    func deleteSession(at offsets: IndexSet) {
        for index in offsets {
            let session = sessions[index]
            deleteSession(session)
        }
    }
    
    // MARK: - Session Queries
    
    func sessionsForDate(_ date: Date) -> [Session] {
        let calendar = Calendar.current
        return sessions.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func sessionsForWeek(containing date: Date) -> [Session] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }
        return sessions.filter { $0.date >= weekInterval.start && $0.date < weekInterval.end }
    }
    
    func sessionsForMonth(containing date: Date) -> [Session] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }
        return sessions.filter { $0.date >= monthInterval.start && $0.date < monthInterval.end }
    }
    
    func sessionsOfType(_ type: SessionType) -> [Session] {
        sessions.filter { $0.type == type }
    }
    
    var todaysSessions: [Session] {
        sessionsForDate(Date())
    }
    
    var thisWeeksSessions: [Session] {
        sessionsForWeek(containing: Date())
    }
    
    var thisMonthsSessions: [Session] {
        sessionsForMonth(containing: Date())
    }
    
    // MARK: - Statistics
    
    var statistics: SessionStatistics {
        var stats = SessionStatistics()
        
        stats.totalSessions = sessions.count
        stats.totalColdSessions = sessions.filter { $0.type == .coldPlunge }.count
        stats.totalSaunaSessions = sessions.filter { $0.type == .sauna }.count
        stats.totalDuration = sessions.reduce(0) { $0 + $1.duration }
        stats.sessionsThisWeek = thisWeeksSessions.count
        stats.sessionsThisMonth = thisMonthsSessions.count
        
        if !sessions.isEmpty {
            stats.averageDuration = stats.totalDuration / Double(sessions.count)
        }
        
        let sessionsWithTemp = sessions.compactMap { $0.temperature }
        if !sessionsWithTemp.isEmpty {
            stats.averageTemperature = sessionsWithTemp.reduce(0, +) / Double(sessionsWithTemp.count)
        }
        
        stats.currentStreak = SettingsManager.shared.currentStreak
        stats.longestStreak = SettingsManager.shared.longestStreak
        
        return stats
    }
    
    // MARK: - Calendar Data
    
    func daysWithSessions(in month: Date) -> [Date: [Session]] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return [:]
        }
        
        let monthSessions = sessions.filter {
            $0.date >= monthInterval.start && $0.date < monthInterval.end
        }
        
        var result: [Date: [Session]] = [:]
        for session in monthSessions {
            let day = calendar.startOfDay(for: session.date)
            if result[day] != nil {
                result[day]?.append(session)
            } else {
                result[day] = [session]
            }
        }
        
        return result
    }
    
    // MARK: - Goals
    
    func addGoal(_ goal: Goal) {
        goals.append(goal)
        saveGoals()
    }
    
    func updateGoal(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            saveGoals()
        }
    }
    
    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        saveGoals()
    }
    
    // MARK: - Achievements
    
    private func checkAchievements() {
        // Check First Plunge
        if let index = achievements.firstIndex(where: { $0.name == "First Plunge" }) {
            if !achievements[index].isUnlocked && statistics.totalColdSessions >= 1 {
                achievements[index].isUnlocked = true
                achievements[index].unlockedDate = Date()
                achievements[index].progress = 1
            }
        }
        
        // Check Ice Bear (50 cold sessions)
        if let index = achievements.firstIndex(where: { $0.name == "Ice Bear" }) {
            achievements[index].progress = statistics.totalColdSessions
            if !achievements[index].isUnlocked && statistics.totalColdSessions >= 50 {
                achievements[index].isUnlocked = true
                achievements[index].unlockedDate = Date()
            }
        }
        
        // Check Heat Seeker (50 sauna sessions)
        if let index = achievements.firstIndex(where: { $0.name == "Heat Seeker" }) {
            achievements[index].progress = statistics.totalSaunaSessions
            if !achievements[index].isUnlocked && statistics.totalSaunaSessions >= 50 {
                achievements[index].isUnlocked = true
                achievements[index].unlockedDate = Date()
            }
        }
        
        // Check Week Warrior (7 day streak)
        if let index = achievements.firstIndex(where: { $0.name == "Week Warrior" }) {
            achievements[index].progress = SettingsManager.shared.currentStreak
            if !achievements[index].isUnlocked && SettingsManager.shared.currentStreak >= 7 {
                achievements[index].isUnlocked = true
                achievements[index].unlockedDate = Date()
            }
        }
        
        // Check Monthly Master (30 day streak)
        if let index = achievements.firstIndex(where: { $0.name == "Monthly Master" }) {
            achievements[index].progress = SettingsManager.shared.currentStreak
            if !achievements[index].isUnlocked && SettingsManager.shared.currentStreak >= 30 {
                achievements[index].isUnlocked = true
                achievements[index].unlockedDate = Date()
            }
        }
        
        saveAchievements()
    }
    
    // MARK: - Challenges
    
    func joinChallenge(_ challenge: Challenge) {
        var mutableChallenge = challenge
        mutableChallenge.isJoined = true
        joinedChallenges.append(mutableChallenge)
        saveChallenges()
    }
    
    func leaveChallenge(_ challenge: Challenge) {
        joinedChallenges.removeAll { $0.id == challenge.id }
        saveChallenges()
    }
    
    private func updateChallengeProgress(for session: Session) {
        for i in joinedChallenges.indices {
            var challenge = joinedChallenges[i]
            
            // Check if session matches challenge requirements
            if let requiredType = challenge.requirement.sessionType {
                guard session.type == requiredType else { continue }
            }
            
            // Update progress based on type
            switch challenge.requirement.type {
            case .sessionsPerWeek, .sessionsPerMonth, .totalSessions:
                challenge.currentProgress += 1
            case .streakDays:
                challenge.currentProgress = SettingsManager.shared.currentStreak
            case .totalMinutes:
                challenge.currentProgress += Int(session.duration / 60)
            case .minDuration:
                if Int(session.duration / 60) >= challenge.requirement.target {
                    challenge.currentProgress = challenge.requirement.target
                }
            }
            
            // Check completion
            if challenge.currentProgress >= challenge.requirement.target {
                challenge.isCompleted = true
            }
            
            joinedChallenges[i] = challenge
        }
        saveChallenges()
    }
    
    // MARK: - Data Export
    
    func exportSessionsCSV() -> String {
        var csv = "Date,Type,Duration (seconds),Temperature,Unit,Heart Rate,Notes\n"
        
        for session in sessions {
            let dateFormatter = ISO8601DateFormatter()
            let date = dateFormatter.string(from: session.date)
            let type = session.type.displayName
            let duration = String(Int(session.duration))
            let temp = session.temperature.map { String($0) } ?? ""
            let unit = session.temperatureUnit.rawValue
            let hr = session.heartRate.map { String($0) } ?? ""
            let notes = session.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csv += "\(date),\(type),\(duration),\(temp),\(unit),\(hr),\(notes)\n"
        }
        
        return csv
    }
    
    func exportSessionsToCSV() -> URL? {
        let csv = exportSessionsCSV()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "plunge-heat-sessions-\(dateString).csv"
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write CSV file: \(error)")
            return nil
        }
    }
    
    // MARK: - Reset
    
    func resetAllData() {
        sessions = []
        goals = []
        achievements = Achievement.allAchievements
        joinedChallenges = []
        
        UserDefaults.standard.removeObject(forKey: sessionsKey)
        UserDefaults.standard.removeObject(forKey: goalsKey)
        UserDefaults.standard.removeObject(forKey: achievementsKey)
        UserDefaults.standard.removeObject(forKey: challengesKey)
    }
}
