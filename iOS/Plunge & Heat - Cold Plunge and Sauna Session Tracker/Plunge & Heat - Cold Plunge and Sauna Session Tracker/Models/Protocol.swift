//
//  Protocol.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import Foundation
import SwiftUI

// MARK: - Wellness Protocol

struct WellnessProtocol: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var category: ProtocolCategory
    var sessionType: SessionType
    var targetTemperature: TemperatureRange
    var targetDuration: DurationRange
    var frequencyPerWeek: Int
    var steps: [ProtocolStep]
    var benefits: [String]
    var tips: [String]
    var iconName: String
    var isPremium: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: ProtocolCategory,
        sessionType: SessionType,
        targetTemperature: TemperatureRange,
        targetDuration: DurationRange,
        frequencyPerWeek: Int,
        steps: [ProtocolStep],
        benefits: [String],
        tips: [String],
        iconName: String = "list.bullet.clipboard",
        isPremium: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.sessionType = sessionType
        self.targetTemperature = targetTemperature
        self.targetDuration = targetDuration
        self.frequencyPerWeek = frequencyPerWeek
        self.steps = steps
        self.benefits = benefits
        self.tips = tips
        self.iconName = iconName
        self.isPremium = isPremium
    }
}

// MARK: - Protocol Category

enum ProtocolCategory: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case therapeutic = "Therapeutic"
    case performance = "Performance"
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        case .therapeutic: return .purple
        case .performance: return .blue
        }
    }
}

// MARK: - Temperature Range

struct TemperatureRange: Codable {
    var min: Double
    var max: Double
    var unit: TemperatureUnit
    
    var formatted: String {
        "\(Int(min))-\(Int(max))\(unit.symbol)"
    }
}

// MARK: - Duration Range

struct DurationRange: Codable {
    var min: TimeInterval // in seconds
    var max: TimeInterval
    
    var formatted: String {
        let minMinutes = Int(min) / 60
        let maxMinutes = Int(max) / 60
        return "\(minMinutes)-\(maxMinutes) min"
    }
}

// MARK: - Protocol Step

struct ProtocolStep: Identifiable, Codable {
    let id: UUID
    var order: Int
    var title: String
    var description: String
    var durationSeconds: TimeInterval?
    
    init(id: UUID = UUID(), order: Int, title: String, description: String, durationSeconds: TimeInterval? = nil) {
        self.id = id
        self.order = order
        self.title = title
        self.description = description
        self.durationSeconds = durationSeconds
    }
}

// MARK: - Breathing Technique

struct BreathingTechnique: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var inhaleSeconds: Double
    var holdSeconds: Double
    var exhaleSeconds: Double
    var holdAfterExhaleSeconds: Double
    var cycles: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        inhaleSeconds: Double,
        holdSeconds: Double,
        exhaleSeconds: Double,
        holdAfterExhaleSeconds: Double = 0,
        cycles: Int = 4
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.inhaleSeconds = inhaleSeconds
        self.holdSeconds = holdSeconds
        self.exhaleSeconds = exhaleSeconds
        self.holdAfterExhaleSeconds = holdAfterExhaleSeconds
        self.cycles = cycles
    }
    
    var patternDescription: String {
        if holdAfterExhaleSeconds > 0 {
            return "\(Int(inhaleSeconds))-\(Int(holdSeconds))-\(Int(exhaleSeconds))-\(Int(holdAfterExhaleSeconds))"
        }
        return "\(Int(inhaleSeconds))-\(Int(holdSeconds))-\(Int(exhaleSeconds))"
    }
}

// MARK: - Pre-built Protocols

