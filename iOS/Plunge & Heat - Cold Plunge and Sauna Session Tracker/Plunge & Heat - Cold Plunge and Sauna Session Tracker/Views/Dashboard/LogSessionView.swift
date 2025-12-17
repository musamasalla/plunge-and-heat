//
//  LogSessionView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI
import PhotosUI

// MARK: - Log Session View

struct LogSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var healthKit = HealthKitManager.shared
    
    let sessionType: SessionType
    
    @State private var mode: SessionMode = .manual
    @State private var duration: TimeInterval = 180 // 3 minutes default
    @State private var temperature: Double = 50
    @State private var heartRate: Int?
    @State private var notes: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    
    // Timer states
    @State private var isTimerRunning = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showBreathingGuide = false
    @State private var currentHeartRate: Int?
    
    // Animation states
    @State private var animateGradient = false
    @State private var showSessionComplete = false
    @State private var savedSession: Session?
    
    enum SessionMode: String, CaseIterable {
        case manual = "Manual Entry"
        case timer = "Live Timer"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background
                sessionBackground
                
                if isTimerRunning {
                    liveTimerView
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Mode selector
                            modeSelector
                            
                            if mode == .manual {
                                manualEntryForm
                            } else {
                                timerSetupView
                            }
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }
                }
                
                // Save button
                if !isTimerRunning {
                    VStack {
                        Spacer()
                        saveButton
                    }
                }
            }
            .navigationTitle(sessionType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            .fullScreenCover(isPresented: $showSessionComplete) {
                if let session = savedSession {
                    SessionCompleteView(
                        session: session,
                        isNewStreak: settings.currentStreak == 1,
                        streakCount: settings.currentStreak
                    )
                }
            }
            .onAppear {
                setupDefaults()
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    animateGradient = true
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    // MARK: - Background
    
    private var sessionBackground: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            Circle()
                .fill(sessionType.primaryColor.opacity(0.15))
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: animateGradient ? -30 : 30, y: animateGradient ? -100 : -50)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Mode Selector
    
    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach(SessionMode.allCases, id: \.self) { sessionMode in
                Button(action: {
                    HapticFeedback.light()
                    withAnimation(.spring()) {
                        mode = sessionMode
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: sessionMode == .manual ? "pencil" : "timer")
                            .font(.subheadline)
                        Text(sessionMode.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(mode == sessionMode ? .white : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        mode == sessionMode ?
                        sessionType.gradient :
                        LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding(4)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Manual Entry Form
    
    private var manualEntryForm: some View {
        VStack(spacing: 20) {
            // Duration
            FormCard(title: "Duration", icon: "clock.fill", color: sessionType.primaryColor) {
                VStack(spacing: 16) {
                    // Quick buttons
                    HStack(spacing: 12) {
                        ForEach([60, 120, 180, 300, 600], id: \.self) { seconds in
                            QuickDurationButton(
                                seconds: seconds,
                                isSelected: Int(duration) == seconds,
                                color: sessionType.primaryColor
                            ) {
                                HapticFeedback.light()
                                withAnimation(.spring()) {
                                    duration = TimeInterval(seconds)
                                }
                            }
                        }
                    }
                    
                    // Custom stepper
                    HStack {
                        Button(action: { if duration > 10 { duration -= 10 } }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(sessionType.primaryColor)
                        }
                        
                        Spacer()
                        
                        Text(formatDuration(duration))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { duration += 10 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(sessionType.primaryColor)
                        }
                    }
                }
            }
            
            // Temperature
            FormCard(title: "Temperature", icon: "thermometer.medium", color: sessionType.primaryColor) {
                VStack(spacing: 16) {
                    // Quick suggestions
                    HStack(spacing: 12) {
                        ForEach(temperatureSuggestions, id: \.self) { temp in
                            QuickTempButton(
                                temp: temp,
                                unit: settings.temperatureUnit,
                                isSelected: Int(temperature) == temp,
                                color: sessionType.primaryColor
                            ) {
                                HapticFeedback.light()
                                withAnimation(.spring()) {
                                    temperature = Double(temp)
                                }
                            }
                        }
                    }
                    
                    // Slider
                    VStack(spacing: 8) {
                        Slider(
                            value: $temperature,
                            in: temperatureRange,
                            step: 1
                        )
                        .tint(sessionType.primaryColor)
                        
                        Text("\(Int(temperature))°\(settings.temperatureUnit.symbol)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Heart Rate (optional)
            FormCard(title: "Heart Rate", icon: "heart.fill", color: .red) {
                HStack {
                    TextField("Optional", value: $heartRate, format: .number)
                        .keyboardType(.numberPad)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("BPM")
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    if healthKit.isAuthorized {
                        Button("Fetch") {
                            Task {
                                if let hr = try? await healthKit.fetchLatestHeartRate() {
                                    heartRate = Int(hr)
                                }
                            }
                        }
                        .font(.caption)
                        .foregroundColor(sessionType.primaryColor)
                    }
                }
            }
            
            // Notes
            FormCard(title: "Notes", icon: "note.text", color: .purple) {
                TextField("How did it feel?", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .foregroundColor(.white)
            }
            
            // Photo
            FormCard(title: "Photo", icon: "camera.fill", color: .orange) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        if photoData != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Photo added")
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "plus.circle")
                                .foregroundColor(sessionType.primaryColor)
                            Text("Add photo")
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                    }
                }
                .onChange(of: selectedPhoto) { _, item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self) {
                            photoData = data
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Timer Setup View
    
    private var timerSetupView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Big timer display
            ZStack {
                Circle()
                    .stroke(sessionType.gradient, lineWidth: 6)
                    .frame(width: 250, height: 250)
                
                VStack(spacing: 8) {
                    Text("Ready to start")
                        .font(.headline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text("00:00")
                        .font(.system(size: 64, weight: .thin, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
            }
            
            // Start button
            Button(action: startTimer) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("Start Session")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(sessionType.gradient)
                .cornerRadius(16)
                .shadow(color: sessionType.primaryColor.opacity(0.4), radius: 15, y: 8)
            }
            .padding(.horizontal, 40)
            
            // Tips
            VStack(spacing: 8) {
                Text("💡 Tip")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textSecondary)
                
                Text(sessionType == .coldPlunge ?
                     "Focus on your breath. The first minute is the hardest." :
                     "Start at a lower temperature and work your way up.")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Live Timer View
    
    private var liveTimerView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Timer display with breathing guide
            ZStack {
                // Pulsing ring
                Circle()
                    .stroke(sessionType.gradient, lineWidth: 8)
                    .frame(width: 280, height: 280)
                    .scaleEffect(animateGradient ? 1.02 : 1.0)
                
                VStack(spacing: 16) {
                    Text(formatDuration(elapsedTime))
                        .font(.system(size: 72, weight: .thin, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                    
                    if let hr = currentHeartRate {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("\(hr) BPM")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(AppTheme.cardBackground))
                    }
                }
            }
            
            // Breathing guide toggle
            if settings.breathingGuideEnabled {
                Button(action: { showBreathingGuide.toggle() }) {
                    HStack {
                        Image(systemName: showBreathingGuide ? "wind.circle.fill" : "wind.circle")
                        Text(showBreathingGuide ? "Hide Breathing Guide" : "Show Breathing Guide")
                    }
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            // Breathing guide
            if showBreathingGuide {
                BreathingGuideView(technique: .boxBreathing)
                    .frame(height: 200)
            }
            
            Spacer()
            
            // Control buttons
            HStack(spacing: 20) {
                // Emergency exit
                Button(action: emergencyExit) {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 50))
                        Text("Exit")
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                }
                
                Spacer()
                
                // Stop & Save
                Button(action: stopAndSave) {
                    VStack(spacing: 8) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 60))
                        Text("Stop & Save")
                            .font(.caption)
                    }
                    .foregroundColor(sessionType.primaryColor)
                }
                
                Spacer()
                
                // Add minute
                Button(action: { /* Could add lap markers */ }) {
                    VStack(spacing: 8) {
                        Image(systemName: "flag.circle.fill")
                            .font(.system(size: 50))
                        Text("Mark")
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button(action: saveSession) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                Text("Save Session")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(sessionType.gradient)
            .cornerRadius(16)
            .shadow(color: sessionType.primaryColor.opacity(0.4), radius: 15, y: 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    // MARK: - Helper Methods
    
    private func setupDefaults() {
        temperature = sessionType == .coldPlunge ? 50 : 170
    }
    
    private var temperatureSuggestions: [Int] {
        if sessionType == .coldPlunge {
            return settings.temperatureUnit == .celsius ? [5, 10, 15] : [40, 50, 60]
        } else {
            return settings.temperatureUnit == .celsius ? [70, 80, 90] : [160, 180, 200]
        }
    }
    
    private var temperatureRange: ClosedRange<Double> {
        if sessionType == .coldPlunge {
            return settings.temperatureUnit == .celsius ? 0...20 : 32...68
        } else {
            return settings.temperatureUnit == .celsius ? 60...100 : 140...212
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func startTimer() {
        HapticFeedback.medium()
        isTimerRunning = true
        elapsedTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
            
            // Haptic every minute
            if Int(elapsedTime) % 60 == 0 && settings.hapticFeedbackEnabled {
                HapticFeedback.medium()
            }
            
            // Fetch heart rate periodically
            if Int(elapsedTime) % 30 == 0 && healthKit.isAuthorized {
                Task {
                    if let hr = try? await healthKit.fetchLatestHeartRate() {
                        currentHeartRate = Int(hr)
                    }
                }
            }
        }
    }
    
    private func stopAndSave() {
        timer?.invalidate()
        duration = elapsedTime
        saveSession()
    }
    
    private func emergencyExit() {
        timer?.invalidate()
        HapticFeedback.warning()
        dismiss()
    }
    
    private func saveSession() {
        let session = Session(
            type: sessionType,
            date: Date(),
            duration: duration,
            temperature: temperature,
            temperatureUnit: settings.temperatureUnit,
            heartRate: heartRate ?? currentHeartRate,
            notes: notes.isEmpty ? nil : notes,
            photoData: photoData
        )
        
        dataManager.addSession(session)
        savedSession = session
        HapticFeedback.success()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showSessionComplete = true
        }
    }
}

// MARK: - Form Card

struct FormCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
    }
}

// MARK: - Quick Duration Button

struct QuickDurationButton: View {
    let seconds: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(formatLabel)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : AppTheme.surfaceBackground)
                )
        }
    }
    
    private var formatLabel: String {
        if seconds < 60 { return "\(seconds)s" }
        return "\(seconds / 60)m"
    }
}

// MARK: - Quick Temp Button

struct QuickTempButton: View {
    let temp: Int
    let unit: TemperatureUnit
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(temp)°")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? color : AppTheme.surfaceBackground)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    LogSessionView(sessionType: .coldPlunge)
}
