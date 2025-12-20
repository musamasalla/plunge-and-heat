//
//  WatchConnectivityManager.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/20.
//

import Foundation
import WatchConnectivity
import Combine

// MARK: - Watch Connectivity Manager (iOS Side)

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isWatchAppInstalled = false
    @Published var isReachable = false
    
    private var session: WCSession?
    
    // App Group identifier for shared data
    static let appGroupID = "group.com.plungeheat.app"
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Shared UserDefaults
    
    var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupID)
    }
    
    // MARK: - Send Data to Watch
    
    func sendSessionToWatch(_ session: Session) {
        guard let wcSession = self.session,
              wcSession.activationState == .activated,
              wcSession.isWatchAppInstalled else { return }
        
        let sessionData: [String: Any] = [
            "action": "newSession",
            "id": session.id.uuidString,
            "type": session.type.rawValue,
            "date": session.date.timeIntervalSince1970,
            "duration": session.duration
        ]
        
        // Use transferUserInfo for reliable delivery
        wcSession.transferUserInfo(sessionData)
        
        // Also update shared UserDefaults
        updateSharedData()
    }
    
    func updateSharedData() {
        guard let defaults = sharedDefaults else { return }
        
        let settings = SettingsManager.shared
        let dataManager = DataManager.shared
        
        // Update streak
        defaults.set(settings.currentStreak, forKey: "currentStreak")
        defaults.set(settings.longestStreak, forKey: "longestStreak")
        
        // Update today's sessions
        let todayCount = dataManager.todaysSessions.count
        defaults.set(todayCount, forKey: "todaySessions")
        
        // Update last session type
        if let lastSession = dataManager.todaysSessions.first {
            defaults.set(lastSession.type.displayName, forKey: "lastSessionType")
        }
        
        // Total sessions
        defaults.set(dataManager.statistics.totalSessions, forKey: "totalSessions")
        
        // Sync to watch if reachable
        syncToWatch()
    }
    
    func syncToWatch() {
        guard let wcSession = session,
              wcSession.activationState == .activated else { return }
        
        let settings = SettingsManager.shared
        let dataManager = DataManager.shared
        
        let context: [String: Any] = [
            "currentStreak": settings.currentStreak,
            "longestStreak": settings.longestStreak,
            "todaySessions": dataManager.todaysSessions.count,
            "totalSessions": dataManager.statistics.totalSessions,
            "lastUpdate": Date().timeIntervalSince1970
        ]
        
        do {
            try wcSession.updateApplicationContext(context)
        } catch {
            print("Failed to update application context: \(error)")
        }
    }
    
    // MARK: - Receive Session from Watch
    
    func handleSessionFromWatch(_ data: [String: Any]) {
        guard let typeRaw = data["type"] as? String,
              let type = SessionType(rawValue: typeRaw),
              let duration = data["duration"] as? TimeInterval,
              let dateInterval = data["date"] as? TimeInterval else { return }
        
        let date = Date(timeIntervalSince1970: dateInterval)
        
        // Create session in DataManager
        let session = Session(
            id: UUID(),
            type: type,
            date: date,
            duration: duration,
            temperature: nil,
            temperatureUnit: SettingsManager.shared.temperatureUnit,
            heartRate: data["heartRate"] as? Int,
            notes: "Logged from Apple Watch"
        )
        
        DataManager.shared.addSession(session)
        
        // Update shared data
        updateSharedData()
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
            
            if activationState == .activated {
                self.updateSharedData()
            }
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle inactive state
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate for multi-watch support
        Task { @MainActor in
            self.session?.activate()
        }
    }
    
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            if session.isReachable {
                self.syncToWatch()
            }
        }
    }
    
    // Receive messages from Watch
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            if let action = message["action"] as? String {
                switch action {
                case "newSession":
                    self.handleSessionFromWatch(message)
                case "requestSync":
                    self.syncToWatch()
                default:
                    break
                }
            }
        }
    }
    
    // Receive user info transfers from Watch
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in
            if let action = userInfo["action"] as? String, action == "newSession" {
                self.handleSessionFromWatch(userInfo)
            }
        }
    }
}