extension WellnessProtocol {
    static let wimHofMethod = WellnessProtocol(
        name: "Wim Hof Method",
        description: "The famous Dutch extreme athlete's cold exposure protocol combining breathing, cold exposure, and meditation.",
        category: .intermediate,
        sessionType: .coldPlunge,
        targetTemperature: TemperatureRange(min: 50, max: 59, unit: .fahrenheit),
        targetDuration: DurationRange(min: 60, max: 180),
        frequencyPerWeek: 5,
        steps: [
            ProtocolStep(order: 1, title: "Breathing Rounds", description: "30-40 deep breaths, let go on exhale", durationSeconds: 90),
            ProtocolStep(order: 2, title: "Breath Hold", description: "Hold breath after exhale as long as comfortable", durationSeconds: 60),
            ProtocolStep(order: 3, title: "Recovery Breath", description: "Inhale deeply, hold for 15 seconds", durationSeconds: 15),
            ProtocolStep(order: 4, title: "Cold Exposure", description: "Enter cold water, focus on breath", durationSeconds: 120)
        ],
        benefits: ["Increased energy", "Improved immune response", "Better stress management", "Enhanced focus"],
        tips: ["Start with shorter exposures", "Never practice alone", "Stay relaxed, don't fight the cold"],
        iconName: "wind",
        isPremium: false
    )
    
    static let hubermanProtocol = WellnessProtocol(
        name: "Huberman Protocol",
        description: "Science-based deliberate cold exposure for dopamine and adrenaline benefits, based on Dr. Andrew Huberman's research.",
        category: .intermediate,
        sessionType: .coldPlunge,
        targetTemperature: TemperatureRange(min: 45, max: 55, unit: .fahrenheit),
        targetDuration: DurationRange(min: 60, max: 180),
        frequencyPerWeek: 3,
        steps: [
            ProtocolStep(order: 1, title: "Prepare", description: "Deep breaths, set intention for the session"),
            ProtocolStep(order: 2, title: "Enter Cold", description: "Submerge up to neck, arms at sides"),
            ProtocolStep(order: 3, title: "Stay Present", description: "Focus on breath, don't distract yourself"),
            ProtocolStep(order: 4, title: "Exit", description: "Let body warm up naturally, no hot shower")
        ],
        benefits: ["2.5x dopamine increase", "Improved resilience", "Better mood regulation", "Enhanced metabolism"],
        tips: ["11 minutes total per week is target", "End cold, don't end with heat", "Morning sessions maximize benefit"],
        iconName: "brain.head.profile",
        isPremium: false
    )
    
    static let scandinavianContrast = WellnessProtocol(
        name: "Scandinavian Contrast Therapy",
        description: "Traditional Nordic practice alternating between sauna heat and cold plunge for recovery and wellness.",
        category: .intermediate,
        sessionType: .sauna,
        targetTemperature: TemperatureRange(min: 170, max: 195, unit: .fahrenheit),
        targetDuration: DurationRange(min: 600, max: 1200),
        frequencyPerWeek: 2,
        steps: [
            ProtocolStep(order: 1, title: "Sauna Round 1", description: "10-15 minutes in sauna", durationSeconds: 720),
            ProtocolStep(order: 2, title: "Cold Plunge 1", description: "1-2 minutes cold immersion", durationSeconds: 90),
            ProtocolStep(order: 3, title: "Rest", description: "5-10 minutes relaxation", durationSeconds: 300),
            ProtocolStep(order: 4, title: "Sauna Round 2", description: "10-15 minutes in sauna", durationSeconds: 720),
            ProtocolStep(order: 5, title: "Cold Plunge 2", description: "1-2 minutes cold immersion", durationSeconds: 90),
            ProtocolStep(order: 6, title: "Cool Down", description: "Rest and hydrate", durationSeconds: 300)
        ],
        benefits: ["Muscle recovery", "Improved circulation", "Deep relaxation", "Better sleep"],
        tips: ["Stay hydrated", "Listen to your body", "End on cold for alertness, heat for relaxation"],
        iconName: "arrow.triangle.swap",
        isPremium: false
    )
    
