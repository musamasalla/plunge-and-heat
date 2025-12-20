//
//  PlungeHeatWatchApp.swift
//  Plunge & Heat Watch App
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI
import WatchKit
import WatchConnectivity

// MARK: - Watch App Entry Point

@main
struct PlungeHeatWatchApp: App {
    @StateObject private var sessionManager = WatchSessionManager.shared
    
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(sessionManager)
        }
    }
}

// MARK: - Watch Session Manager

@MainActor
final class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var todaySessions: Int = 0
    @Published var totalSessions: Int = 0
    @Published var isConnected = false
    @Published var lastSyncDate: Date?
    
    // Local session storage for Watch
    @Published var localSessions: [WatchSession] = []
    
    private var session: WCSession?
    
    // App Group for shared data
    static let appGroupID = "group.com.plungeheat.app"
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        
        loadFromSharedDefaults()
    }
    
    // MARK: - Shared UserDefaults
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupID)
    }
    
    func loadFromSharedDefaults() {
        guard let defaults = sharedDefaults else { return }
        
        currentStreak = defaults.integer(forKey: "currentStreak")
        longestStreak = defaults.integer(forKey: "longestStreak")
        todaySessions = defaults.integer(forKey: "todaySessions")
        totalSessions = defaults.integer(forKey: "totalSessions")
        
        if let lastSync = defaults.object(forKey: "lastUpdate") as? TimeInterval {
            lastSyncDate = Date(timeIntervalSince1970: lastSync)
        }
    }
    
    func saveToSharedDefaults() {
        guard let defaults = sharedDefaults else { return }
        
        defaults.set(currentStreak, forKey: "currentStreak")
        defaults.set(todaySessions, forKey: "todaySessions")
    }
    
    // MARK: - Request Sync from Phone
    
    func requestSync() {
        guard let wcSession = session,
              wcSession.activationState == .activated,
              wcSession.isReachable else { return }
        
        wcSession.sendMessage(["action": "requestSync"], replyHandler: nil)
    }
    
    // MARK: - Send Session to Phone
    
    func sendSessionToPhone(_ session: WatchSession) {
        guard let wcSession = self.session,
              wcSession.activationState == .activated else {
            // Store locally if not connected
            localSessions.append(session)
            return
        }
        
        let sessionData: [String: Any] = [
            "action": "newSession",
            "id": session.id.uuidString,
            "type": session.type.rawValue,
            "date": session.date.timeIntervalSince1970,
            "duration": session.duration,
            "heartRate": session.heartRate as Any
        ]
        
        // Use transferUserInfo for reliable delivery even when phone is not reachable
        wcSession.transferUserInfo(sessionData)
        
        // Update local count
        todaySessions += 1
        
        // Play success haptic
        WKInterfaceDevice.current().play(.success)
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isConnected = activationState == .activated
            if activationState == .activated {
                self.requestSync()
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isConnected = session.isReachable
            if session.isReachable {
                // Send any locally stored sessions
                for localSession in self.localSessions {
                    self.sendSessionToPhone(localSession)
                }
                self.localSessions.removeAll()
            }
        }
    }
    
    // Receive application context from iPhone
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            if let streak = applicationContext["currentStreak"] as? Int {
                self.currentStreak = streak
            }
            if let longest = applicationContext["longestStreak"] as? Int {
                self.longestStreak = longest
            }
            if let today = applicationContext["todaySessions"] as? Int {
                self.todaySessions = today
            }
            if let total = applicationContext["totalSessions"] as? Int {
                self.totalSessions = total
            }
            if let lastUpdate = applicationContext["lastUpdate"] as? TimeInterval {
                self.lastSyncDate = Date(timeIntervalSince1970: lastUpdate)
            }
            
            self.saveToSharedDefaults()
        }
    }
}

// MARK: - Watch Session Model

struct WatchSession: Identifiable {
    let id: UUID
    let type: WatchSessionType
    let date: Date
    let duration: TimeInterval
    var heartRate: Int?
    
    init(type: WatchSessionType, duration: TimeInterval, heartRate: Int? = nil) {
        self.id = UUID()
        self.type = type
        self.date = Date()
        self.duration = duration
        self.heartRate = heartRate
    }
}

enum WatchSessionType: String {
    case cold = "cold"
    case heat = "sauna"
    
    var color: Color {
        self == .cold ? .cyan : .orange
    }
    
    var icon: String {
        self == .cold ? "snowflake" : "flame.fill"
    }
    
