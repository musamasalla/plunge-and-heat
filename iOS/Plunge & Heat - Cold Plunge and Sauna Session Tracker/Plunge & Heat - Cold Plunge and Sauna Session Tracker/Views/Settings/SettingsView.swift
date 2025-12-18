//
//  SettingsView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var dataManager = DataManager.shared
    
    @State private var showingExportOptions = false
    @State private var showingResetConfirmation = false
    @State private var showingPaywall = false
    @State private var animateContent = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile/Premium Section
                        premiumSection
                        
                        // Preferences Section
                        preferencesSection
                        
                        // Health Section
                        healthSection
                        
                        // Notifications Section
                        notificationsSection
                        
                        // Data Section
                        dataSection
                        
                        // About Section
                        aboutSection
                        
                        // App Info
                        appInfoFooter
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .alert("Reset All Data", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will delete all your sessions, goals, and achievements. This action cannot be undone.")
            }
            .onAppear {
                withAnimation(.spring().delay(0.2)) {
                    animateContent = true
                }
            }
        }
    }
    
    // MARK: - Premium Section
    
    private var premiumSection: some View {
        VStack(spacing: 0) {
            if subscriptionManager.isPremium {
                // Premium user
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Premium Member")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("All features unlocked")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                // Free user - upgrade prompt
                Button(action: { showingPaywall = true }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.cardBackground)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "crown")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upgrade to Premium")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Unlock all features")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.cardBackground)
                    )
                }
            }
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        SettingsSection(title: "Preferences", icon: "gearshape.fill", color: .gray) {
            // Temperature Unit
            SettingsRow(
                icon: "thermometer.medium",
                title: "Temperature Unit",
                color: .blue
            ) {
                Picker("", selection: $settings.temperatureUnit) {
                    Text("°F").tag(TemperatureUnit.fahrenheit)
                    Text("°C").tag(TemperatureUnit.celsius)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
            
            Divider().background(AppTheme.surfaceBackground)
            
            // Haptic Feedback
            SettingsToggleRow(
                icon: "waveform",
                title: "Haptic Feedback",
                color: .purple,
                isOn: $settings.hapticFeedbackEnabled
            )
            
            Divider().background(AppTheme.surfaceBackground)
            
            // Sound Effects
            SettingsToggleRow(
                icon: "speaker.wave.2.fill",
                title: "Sound Effects",
                color: .green,
                isOn: .constant(true)
            )
        }
    }
    
    // MARK: - Health Section
    
    private var healthSection: some View {
        SettingsSection(title: "Health", icon: "heart.fill", color: .red) {
            // HealthKit Status
            SettingsRow(
                icon: "heart.text.square.fill",
                title: "Apple Health",
                color: .pink
            ) {
                if healthKit.isAuthorized {
                    Text("Connected")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Button("Connect") {
                        Task {
                            try? await healthKit.requestAuthorization()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.coldPrimary)
                }
            }
            
            if healthKit.isAuthorized {
                Divider().background(AppTheme.surfaceBackground)
                
                // Auto-fetch heart rate
                SettingsToggleRow(
                    icon: "heart.circle.fill",
                    title: "Auto-fetch Heart Rate",
                    color: .red,
                    isOn: .constant(true)
                )
                
                Divider().background(AppTheme.surfaceBackground)
                
                // Save to Mindful Minutes
                SettingsToggleRow(
                    icon: "brain.head.profile",
                    title: "Save to Mindful Minutes",
                    color: .cyan,
                    isOn: .constant(true)
                )
            }
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        SettingsSection(title: "Notifications", icon: "bell.fill", color: .orange) {
            // Daily Reminder
            SettingsToggleRow(
                icon: "clock.fill",
                title: "Daily Reminder",
                color: .blue,
                isOn: $settings.dailyReminderEnabled
            )
            
            if settings.dailyReminderEnabled {
                Divider().background(AppTheme.surfaceBackground)
                
                SettingsRow(
                    icon: "alarm.fill",
                    title: "Reminder Time",
                    color: .orange
                ) {
                    DatePicker("", selection: $settings.dailyReminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
            
            Divider().background(AppTheme.surfaceBackground)
            
            // Streak Alerts
            SettingsToggleRow(
                icon: "flame.fill",
                title: "Streak Alerts",
                color: .orange,
                isOn: .constant(true)
            )
            
            Divider().background(AppTheme.surfaceBackground)
            
            // Goal Progress
            SettingsToggleRow(
                icon: "target",
                title: "Goal Progress",
                color: .green,
                isOn: .constant(true)
            )
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        SettingsSection(title: "Data", icon: "externaldrive.fill", color: .blue) {
            // Export Data
            Button(action: { showingExportOptions = true }) {
                SettingsRow(
                    icon: "square.and.arrow.up.fill",
                    title: "Export Data",
                    color: .green
                ) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            
            Divider().background(AppTheme.surfaceBackground)
            
            // Cloud Sync
            SettingsRow(
                icon: "icloud.fill",
                title: "Cloud Sync",
                color: .blue
            ) {
                if subscriptionManager.isPremium {
                    Text("Enabled")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Premium")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            
            Divider().background(AppTheme.surfaceBackground)
            
            // Reset Data
            Button(action: { showingResetConfirmation = true }) {
                SettingsRow(
                    icon: "trash.fill",
                    title: "Reset All Data",
                    color: .red
                ) {
                    EmptyView()
                }
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle.fill", color: .blue) {
            // Rate App
            Button(action: rateApp) {
                SettingsRow(
                    icon: "star.fill",
                    title: "Rate Plunge & Heat",
                    color: .yellow
                ) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            
            Divider().background(AppTheme.surfaceBackground)
            
            // Share App
            Button(action: shareApp) {
                SettingsRow(
                    icon: "square.and.arrow.up",
                    title: "Share with Friends",
                    color: .blue
                ) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            
            Divider().background(AppTheme.surfaceBackground)
            
            // Privacy Policy
            Link(destination: URL(string: "https://plungeheat.app/privacy")!) {
                SettingsRow(
                    icon: "hand.raised.fill",
                    title: "Privacy Policy",
                    color: .purple
                ) {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            
            Divider().background(AppTheme.surfaceBackground)
            
            // Terms of Service
            Link(destination: URL(string: "https://plungeheat.app/terms")!) {
                SettingsRow(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    color: .gray
                ) {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
    }
    
    // MARK: - App Info Footer
    
    private var appInfoFooter: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "snowflake")
                    .foregroundColor(AppTheme.coldPrimary)
                Image(systemName: "flame.fill")
                    .foregroundColor(AppTheme.heatPrimary)
            }
            .font(.title2)
            
            Text("Plunge & Heat")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
            
            Text("Made with ❄️ and 🔥")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Actions
    
    private func resetAllData() {
        dataManager.resetAllData()
        HapticFeedback.warning()
    }
    
    private func rateApp() {
        // Open App Store review
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id123456789?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareApp() {
        let url = URL(string: "https://apps.apple.com/app/id123456789")!
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 0) {
                content
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
            )
        }
    }
}

// MARK: - Settings Row

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder let trailing: Content
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            trailing
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppTheme.coldPrimary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