    static let beginnerCold = WellnessProtocol(
        name: "Beginner Cold Start",
        description: "A gentle introduction to cold exposure for those new to cold therapy.",
        category: .beginner,
        sessionType: .coldPlunge,
        targetTemperature: TemperatureRange(min: 60, max: 68, unit: .fahrenheit),
        targetDuration: DurationRange(min: 30, max: 60),
        frequencyPerWeek: 3,
        steps: [
            ProtocolStep(order: 1, title: "Prepare", description: "Take 5 deep breaths, relax shoulders", durationSeconds: 30),
            ProtocolStep(order: 2, title: "Enter Slowly", description: "Step in gradually, breathe through it", durationSeconds: 15),
            ProtocolStep(order: 3, title: "Stay", description: "30-60 seconds, focus on steady breathing", durationSeconds: 45),
            ProtocolStep(order: 4, title: "Exit", description: "Step out, let body warm naturally", durationSeconds: 10)
        ],
        benefits: ["Build cold tolerance", "Mental resilience", "Morning alertness"],
        tips: ["Start with cold showers first", "Never force through pain", "Celebrate small wins"],
        iconName: "leaf.fill",
        isPremium: false
    )
    
    static let finnishSauna = WellnessProtocol(
        name: "Finnish Sauna Tradition",
        description: "Classic Finnish sauna experience with proper cool-down periods for optimal relaxation.",
        category: .therapeutic,
        sessionType: .sauna,
        targetTemperature: TemperatureRange(min: 176, max: 212, unit: .fahrenheit),
        targetDuration: DurationRange(min: 900, max: 1500),
        frequencyPerWeek: 3,
        steps: [
            ProtocolStep(order: 1, title: "Shower", description: "Rinse off before entering sauna", durationSeconds: 60),
            ProtocolStep(order: 2, title: "First Round", description: "Sit on lower bench, gradually move up", durationSeconds: 600),
            ProtocolStep(order: 3, title: "Cool Down", description: "Cold shower or rest in cool room", durationSeconds: 120),
            ProtocolStep(order: 4, title: "Second Round", description: "Add löyly (steam) by pouring water on stones", durationSeconds: 480),
            ProtocolStep(order: 5, title: "Rest", description: "Relax and hydrate", durationSeconds: 300)
        ],
        benefits: ["Deep relaxation", "Improved circulation", "Skin detoxification", "Stress relief"],
        tips: ["Stay hydrated", "Don't rush", "Listen to your body", "End with cool shower"],
        iconName: "flame.fill",
        isPremium: false
    )
    
    static let athleteRecovery = WellnessProtocol(
        name: "Athlete Recovery Protocol",
        description: "Optimized cold exposure routine for post-workout muscle recovery and reduced inflammation.",
        category: .performance,
        sessionType: .coldPlunge,
        targetTemperature: TemperatureRange(min: 50, max: 59, unit: .fahrenheit),
        targetDuration: DurationRange(min: 60, max: 180),
        frequencyPerWeek: 4,
        steps: [
            ProtocolStep(order: 1, title: "Post-Workout Wait", description: "Wait 4+ hours after strength training", durationSeconds: 0),
            ProtocolStep(order: 2, title: "Brief Warmup", description: "Light movement to increase blood flow", durationSeconds: 120),
            ProtocolStep(order: 3, title: "Cold Immersion", description: "Submerge to mid-chest level", durationSeconds: 120),
            ProtocolStep(order: 4, title: "Active Recovery", description: "Move limbs gently in cold water", durationSeconds: 60),
            ProtocolStep(order: 5, title: "Natural Warmup", description: "Exit and let body warm naturally", durationSeconds: 0)
        ],
        benefits: ["Reduced muscle soreness", "Faster recovery", "Decreased inflammation", "Improved performance"],
        tips: ["Don't plunge immediately after strength training", "Focus on breathing", "Use after endurance training is fine"],
        iconName: "figure.run",
        isPremium: true
    )
    