    var name: String {
        self == .cold ? "Cold Plunge" : "Sauna"
    }
}

// MARK: - Watch Home View

struct WatchHomeView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    
    @State private var showingColdTimer = false
    @State private var showingSaunaTimer = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header with streak
                    streakHeader
                    
                    // Quick log buttons
                    quickLogButtons
                    
                    // Today's summary
                    todaySummary
                    
                    // Sync status
                    syncStatus
                }
                .padding()
            }
            .navigationTitle("Plunge & Heat")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingColdTimer) {
            WatchTimerView(sessionType: .cold)
                .environmentObject(sessionManager)
        }
        .sheet(isPresented: $showingSaunaTimer) {
            WatchTimerView(sessionType: .heat)
                .environmentObject(sessionManager)
        }
        .onAppear {
            sessionManager.requestSync()
        }
    }
    
    // MARK: - Streak Header
    
    private var streakHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("\(sessionManager.currentStreak)")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("day streak")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Best streak badge
            if sessionManager.longestStreak > 0 {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(sessionManager.longestStreak)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    Text("best")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.2))
        )
    }
    
    // MARK: - Quick Log Buttons
    
    private var quickLogButtons: some View {
        HStack(spacing: 12) {
            // Cold Plunge
            Button(action: { showingColdTimer = true }) {
                VStack(spacing: 8) {
                    Image(systemName: "snowflake")
                        .font(.title2)
                    Text("Cold")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cyan.opacity(0.3))
                )
            }
            .buttonStyle(.plain)
            
            // Sauna
            Button(action: { showingSaunaTimer = true }) {
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                    Text("Sauna")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.3))
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Today's Summary
    
    private var todaySummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.caption)
                .foregroundColor(.gray)
            
            if sessionManager.todaySessions > 0 {
                Text("\(sessionManager.todaySessions) session\(sessionManager.todaySessions == 1 ? "" : "s")")
                    .font(.headline)
                    .foregroundColor(.white)
            } else {
                Text("No sessions yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Sync Status
    
    private var syncStatus: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(sessionManager.isConnected ? Color.green : Color.red)
                .frame(width: 6, height: 6)
            
            Text(sessionManager.isConnected ? "Connected" : "Offline")
                .font(.caption2)
                .foregroundColor(.gray)
            
            Spacer()
            
            if let lastSync = sessionManager.lastSyncDate {
                Text(lastSync, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Watch Timer View

struct WatchTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sessionManager: WatchSessionManager
    
    let sessionType: WatchSessionType
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var currentHeartRate: Int?
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Session type indicator
            HStack {
                Image(systemName: sessionType.icon)
                    .foregroundColor(sessionType.color)
                Text(sessionType.name)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Timer display
            Text(formatTime(elapsedTime))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(sessionType.color)
                .monospacedDigit()
            
            // Heart rate
            if let hr = currentHeartRate {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(hr)")
                        .foregroundColor(.white)
                }
                .font(.headline)
            }
            
            // Control buttons
            HStack(spacing: 16) {
                // Cancel
                Button(action: cancelSession) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.red.opacity(0.8)))
                }
                .buttonStyle(.plain)
                
                // Start/Pause
                Button(action: toggleTimer) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(sessionType.color))
                }
                .buttonStyle(.plain)
                
                // Save
                Button(action: saveSession) {
                    Image(systemName: "checkmark")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.green.opacity(0.8)))
                }
                .buttonStyle(.plain)
                .disabled(elapsedTime < 10) // Minimum 10 seconds
            }
        }
        .padding()
        .onDisappear {
            timer?.invalidate()
        }
        .alert("Session Saved!", isPresented: $showingSaveConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("\(formatTime(elapsedTime)) logged successfully")
        }
    }
    
    private func toggleTimer() {
        if isRunning {
            timer?.invalidate()
            timer = nil
        } else {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                elapsedTime += 1
            }
        }
        isRunning.toggle()
        WKInterfaceDevice.current().play(.click)
    }
    
    private func cancelSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        WKInterfaceDevice.current().play(.failure)
        dismiss()
    }
    
    private func saveSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        
        // Create and send session
        let session = WatchSession(
            type: sessionType,
            duration: elapsedTime,
            heartRate: currentHeartRate
        )
        
        sessionManager.sendSessionToPhone(session)
        showingSaveConfirmation = true
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    WatchHomeView()
        .environmentObject(WatchSessionManager.shared)
}
