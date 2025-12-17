//
//  OnboardingView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var currentPage = 0
    @State private var selectedUnit: TemperatureUnit = .fahrenheit
    @State private var animateBackground = false
    
    private let totalPages = 5
    
    var body: some View {
        ZStack {
            // Animated background
            animatedBackground
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button("Skip") {
                            withAnimation(.spring()) {
                                currentPage = totalPages - 1
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding()
                    }
                }
                .frame(height: 50)
                
                // Page content
                TabView(selection: $currentPage) {
                    WelcomePageEnhanced()
                        .tag(0)
                    
                    ProgressTrackingPageEnhanced()
                        .tag(1)
                    
                    WatchIntegrationPageEnhanced()
                        .tag(2)
                    
                    HealthKitPageEnhanced()
                        .tag(3)
                    
                    TemperatureUnitPageEnhanced(selectedUnit: $selectedUnit)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Bottom section
                VStack(spacing: 20) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? AppTheme.coldPrimary : AppTheme.textTertiary.opacity(0.3))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    
                    // Next/Get Started button
                    Button(action: handleNextButton) {
                        HStack {
                            Text(currentPage == totalPages - 1 ? "Get Started" : "Continue")
                                .font(.headline)
                            
                            Image(systemName: currentPage == totalPages - 1 ? "arrow.right.circle.fill" : "arrow.right")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.coldPrimary, AppTheme.coldSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: AppTheme.coldPrimary.opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animateBackground = true
            }
        }
    }
    
    private var animatedBackground: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            // Gradient orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.coldPrimary.opacity(0.25), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: animateBackground ? -80 : 80, y: animateBackground ? -150 : -50)
                .blur(radius: 1)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.heatPrimary.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: animateBackground ? 100 : -50, y: animateBackground ? 300 : 400)
                .blur(radius: 1)
        }
        .ignoresSafeArea()
    }
    
    private func handleNextButton() {
        HapticFeedback.medium()
        if currentPage < totalPages - 1 {
            withAnimation(.spring()) {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        settings.temperatureUnit = selectedUnit
        settings.hasCompletedOnboarding = true
        HapticFeedback.success()
    }
}

// MARK: - Welcome Page Enhanced

struct WelcomePageEnhanced: View {
    @State private var iconScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    @State private var featuresOffset: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated Icon
            ZStack {
                // Outer glow rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.coldPrimary, AppTheme.heatPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 140 + CGFloat(i * 30), height: 140 + CGFloat(i * 30))
                        .opacity(0.3 - Double(i) * 0.1)
                        .scaleEffect(iconScale)
                }
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.coldPrimary, AppTheme.heatPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: AppTheme.coldPrimary.opacity(0.5), radius: 20, y: 10)
                    .scaleEffect(iconScale)
                
                HStack(spacing: 8) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 32, weight: .medium))
                    Image(systemName: "flame.fill")
                        .font(.system(size: 32, weight: .medium))
                }
                .foregroundColor(.white)
                .scaleEffect(iconScale)
            }
            
            VStack(spacing: 12) {
                Text("Plunge & Heat")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Master the elements")
                    .font(.title3)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .opacity(textOpacity)
            
            // Features
            VStack(spacing: 20) {
                OnboardingFeatureItem(
                    icon: "bolt.fill",
                    title: "Quick Logging",
                    description: "Log sessions in seconds",
                    color: .yellow
                )
                
                OnboardingFeatureItem(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Progress",
                    description: "Watch your tolerance grow",
                    color: .green
                )
                
                OnboardingFeatureItem(
                    icon: "flame.fill",
                    title: "Build Streaks",
                    description: "Stay consistent daily",
                    color: .orange
                )
            }
            .padding(.horizontal, 32)
            .offset(y: featuresOffset)
            .opacity(textOpacity)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                textOpacity = 1.0
                featuresOffset = 0
            }
        }
    }
}

// MARK: - Onboarding Feature Item

struct OnboardingFeatureItem: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Progress Tracking Page Enhanced

struct ProgressTrackingPageEnhanced: View {
    @State private var chartBars: [CGFloat] = [0, 0, 0, 0, 0, 0, 0]
    @State private var statsOpacity: Double = 0
    
    private let targetHeights: [CGFloat] = [40, 65, 50, 80, 55, 90, 70]
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Chart visualization
            VStack(spacing: 20) {
                // Animated chart
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(0..<7, id: \.self) { index in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: index % 2 == 0 ? 
                                            [AppTheme.coldPrimary, AppTheme.coldSecondary] :
                                            [AppTheme.heatPrimary, AppTheme.heatSecondary],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 32, height: chartBars[index])
                            
                            Text(["M", "T", "W", "T", "F", "S", "S"][index])
                                .font(.caption2)
                                .foregroundColor(AppTheme.textTertiary)
                        }
                    }
                }
                .frame(height: 120)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppTheme.cardBackground)
                )
                
                // Stats row
                HStack(spacing: 20) {
                    MiniStatBubble(value: "7", label: "Day Streak", icon: "flame.fill", color: .orange)
                    MiniStatBubble(value: "23", label: "Sessions", icon: "number", color: AppTheme.coldPrimary)
                    MiniStatBubble(value: "85%", label: "Goal Hit", icon: "target", color: .green)
                }
                .opacity(statsOpacity)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                Text("Watch Your Progress")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Beautiful charts and statistics help you visualize your journey and stay motivated.")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(statsOpacity)
            
            Spacer()
        }
        .onAppear {
            animateCharts()
        }
    }
    
    private func animateCharts() {
        for i in 0..<7 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(i) * 0.1)) {
                chartBars[i] = targetHeights[i]
            }
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            statsOpacity = 1.0
        }
    }
}

// MARK: - Mini Stat Bubble

