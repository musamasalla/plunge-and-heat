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
                // Animated splash screen
                SplashView()
            } else if !settings.hasCompletedOnboarding {
                OnboardingView()
            } else {
                mainTabView
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Delay to show splash animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
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
        SettingsView()
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
