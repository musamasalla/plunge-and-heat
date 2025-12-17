//
//  PlungeHeatWatchApp.swift
//  Plunge & Heat Watch App
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI
import WatchKit

@main
struct PlungeHeatWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}

// MARK: - Watch Home View

struct WatchHomeView: View {
    @State private var currentStreak = 7
    @State private var todaySessions = 0
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
                }
                .padding()
            }
            .navigationTitle("Plunge & Heat")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingColdTimer) {
            WatchTimerView(sessionType: .cold)
        }
        .sheet(isPresented: $showingSaunaTimer) {
            WatchTimerView(sessionType: .heat)
        }
    }
    
    // MARK: - Streak Header
    
    private var streakHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("\(currentStreak)")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("day streak")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
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
            
            if todaySessions > 0 {
                Text("\(todaySessions) session\(todaySessions == 1 ? "" : "s")")
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
}

// MARK: - Watch Timer View

struct WatchTimerView: View {
    @Environment(\.dismiss) private var dismiss
    
    enum SessionType {
        case cold, heat
        
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
    
    let sessionType: SessionType
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var currentHeartRate: Int?
    
    var body: some View {
        VStack(spacing: 20) {
            // Timer display
            Text(formatTime(elapsedTime))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(sessionType.color)
            
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
            HStack(spacing: 20) {
                // Stop/Cancel
                Button(action: stopSession) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.red.opacity(0.8)))
                }
                .buttonStyle(.plain)
                
                // Start/Pause
                Button(action: toggleTimer) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(sessionType.color))
                }
                .buttonStyle(.plain)
                
                // Save
                Button(action: saveSession) {
                    Image(systemName: "checkmark")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.green.opacity(0.8)))
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(sessionType.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            timer?.invalidate()
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
    
    private func stopSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        dismiss()
    }
    
    private func saveSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        
        // Save session to shared container
        // This would sync with the iOS app via WatchConnectivity
        WKInterfaceDevice.current().play(.success)
        
        dismiss()
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
}
