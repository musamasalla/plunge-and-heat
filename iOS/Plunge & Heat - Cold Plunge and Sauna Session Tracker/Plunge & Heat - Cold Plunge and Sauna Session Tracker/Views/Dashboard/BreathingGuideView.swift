//
//  BreathingSessionView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/18.
//

import SwiftUI

// MARK: - Breathing Session View (Full Featured)

struct BreathingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTechnique: BreathingTechnique = .boxBreathing
    @State private var isActive = false
    @State private var currentPhase: BreathingPhase = .inhale
    @State private var progress: CGFloat = 0
    @State private var cycleCount = 0
    @State private var breathScale: CGFloat = 0.6
    @State private var phaseTimer: Timer?
    
    enum BreathingPhase: String {
        case inhale = "Inhale"
        case hold1 = "Hold"
        case exhale = "Exhale"
        case hold2 = "Rest"
        
        var displayText: String {
            switch self {
            case .inhale: return "Inhale"
            case .hold1, .hold2: return "Hold"
            case .exhale: return "Exhale"
            }
        }
        
        var color: Color {
            switch self {
            case .inhale: return AppTheme.coldPrimary
            case .hold1: return .purple
            case .exhale: return AppTheme.heatPrimary
            case .hold2: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    if !isActive {
                        // Selection mode
                        techniqueSelector
                        techniqueInfo
                    } else {
                        // Active breathing mode
                        breathingAnimation
                        phaseIndicator
                        cycleIndicator
                    }
                    
                    Spacer()
                    
                    // Control button
                    controlButton
                }
                .padding()
            }
            .navigationTitle(isActive ? selectedTechnique.name : "Breathing Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
            }
        }
    }
    
    // MARK: - Technique Selector
    
    private var techniqueSelector: some View {
        VStack(spacing: 16) {
            Text("Select Technique")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(BreathingTechnique.allTechniques, id: \.id) { technique in
                    TechniqueCard(
                        technique: technique,
                        isSelected: selectedTechnique.id == technique.id
                    ) {
                        HapticFeedback.light()
                        withAnimation(.spring()) {
                            selectedTechnique = technique
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Technique Info
    
    private var techniqueInfo: some View {
        VStack(spacing: 16) {
            // Pattern visualization
            HStack(spacing: 24) {
                PatternStep(label: "Inhale", seconds: selectedTechnique.inhaleSeconds, color: AppTheme.coldPrimary)
                PatternStep(label: "Hold", seconds: selectedTechnique.holdSeconds, color: .purple)
                PatternStep(label: "Exhale", seconds: selectedTechnique.exhaleSeconds, color: AppTheme.heatPrimary)
                if selectedTechnique.holdAfterExhaleSeconds > 0 {
                    PatternStep(label: "Hold", seconds: selectedTechnique.holdAfterExhaleSeconds, color: .purple)
                }
            }
            
            Text("\(selectedTechnique.cycles) cycles")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
    }
    
    // MARK: - Breathing Animation
    
    private var breathingAnimation: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(currentPhase.color.opacity(0.1))
                .frame(width: 280, height: 280)
                .scaleEffect(breathScale * 1.2)
                .blur(radius: 30)
            
            // Middle ring
            Circle()
                .stroke(currentPhase.color.opacity(0.3), lineWidth: 2)
                .frame(width: 240, height: 240)
                .scaleEffect(breathScale)
            
            // Main circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [currentPhase.color.opacity(0.6), currentPhase.color.opacity(0.2)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(breathScale)
                .shadow(color: currentPhase.color.opacity(0.5), radius: 20)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(currentPhase.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .scaleEffect(breathScale)
            
            // Center text
            VStack(spacing: 4) {
                Text(currentPhase.displayText)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(currentPhaseSeconds)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .frame(height: 300)
    }
    
    private var currentPhaseSeconds: String {
        let seconds: Double
        switch currentPhase {
        case .inhale: seconds = selectedTechnique.inhaleSeconds
        case .hold1: seconds = selectedTechnique.holdSeconds
        case .exhale: seconds = selectedTechnique.exhaleSeconds
        case .hold2: seconds = selectedTechnique.holdAfterExhaleSeconds
        }
        return "\(Int(seconds))s"
    }
    
    // MARK: - Phase Indicator
    
    private var phaseIndicator: some View {
        HStack(spacing: 20) {
            PhaseIndicator(phase: "Inhale", color: AppTheme.coldPrimary, isActive: currentPhase == .inhale)
            PhaseIndicator(phase: "Hold", color: .purple, isActive: currentPhase == .hold1)
            PhaseIndicator(phase: "Exhale", color: AppTheme.heatPrimary, isActive: currentPhase == .exhale)
            if selectedTechnique.holdAfterExhaleSeconds > 0 {
                PhaseIndicator(phase: "Hold", color: .purple, isActive: currentPhase == .hold2)
            }
        }
    }
    
    // MARK: - Cycle Indicator
    
    private var cycleIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<selectedTechnique.cycles, id: \.self) { index in
                Circle()
                    .fill(index < cycleCount ? currentPhase.color : AppTheme.surfaceBackground)
                    .frame(width: 12, height: 12)
            }
        }
    }
    
    // MARK: - Control Button
    
    private var controlButton: some View {
        Button(action: {
            HapticFeedback.medium()
            if isActive {
                stopBreathing()
            } else {
                startBreathing()
            }
        }) {
            HStack {
                Image(systemName: isActive ? "stop.fill" : "play.fill")
                Text(isActive ? "Stop" : "Start Breathing")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(isActive ? Color.red : AppTheme.coldPrimary)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Breathing Logic
    
    private func startBreathing() {
        isActive = true
        cycleCount = 0
        currentPhase = .inhale
        runPhase()
    }
    
    private func stopBreathing() {
        isActive = false
        phaseTimer?.invalidate()
        phaseTimer = nil
        progress = 0
        breathScale = 0.6
    }
    
    private func runPhase() {
        let duration: Double
        let targetScale: CGFloat
        
        switch currentPhase {
        case .inhale:
            duration = selectedTechnique.inhaleSeconds
            targetScale = 1.0
        case .hold1:
            duration = selectedTechnique.holdSeconds
            targetScale = 1.0
        case .exhale:
            duration = selectedTechnique.exhaleSeconds
            targetScale = 0.6
        case .hold2:
            duration = selectedTechnique.holdAfterExhaleSeconds
            targetScale = 0.6
        }
        
        // Animate scale
        withAnimation(.easeInOut(duration: duration)) {
            breathScale = targetScale
        }
        
        // Animate progress
        progress = 0
        withAnimation(.linear(duration: duration)) {
            progress = 1.0
        }
        
        // Schedule next phase
        phaseTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            HapticFeedback.light()
            moveToNextPhase()
        }
    }
    
    private func moveToNextPhase() {
        switch currentPhase {
        case .inhale:
            currentPhase = .hold1
        case .hold1:
            currentPhase = .exhale
        case .exhale:
            if selectedTechnique.holdAfterExhaleSeconds > 0 {
                currentPhase = .hold2
            } else {
                completeCycle()
                return
            }
        case .hold2:
            completeCycle()
            return
        }
        
        runPhase()
    }
    
    private func completeCycle() {
        cycleCount += 1
        HapticFeedback.success()
        
        if cycleCount >= selectedTechnique.cycles {
            // Completed all cycles
            stopBreathing()
        } else {
            // Start next cycle
            currentPhase = .inhale
            runPhase()
        }
    }
}

// MARK: - Technique Card

struct TechniqueCard: View {
    let technique: BreathingTechnique
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.coldPrimary : AppTheme.surfaceBackground)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "wind")
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(technique.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(technique.description)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(technique.patternDescription)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.coldPrimary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? AppTheme.coldPrimary : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - Pattern Step

struct PatternStep: View {
    let label: String
    let seconds: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text("\(Int(seconds))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

// MARK: - Phase Indicator

struct PhaseIndicator: View {
    let phase: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isActive ? color : AppTheme.surfaceBackground)
                .frame(width: 12, height: 12)
            
            Text(phase)
                .font(.caption2)
                .foregroundColor(isActive ? .white : AppTheme.textTertiary)
        }
    }
}

// MARK: - Preview

#Preview {
    BreathingSessionView()
}