    static let coldShowerStart = WellnessProtocol(
        name: "30-Day Cold Shower Challenge",
        description: "Progressive cold shower challenge to build cold tolerance before moving to ice baths.",
        category: .beginner,
        sessionType: .coldPlunge,
        targetTemperature: TemperatureRange(min: 55, max: 70, unit: .fahrenheit),
        targetDuration: DurationRange(min: 30, max: 180),
        frequencyPerWeek: 7,
        steps: [
            ProtocolStep(order: 1, title: "Week 1", description: "End showers with 30 seconds of cold water", durationSeconds: 30),
            ProtocolStep(order: 2, title: "Week 2", description: "Increase to 1 minute of cold water", durationSeconds: 60),
            ProtocolStep(order: 3, title: "Week 3", description: "Start with cold, then alternate", durationSeconds: 90),
            ProtocolStep(order: 4, title: "Week 4", description: "Full cold showers, 2-3 minutes", durationSeconds: 150)
        ],
        benefits: ["Build cold tolerance", "Morning alertness", "Improved willpower", "Better circulation"],
        tips: ["Consistency is key", "Focus on breath control", "Celebrate small wins"],
        iconName: "drop.fill",
        isPremium: false
    )
    
    static let advancedIceBath = WellnessProtocol(
        name: "Advanced Ice Bath",
        description: "Intensive cold exposure for experienced practitioners seeking maximum benefits.",
        category: .advanced,
        sessionType: .coldPlunge,
        targetTemperature: TemperatureRange(min: 33, max: 45, unit: .fahrenheit),
        targetDuration: DurationRange(min: 180, max: 600),
        frequencyPerWeek: 2,
        steps: [
            ProtocolStep(order: 1, title: "Mental Preparation", description: "Breathing exercises and visualization", durationSeconds: 180),
            ProtocolStep(order: 2, title: "Enter Gradually", description: "Submerge body, then arms one at a time", durationSeconds: 30),
            ProtocolStep(order: 3, title: "Full Immersion", description: "Submerge to neck, stay calm", durationSeconds: 300),
            ProtocolStep(order: 4, title: "Hands Under", description: "Submerge hands for additional challenge", durationSeconds: 120),
            ProtocolStep(order: 5, title: "Exit & Recover", description: "Move slowly, allow body to shiver and warm", durationSeconds: 0)
        ],
        benefits: ["Maximum hormetic stress", "Peak dopamine response", "Enhanced mental fortitude", "Deep recovery"],
        tips: ["Never practice alone", "Know your limits", "Don't push through numbness", "Have warm clothes ready"],
        iconName: "snowflake.circle.fill",
        isPremium: true
    )
    
    static let allProtocols: [WellnessProtocol] = [
        .wimHofMethod,
        .hubermanProtocol,
        .scandinavianContrast,
        .beginnerCold,
        .finnishSauna,
        .athleteRecovery,
        .coldShowerStart,
        .advancedIceBath
    ]
}

// MARK: - Pre-built Breathing Techniques

extension BreathingTechnique {
    static let boxBreathing = BreathingTechnique(
        name: "Box Breathing",
        description: "A calming technique used by Navy SEALs",
        inhaleSeconds: 4,
        holdSeconds: 4,
        exhaleSeconds: 4,
        holdAfterExhaleSeconds: 4,
        cycles: 4
    )
    
    static let physiologicalSigh = BreathingTechnique(
        name: "Physiological Sigh",
        description: "Quick stress relief with double inhale",
        inhaleSeconds: 2,
        holdSeconds: 1,
        exhaleSeconds: 6,
        cycles: 3
    )
    
    static let wimHofBreathing = BreathingTechnique(
        name: "Wim Hof Breathing",
        description: "Energizing power breaths",
        inhaleSeconds: 2,
        holdSeconds: 0,
        exhaleSeconds: 2,
        cycles: 30
    )
    
    static let allTechniques: [BreathingTechnique] = [
        .boxBreathing,
        .physiologicalSigh,
        .wimHofBreathing
    ]
}
