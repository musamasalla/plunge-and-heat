//
//  ContentView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

// MARK: - Content View

struct ContentView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var selectedTab = 0
    @State private var showingCelebration = false
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                // Loading screen
                ZStack {
                    AppTheme.background.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.coldPrimary, AppTheme.heatPrimary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "snowflake")
                                    .font(.system(size: 24))
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 24))
                            }
                            .foregroundColor(.white)
                        }
                        
                        Text("Plunge & Heat")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.coldPrimary))
                    }
                }
            } else if !settings.hasCompletedOnboarding {
                OnboardingView()
            } else {
                mainTabView
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Small delay to ensure everything is loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Main Tab View
    
    private var mainTabView: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("Log", systemImage: "plus.circle.fill")
                    }
                    .tag(0)
                
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "calendar")
                    }
                    .tag(1)
                
                InsightsView()
                    .tabItem {
                        Label("Insights", systemImage: "chart.bar.fill")
                    }
                    .tag(2)
                
                SettingsContainerView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(AppTheme.coldPrimary)
            
            // Celebration overlay
            if showingCelebration {
                ConfettiView()
                    .allowsHitTesting(false)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showingCelebration = false
                        }
                    }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .streakMilestone)) { notification in
            if let streak = notification.object as? Int, streak > 0 && streak % 7 == 0 {
                showingCelebration = true
                HapticFeedback.success()
            }
        }
    }
}

// MARK: - Settings Container View (for tab navigation)

struct SettingsContainerView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                SettingsContentView()
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Settings Content View

struct SettingsContentView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var dataManager = DataManager.shared
    
    @State private var showingExportSheet = false
    @State private var showingPaywall = false
    @State private var showingResetAlert = false
    @State private var exportURL: URL?
    
    var body: some View {
        List {
            // Account Section
            Section {
                if subscriptionManager.isPremium {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        
                        VStack(alignment: .leading) {
                            Text("Premium Member")
                                .font(.headline)
                            Text("You have access to all features")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                } else {
                    Button(action: {
                        showingPaywall = true
                    }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            
                            VStack(alignment: .leading) {
                                Text("Upgrade to Premium")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Unlimited sessions & more")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.textTertiary)
                        }
                    }
                }
            } header: {
                Text("Account")
            }
            .listRowBackground(AppTheme.cardBackground)
            
            // Preferences Section
            Section {
                Picker("Temperature", selection: $settings.temperatureUnit) {
                    Text("Fahrenheit").tag(TemperatureUnit.fahrenheit)
                    Text("Celsius").tag(TemperatureUnit.celsius)
                }
                
                Toggle(isOn: $settings.hapticFeedbackEnabled) {
                    Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                }
                .tint(AppTheme.coldPrimary)
                
                Toggle(isOn: $settings.breathingGuideEnabled) {
                    Label("Breathing Guide", systemImage: "wind")
                }
                .tint(AppTheme.coldPrimary)
            } header: {
                Text("Preferences")
            }
            .listRowBackground(AppTheme.cardBackground)
            
            // Notifications Section
            Section {
                Toggle(isOn: $settings.dailyReminderEnabled) {
                    Label("Daily Reminder", systemImage: "bell.fill")
                }
                .tint(AppTheme.coldPrimary)
                .onChange(of: settings.dailyReminderEnabled) { _, enabled in
                    if enabled {
                        NotificationManager.shared.scheduleDailyReminder(at: settings.dailyReminderTime)
                    } else {
                        NotificationManager.shared.cancelDailyReminder()
                    }
                }
                
                if settings.dailyReminderEnabled {
                    DatePicker("Time", selection: $settings.dailyReminderTime, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Notifications")
            }
            .listRowBackground(AppTheme.cardBackground)
            
            // Health Section
            Section {
                HStack {
                    Label("Apple Health", systemImage: "heart.text.square.fill")
                    Spacer()
                    Text(healthKit.isAuthorized ? "Connected" : "Not Connected")
                        .font(.caption)
                        .foregroundColor(healthKit.isAuthorized ? .green : AppTheme.textSecondary)
                }
            } header: {
                Text("Health")
            }
            .listRowBackground(AppTheme.cardBackground)
            
            // Data Section
            Section {
                Button(action: exportData) {
                    HStack {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                        Spacer()
                        if !subscriptionManager.isPremium {
                            PremiumBadge()
                        }
                    }
                }
                .disabled(!subscriptionManager.canAccess(feature: .exportData))
                
                Button(action: restorePurchases) {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                }
                
                Button(role: .destructive, action: { showingResetAlert = true }) {
                    Label("Reset All Data", systemImage: "trash")
                }
            } header: {
                Text("Data")
            }
            .listRowBackground(AppTheme.cardBackground)
            
            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Link(destination: URL(string: "https://plungeheat.app")!) {
                    HStack {
                        Text("Website")
                        Spacer()
                        Image(systemName: "safari")
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                
                Link(destination: URL(string: "mailto:support@plungeheat.app")!) {
                    HStack {
                        Text("Contact Support")
                        Spacer()
                        Image(systemName: "envelope")
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
            } header: {
                Text("About")
            } footer: {
                Text("Made with ❄️ and 🔥 • © 2025 Plunge & Heat")
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
            }
            .listRowBackground(AppTheme.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Reset All Data?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { resetAllData() }
        } message: {
            Text("This will delete all sessions and progress.")
        }
    }
    
    private func exportData() {
        if let url = DataManager.shared.exportSessionsToCSV() {
            exportURL = url
            showingExportSheet = true
        }
    }
    
    private func restorePurchases() {
        Task { try? await subscriptionManager.restorePurchases() }
    }
    
    private func resetAllData() {
        DataManager.shared.resetAllData()
        SettingsManager.shared.resetAllData()
        HapticFeedback.warning()
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Notification Names

extension Notification.Name {
    static let streakMilestone = Notification.Name("streakMilestone")
    static let sessionLogged = Notification.Name("sessionLogged")
}

// MARK: - Preview

#Preview {
    ContentView()
}