struct MiniStatBubble: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
        )
    }
}

// MARK: - Watch Integration Page Enhanced

struct WatchIntegrationPageEnhanced: View {
    @State private var watchScale: CGFloat = 0.8
    @State private var heartBeat = false
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Watch illustration
            ZStack {
                // Glow
                Circle()
                    .fill(AppTheme.coldPrimary.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                
                // Watch body
                RoundedRectangle(cornerRadius: 32)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.2), Color(white: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 170)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                
                // Watch screen
                VStack(spacing: 12) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .scaleEffect(heartBeat ? 1.2 : 1.0)
                        
                        Text("72")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .scaleEffect(watchScale)
            
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("Apple Watch")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("PRO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.yellow.opacity(0.2)))
                }
                
                Text("Start sessions from your wrist with real-time heart rate monitoring and haptic countdown alerts.")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(contentOpacity)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                watchScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                contentOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                heartBeat = true
            }
        }
    }
}

// MARK: - HealthKit Page Enhanced

struct HealthKitPageEnhanced: View {
    @StateObject private var healthKit = HealthKitManager.shared
    @State private var isRequesting = false
    @State private var ringProgress: [Double] = [0, 0, 0]
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Health rings
            ZStack {
                // HRV ring
                Circle()
                    .stroke(Color.purple.opacity(0.3), lineWidth: 12)
                    .frame(width: 180, height: 180)
                Circle()
                    .trim(from: 0, to: ringProgress[0])
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                
                // Heart rate ring
                Circle()
                    .stroke(Color.red.opacity(0.3), lineWidth: 12)
                    .frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: ringProgress[1])
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                
                // Sleep ring
                Circle()
                    .stroke(AppTheme.coldPrimary.opacity(0.3), lineWidth: 12)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: ringProgress[2])
                    .stroke(AppTheme.coldPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.pink)
            }
            
            VStack(spacing: 12) {
                Text("Health Insights")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("See how cold and heat therapy affects your heart rate variability, resting heart rate, and sleep quality.")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(contentOpacity)
            
            // Connect button
            Button(action: requestHealthAccess) {
                HStack(spacing: 8) {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: healthKit.isAuthorized ? "checkmark.circle.fill" : "heart.fill")
                        Text(healthKit.isAuthorized ? "Connected" : "Connect Apple Health")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(healthKit.isAuthorized ? Color.green : Color.pink)
                .cornerRadius(14)
                .shadow(color: (healthKit.isAuthorized ? Color.green : Color.pink).opacity(0.4), radius: 10, y: 5)
            }
            .disabled(isRequesting || healthKit.isAuthorized)
            .opacity(contentOpacity)
            
            Text("Optional • Can be changed later")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
                .opacity(contentOpacity)
            
            Spacer()
        }
        .onAppear {
            animateRings()
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                contentOpacity = 1.0
            }
        }
    }
    
    private func animateRings() {
        withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
            ringProgress[0] = 0.7
        }
        withAnimation(.easeOut(duration: 1.0).delay(0.4)) {
            ringProgress[1] = 0.85
        }
        withAnimation(.easeOut(duration: 1.0).delay(0.6)) {
            ringProgress[2] = 0.6
        }
    }
    
    private func requestHealthAccess() {
        isRequesting = true
        Task {
            try? await healthKit.requestAuthorization()
            isRequesting = false
        }
    }
}

// MARK: - Temperature Unit Page Enhanced

struct TemperatureUnitPageEnhanced: View {
    @Binding var selectedUnit: TemperatureUnit
    @State private var thermometerOffset: CGFloat = 50
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Thermometer illustration
            ZStack {
                // Glow
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.coldPrimary.opacity(0.3), AppTheme.heatPrimary.opacity(0.3)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 150, height: 150)
                    .blur(radius: 30)
                
                Image(systemName: "thermometer.variable.and.figure")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.coldPrimary, AppTheme.heatPrimary],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }
            .offset(y: thermometerOffset)
            
            VStack(spacing: 12) {
                Text("Temperature Unit")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Choose how you'd like to see temperatures displayed.")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(contentOpacity)
            
            // Unit selection
            HStack(spacing: 16) {
                TemperatureUnitCard(
                    unit: .fahrenheit,
                    example: "50°F",
                    subtitle: "Common in US",
                    isSelected: selectedUnit == .fahrenheit
                ) {
                    HapticFeedback.light()
                    withAnimation(.spring()) {
                        selectedUnit = .fahrenheit
                    }
                }
                
                TemperatureUnitCard(
                    unit: .celsius,
                    example: "10°C",
                    subtitle: "Used worldwide",
                    isSelected: selectedUnit == .celsius
                ) {
                    HapticFeedback.light()
                    withAnimation(.spring()) {
                        selectedUnit = .celsius
                    }
                }
            }
            .padding(.horizontal, 24)
            .opacity(contentOpacity)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                thermometerOffset = 0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                contentOpacity = 1.0
            }
        }
    }
}

// MARK: - Temperature Unit Card

struct TemperatureUnitCard: View {
    let unit: TemperatureUnit
    let example: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Text(unit == .fahrenheit ? "°F" : "°C")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                
                VStack(spacing: 4) {
                    Text(unit.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : AppTheme.textTertiary)
                }
                
                Text("e.g. \(example)")
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : AppTheme.textTertiary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white.opacity(0.2) : AppTheme.surfaceBackground)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isSelected ? 
                        LinearGradient(colors: [AppTheme.coldPrimary, AppTheme.coldSecondary], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [AppTheme.cardBackground, AppTheme.cardBackground], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(isSelected ? Color.clear : AppTheme.textTertiary.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: isSelected ? AppTheme.coldPrimary.opacity(0.4) : Color.clear, radius: 15, y: 8)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
