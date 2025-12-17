//
//  NotificationManager.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

// MARK: - Notification Manager

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Notification Identifiers
    
    private enum NotificationID {
        static let dailyReminder = "daily_reminder"
        static let streakReminder = "streak_reminder"
        static let goalProgress = "goal_progress"
        static let sessionComplete = "session_complete"
    }
    
    // MARK: - Initialization
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        let granted = try await center.requestAuthorization(options: options)
        isAuthorized = granted
    }
    
    // MARK: - Daily Reminder
    
    func scheduleDailyReminder(at time: Date) {
        guard isAuthorized else { return }
        
        // Cancel existing reminder
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.dailyReminder])
        
        let content = UNMutableNotificationContent()
        content.title = "Keep Your Streak Going! 🔥"
        content.body = "Log today's session to maintain your streak."
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: NotificationID.dailyReminder,
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.dailyReminder])
    }
    
    // MARK: - Streak Milestone
    
    func sendStreakMilestoneNotification(streak: Int) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        
        switch streak {
        case 7:
            content.title = "🔥 7-Day Streak!"
            content.body = "One week strong! You're building an amazing habit."
        case 14:
            content.title = "🔥 Two Week Streak!"
            content.body = "14 days of dedication. Your body is thanking you!"
        case 30:
            content.title = "🏆 30-Day Streak!"
            content.body = "A full month! You're a true warrior of the cold/heat."
        case 60:
            content.title = "⭐ 60-Day Streak!"
            content.body = "Two months of consistency. Legendary dedication!"
        case 100:
            content.title = "💎 100-Day Streak!"
            content.body = "Triple digits! You're in elite territory now."
        default:
            if streak > 0 && streak % 10 == 0 {
                content.title = "🔥 \(streak)-Day Streak!"
                content.body = "Keep that momentum going!"
            } else {
                return
            }
        }
        
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "\(NotificationID.streakReminder)_\(streak)",
            content: content,
            trigger: nil // Immediate
        )
        
        center.add(request)
    }
    
    // MARK: - Goal Progress
    
    func sendGoalProgressNotification(goal: Goal) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        
        let remaining = goal.targetValue - goal.currentValue
        
        if remaining <= 0 {
            content.title = "🎉 Goal Achieved!"
            content.body = "You completed: \(goal.title)"
        } else if remaining == 1 {
            content.title = "Almost There! 💪"
            content.body = "Just one more to hit your goal: \(goal.title)"
        } else {
            content.title = "Goal Progress 📊"
            content.body = "\(goal.currentValue)/\(goal.targetValue) - \(remaining) more to go!"
        }
        
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "\(NotificationID.goalProgress)_\(goal.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        center.add(request)
    }
    
    // MARK: - Session Complete
    
    func sendSessionCompleteNotification(session: Session) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        
        let emoji = session.type == .coldPlunge ? "❄️" : "🔥"
        content.title = "\(emoji) Session Logged!"
        content.body = "\(session.type.displayName) - \(session.durationFormatted). Great work!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "\(NotificationID.sessionComplete)_\(session.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        center.add(request)
    }
    
    // MARK: - Clear All
    
    func clearAllNotifications() {
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
