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
    @State private var showButtons = false
    
    var body: some View {
        ZStack {
            // Background
            session.type.gradient
                .opacity(0.3)
                .ignoresSafeArea()
            
            AppTheme.background
                .opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success Icon
                if showContent {
                    ZStack {
                        Circle()
                            .fill(session.type.gradient)
                            .frame(width: 120, height: 120)
                            .scaleEffect(showContent ? 1.0 : 0.5)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Congratulations Text
                if showContent {
                    VStack(spacing: 12) {
                        Text("Session Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Great job on your \(session.type.displayName.lowercased())!")
                            .font(.title3)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Session Stats
                if showStats {
                    VStack(spacing: 16) {
                        HStack(spacing: 24) {
                            StatBubble(
                                icon: "clock.fill",
                                value: session.durationFormatted,
                                label: "Duration",
                                color: session.type.primaryColor
                            )
                            
                            if let temp = session.temperatureFormatted {
                                StatBubble(
                                    icon: "thermometer.medium",
                                    value: temp,
                                    label: "Temperature",
                                    color: session.type.primaryColor
                                )
                            }
                            
                            if let hr = session.heartRate {
                                StatBubble(
                                    icon: "heart.fill",
                                    value: "\(hr)",
                                    label: "BPM",
                                    color: .red
                                )
                            }
                        }
                        
                        // Streak info
                        if isNewStreak || streakCount > 1 {
                            HStack(spacing: 8) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                
                                if isNewStreak {
                                    Text("New streak started!")
                                        .foregroundColor(.orange)
                                } else {
                                    Text("\(streakCount) day streak!")
                                        .foregroundColor(.orange)
                                }
                            }
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.2))
                            )
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                // Continue Button
                if showButtons {
                    Button(action: {
                        HapticFeedback.light()
                        dismiss()
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(session.type.gradient)
                            .cornerRadius(AppTheme.cornerRadiusMedium)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // Confetti for milestones
            if streakCount > 0 && streakCount % 7 == 0 {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        HapticFeedback.success()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showContent = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
            showStats = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) {
            showButtons = true
        }
    }
}

// MARK: - Stat Bubble

struct StatBubble: View {
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
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
    }
}

// MARK: - Quick Log Success Toast

struct QuickLogToast: View {
    let sessionType: SessionType
    let duration: String
    @Binding var isShowing: Bool
    
    var body: some View {
        if isShowing {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(sessionType.displayName) logged!")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(duration)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.spring()) {
                        isShowing = false
                    }
                }
            }
        }
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
