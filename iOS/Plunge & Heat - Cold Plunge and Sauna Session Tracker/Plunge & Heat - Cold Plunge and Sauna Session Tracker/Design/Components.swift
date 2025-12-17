//
//  Components.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

// MARK: - Session Button

struct SessionButton: View {
    let sessionType: SessionType
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action()
        }) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(sessionType.gradient)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: sessionType.icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text("Log \(sessionType.displayName)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXLarge)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXLarge)
                            .stroke(sessionType.primaryColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(SessionButtonStyle(sessionType: sessionType))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let iconName: String
    let color: Color
    
    init(title: String, value: String, subtitle: String? = nil, iconName: String, color: Color = AppTheme.coldPrimary) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.iconName = iconName
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusLarge)
    }
}

// MARK: - Streak Badge

struct StreakBadge: View {
    let streak: Int
    let isLarge: Bool
    
    init(streak: Int, isLarge: Bool = false) {
        self.streak = streak
        self.isLarge = isLarge
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
                .font(isLarge ? .title2 : .subheadline)
            
            Text("\(streak)")
                .font(isLarge ? .title2 : .subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if isLarge {
                Text("day streak")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, isLarge ? 16 : 12)
        .padding(.vertical, isLarge ? 10 : 6)
        .background(
            Capsule()
                .fill(AppTheme.cardBackground)
                .overlay(
                    Capsule()
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Timer Display

struct TimerDisplay: View {
    let elapsedTime: TimeInterval
    let sessionType: SessionType
    let heartRate: Int?
    
    var body: some View {
        VStack(spacing: 20) {
            // Timer
            Text(formatTime(elapsedTime))
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
            
            // Heart Rate (if available)
            if let hr = heartRate {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(hr) BPM")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(AppTheme.cardBackground)
                )
            }
        }
        .padding(40)
        .background(
            Circle()
                .stroke(sessionType.gradient, lineWidth: 4)
                .frame(width: 280, height: 280)
        )
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Breathing Guide Overlay

struct BreathingGuideView: View {
    let technique: BreathingTechnique
    @State private var phase: BreathingPhase = .inhale
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.6
    
    enum BreathingPhase: String {
        case inhale = "Breathe In"
        case hold = "Hold"
        case exhale = "Breathe Out"
        case holdAfter = "Rest"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.coldPrimary.opacity(0.3))
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: currentPhaseDuration), value: scale)
                
                Circle()
                    .fill(AppTheme.coldPrimary.opacity(opacity))
                    .frame(width: 80, height: 80)
                    .animation(.easeInOut(duration: currentPhaseDuration), value: opacity)
                
                Text(phase.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(width: 150, height: 150)
            
            Text(technique.patternDescription)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .onAppear {
            startBreathingCycle()
        }
    }
    
    private var currentPhaseDuration: Double {
        switch phase {
        case .inhale: return technique.inhaleSeconds
        case .hold: return technique.holdSeconds
        case .exhale: return technique.exhaleSeconds
        case .holdAfter: return technique.holdAfterExhaleSeconds
        }
    }
    
    private func startBreathingCycle() {
        // Inhale
        phase = .inhale
        scale = 1.0
        opacity = 1.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + technique.inhaleSeconds) {
            // Hold
            phase = .hold
            
            DispatchQueue.main.asyncAfter(deadline: .now() + technique.holdSeconds) {
                // Exhale
                phase = .exhale
                scale = 0.6
                opacity = 0.5
                
                DispatchQueue.main.asyncAfter(deadline: .now() + technique.exhaleSeconds) {
                    if technique.holdAfterExhaleSeconds > 0 {
                        phase = .holdAfter
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + technique.holdAfterExhaleSeconds) {
                            startBreathingCycle()
                        }
                    } else {
                        startBreathingCycle()
                    }
                }
            }
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: Session
    
    var body: some View {
        HStack(spacing: 16) {
            // Type Icon
            ZStack {
                Circle()
                    .fill(session.type.primaryColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: session.type.icon)
                    .foregroundColor(session.type.primaryColor)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(session.type.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Label(session.durationFormatted, systemImage: "clock")
                    
                    if let temp = session.temperatureFormatted {
                        Label(temp, systemImage: "thermometer.medium")
                    }
                }
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Time
            Text(formatTime(session.date))
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Premium Badge

struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption2)
            Text("PRO")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.yellow)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.2))
        )
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let iconName: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textTertiary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.coldPrimary))
                .scaleEffect(1.5)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        
        particles = (0..<50).map { _ in
            ConfettiParticle(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...12),
                velocity: CGFloat.random(in: 3...8),
                opacity: 1.0
            )
        }
    }
    
    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            for i in particles.indices {
                particles[i].position.y += particles[i].velocity
                particles[i].position.x += CGFloat.random(in: -2...2)
                particles[i].opacity -= 0.005
                
                if particles[i].opacity <= 0 {
                    timer.invalidate()
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    let velocity: CGFloat
    var opacity: Double
}

// MARK: - Previews

#Preview("Session Buttons") {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        
        VStack(spacing: 16) {
            SessionButton(sessionType: .coldPlunge) {}
            SessionButton(sessionType: .sauna) {}
        }
        .padding()
    }
}

#Preview("Stat Cards") {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(title: "Total Sessions", value: "42", iconName: "number.circle", color: .blue)
            StatCard(title: "Current Streak", value: "7", subtitle: "days", iconName: "flame.fill", color: .orange)
            StatCard(title: "This Week", value: "5", iconName: "calendar", color: .green)
            StatCard(title: "Avg Duration", value: "3:24", iconName: "clock.fill", color: .purple)
        }
        .padding()
    }
}

#Preview("Timer Display") {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        
        TimerDisplay(elapsedTime: 185, sessionType: .coldPlunge, heartRate: 72)
    }
}
