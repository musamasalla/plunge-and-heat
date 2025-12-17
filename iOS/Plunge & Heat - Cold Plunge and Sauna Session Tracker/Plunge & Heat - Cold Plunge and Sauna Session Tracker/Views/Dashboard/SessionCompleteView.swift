//
//  SessionCompleteView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

// MARK: - Session Complete View

struct SessionCompleteView: View {
    @Environment(\.dismiss) private var dismiss
    
    let session: Session
    let isNewStreak: Bool
    let streakCount: Int
    
    @State private var showContent = false
    @State private var showStats = false
    @State private var showConfetti = false
    @State private var ringProgress: CGFloat = 0
    @State private var celebrationScale: CGFloat = 0.5
    
    var body: some View {
        ZStack {
            // Background
            sessionBackground
            
            // Confetti
            if showConfetti {
                ConfettiOverlay()
            }
            
            // Content
            VStack(spacing: 32) {
                Spacer()
                
                // Success animation
                successBadge
                
                // Title
                VStack(spacing: 8) {
                    Text("Session Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(motivationalMessage)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                // Stats
                statsSection
                
                // Streak
                if streakCount > 0 {
                    streakSection
                }
                
                Spacer()
                
                // Done button
                doneButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .onAppear {
            animateIn()
        }
    }
    
    // MARK: - Background
    
    private var sessionBackground: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            // Radial gradient from session type
            RadialGradient(
                colors: [session.type.primaryColor.opacity(0.3), Color.clear],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Success Badge
    
    private var successBadge: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(session.type.primaryColor.opacity(0.2))
                .frame(width: 180, height: 180)
                .blur(radius: 30)
                .scaleEffect(celebrationScale)
            
            // Progress ring
            Circle()
                .stroke(session.type.primaryColor.opacity(0.3), lineWidth: 8)
                .frame(width: 140, height: 140)
            
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(session.type.gradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
            
            // Inner circle with icon
            Circle()
                .fill(session.type.gradient)
                .frame(width: 100, height: 100)
                .shadow(color: session.type.primaryColor.opacity(0.5), radius: 15, y: 8)
            
            Image(systemName: "checkmark")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(celebrationScale)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            CompletionStatCard(
                icon: "clock.fill",
                value: session.durationFormatted,
                label: "Duration",
                color: session.type.primaryColor
            )
            
            if let temp = session.temperatureFormatted {
                CompletionStatCard(
                    icon: "thermometer.medium",
                    value: temp,
                    label: "Temperature",
                    color: session.type.primaryColor
                )
            }
            
            if let hr = session.heartRate {
                CompletionStatCard(
                    icon: "heart.fill",
                    value: "\(hr)",
                    label: "BPM",
                    color: .red
                )
            }
        }
        .opacity(showStats ? 1 : 0)
        .offset(y: showStats ? 0 : 30)
    }
    
    // MARK: - Streak Section
    
    private var streakSection: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streakCount) Day Streak!")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(isNewStreak ? "You started a new streak!" : "Keep it going!")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                )
        )
        .opacity(showStats ? 1 : 0)
        .offset(y: showStats ? 0 : 30)
    }
    
    // MARK: - Done Button
    
    private var doneButton: some View {
        Button(action: {
            HapticFeedback.medium()
            dismiss()
        }) {
            Text("Done")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(session.type.gradient)
                .cornerRadius(16)
                .shadow(color: session.type.primaryColor.opacity(0.4), radius: 15, y: 8)
        }
        .opacity(showStats ? 1 : 0)
    }
    
    // MARK: - Motivational Message
    
    private var motivationalMessage: String {
        let messages: [String]
        if session.type == .coldPlunge {
            messages = [
                "You conquered the cold! 🧊",
                "Ice warrior mode activated! ❄️",
                "Your body thanks you! 💪",
                "Mental fortitude unlocked! 🧠",
                "Cold exposure complete! ✨"
            ]
        } else {
            messages = [
                "Heat therapy complete! 🔥",
                "Sweat session accomplished! 💧",
                "Relaxation achieved! 🧘",
                "Detox mode activated! ✨",
                "Heat master level up! 🌡️"
            ]
        }
        return messages.randomElement() ?? messages[0]
    }
    
    // MARK: - Animation
    
    private func animateIn() {
        // Celebration scale
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            celebrationScale = 1.0
        }
        
        // Ring progress
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            ringProgress = 1.0
        }
        
        // Content
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            showContent = true
        }
        
        // Stats
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            showStats = true
        }
        
        // Confetti for milestones
        if streakCount > 0 && streakCount % 7 == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
                HapticFeedback.success()
            }
        }
    }
}

// MARK: - Completion Stat Card

struct CompletionStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
        )
    }
}

// MARK: - Confetti Overlay

struct ConfettiOverlay: View {
    @State private var isAnimating = false
    
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    private let particleCount = 50
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    ConfettiPiece(
                        color: colors[index % colors.count],
                        size: CGFloat.random(in: 6...12),
                        startX: CGFloat.random(in: 0...geometry.size.width),
                        endX: CGFloat.random(in: -100...geometry.size.width + 100),
                        duration: Double.random(in: 2...3),
                        delay: Double.random(in: 0...0.5),
                        isAnimating: isAnimating,
                        screenHeight: geometry.size.height
                    )
                }
            }
            .onAppear {
                isAnimating = true
            }
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiPiece: View {
    let color: Color
    let size: CGFloat
    let startX: CGFloat
    let endX: CGFloat
    let duration: Double
    let delay: Double
    let isAnimating: Bool
    let screenHeight: CGFloat
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .position(
                x: isAnimating ? endX : startX,
                y: isAnimating ? screenHeight + 50 : -20
            )
            .opacity(isAnimating ? 0 : 1)
            .animation(
                .easeIn(duration: duration).delay(delay),
                value: isAnimating
            )
    }
}

// MARK: - Preview

#Preview {
    SessionCompleteView(
        session: Session.sampleCold,
        isNewStreak: false,
        streakCount: 7
    )
}

