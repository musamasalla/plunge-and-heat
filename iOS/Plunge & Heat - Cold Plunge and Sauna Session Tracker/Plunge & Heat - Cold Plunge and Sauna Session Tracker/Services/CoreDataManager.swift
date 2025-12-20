//
//  CoreDataManager.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import Foundation
import CoreData

// MARK: - Core Data Manager

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Persistent Container
    
    lazy var persistentContainer: NSPersistentContainer = {
        // Use regular container for now - upgrade to NSPersistentCloudKitContainer
        // after enabling CloudKit capability in Xcode
        let container = NSPersistentContainer(name: "PlungeHeat")
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No store description found")
        }
        
        // Enable persistent history tracking (required for future CloudKit migration)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // NOTE: To enable CloudKit sync:
        // 1. Add iCloud capability in Xcode (Signing & Capabilities)
        // 2. Enable CloudKit and create container: iCloud.com.plungeheat.app
        // 3. Change this to NSPersistentCloudKitContainer
        // 4. Add: description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
        //         containerIdentifier: "iCloud.com.plungeheat.app"
        //    )
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        // Merge policy for sync
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    
    func save() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Session CRUD Operations
    
    func createSession(
        type: SessionType,
        date: Date,
        duration: TimeInterval,
        temperature: Double?,
        temperatureUnit: TemperatureUnit,
        heartRate: Int16?,
        notes: String?,
        protocolUsed: String?,
        breathingTechnique: String?
    ) -> SessionEntity {
        let session = SessionEntity(context: viewContext)
        session.id = UUID()
        session.type = type.rawValue
        session.date = date
        session.duration = duration
        session.temperature = temperature ?? 0
        session.hasTemperature = temperature != nil
        session.temperatureUnit = temperatureUnit.rawValue
        session.heartRate = heartRate ?? 0
        session.hasHeartRate = heartRate != nil
        session.notes = notes
        session.protocolUsed = protocolUsed
        session.breathingTechnique = breathingTechnique
        session.createdAt = Date()
        
        save()
        return session
    }
    
    func fetchAllSessions() -> [SessionEntity] {
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SessionEntity.date, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch sessions: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchSessions(from startDate: Date, to endDate: Date) -> [SessionEntity] {
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SessionEntity.date, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch sessions: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchTodaySessions() -> [SessionEntity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return fetchSessions(from: startOfDay, to: endOfDay)
    }
    
    func deleteSession(_ session: SessionEntity) {
        viewContext.delete(session)
        save()
    }
    
    // MARK: - Goal CRUD Operations
    
    func createGoal(
        title: String,
        description: String,
        targetType: GoalTargetType,
        targetValue: Int32,
        sessionType: SessionType?,
        endDate: Date?
    ) -> GoalEntity {
        let goal = GoalEntity(context: viewContext)
        goal.id = UUID()
        goal.title = title
        goal.goalDescription = description
        goal.targetType = targetType.rawValue
        goal.targetValue = targetValue
        goal.currentValue = 0
        goal.sessionType = sessionType?.rawValue
        goal.startDate = Date()
        goal.endDate = endDate
        goal.isCompleted = false
        
        save()
        return goal
    }
    
    func fetchAllGoals() -> [GoalEntity] {
        let request: NSFetchRequest<GoalEntity> = GoalEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GoalEntity.startDate, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch goals: \(error.localizedDescription)")
            return []
        }
    }
    
    func updateGoalProgress(_ goal: GoalEntity, progress: Int32) {
        goal.currentValue = progress
        if progress >= goal.targetValue {
            goal.isCompleted = true
            goal.completedDate = Date()
        }
        save()
    }
    
    func deleteGoal(_ goal: GoalEntity) {
        viewContext.delete(goal)
        save()
    }
    
    // MARK: - Achievement Operations
    
    func createAchievement(
        name: String,
        description: String,
        iconName: String,
        category: String,
        requirement: Int32
    ) -> AchievementEntity {
        let achievement = AchievementEntity(context: viewContext)
        achievement.id = UUID()
        achievement.name = name
        achievement.achievementDescription = description
        achievement.iconName = iconName
        achievement.category = category
        achievement.requirement = requirement
        achievement.progress = 0
        achievement.isUnlocked = false
        
        save()
        return achievement
    }
    
    func fetchAllAchievements() -> [AchievementEntity] {
        let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AchievementEntity.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch achievements: \(error.localizedDescription)")
            return []
        }
    }
    
    func unlockAchievement(_ achievement: AchievementEntity) {
        achievement.isUnlocked = true
        achievement.unlockedDate = Date()
        save()
    }
    
    // MARK: - Statistics
    
    func calculateStatistics() -> SessionStatistics {
        let sessions = fetchAllSessions()
        let calendar = Calendar.current
        
        var stats = SessionStatistics()
        stats.totalSessions = sessions.count
        stats.totalColdSessions = sessions.filter { $0.type == SessionType.coldPlunge.rawValue }.count
        stats.totalSaunaSessions = sessions.filter { $0.type == SessionType.sauna.rawValue }.count
        stats.totalDuration = sessions.reduce(0) { $0 + $1.duration }
        stats.averageDuration = sessions.isEmpty ? 0 : stats.totalDuration / Double(sessions.count)
        
        // This week
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        stats.sessionsThisWeek = sessions.filter { $0.date ?? Date() >= startOfWeek }.count
        
        // This month
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        stats.sessionsThisMonth = sessions.filter { $0.date ?? Date() >= startOfMonth }.count
        
        // Calculate streak
        stats.currentStreak = calculateCurrentStreak(from: sessions)
        
        return stats
    }
    
    private func calculateCurrentStreak(from sessions: [SessionEntity]) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while true {
            let hasSession = sessions.contains { session in
                guard let sessionDate = session.date else { return false }
                return calendar.isDate(sessionDate, inSameDayAs: currentDate)
            }
            
            if hasSession {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Migration from UserDefaults
    
    func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard
        
        // Check if migration already done
        if defaults.bool(forKey: "coreDataMigrationComplete") {
            return
        }
        
        // Migrate sessions
        if let data = defaults.data(forKey: "sessions"),
           let sessions = try? JSONDecoder().decode([Session].self, from: data) {
            for session in sessions {
                _ = createSession(
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
        }
        
        // Mark migration complete
        defaults.set(true, forKey: "coreDataMigrationComplete")
    }
}

// MARK: - Session Entity Extension

extension SessionEntity {
    func toSession() -> Session {
        Session(
            id: id ?? UUID(),
            type: SessionType(rawValue: type ?? "cold_plunge") ?? .coldPlunge,
            date: date ?? Date(),
            duration: duration,
            temperature: hasTemperature ? temperature : nil,
            temperatureUnit: TemperatureUnit(rawValue: temperatureUnit ?? "fahrenheit") ?? .fahrenheit,
            heartRate: hasHeartRate ? Int(heartRate) : nil,
            notes: notes,
            protocolUsed: protocolUsed,
            breathingTechnique: breathingTechnique
        )
    }
}
