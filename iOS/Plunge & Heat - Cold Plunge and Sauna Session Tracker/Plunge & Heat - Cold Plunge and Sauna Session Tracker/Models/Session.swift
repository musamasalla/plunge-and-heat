//
//  Session.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import Foundation
import SwiftUI

// MARK: - Session Model

struct Session: Identifiable, Codable, Hashable {
    let id: UUID
    var type: SessionType
    var date: Date
    var duration: TimeInterval // in seconds
    var temperature: Double?
    var temperatureUnit: TemperatureUnit
    var heartRate: Int?
    var notes: String?
    var photoData: Data?
    var protocolUsed: String?
    var breathingTechnique: String?
    
    init(
        id: UUID = UUID(),
        type: SessionType,
        date: Date = Date(),
        duration: TimeInterval,
        temperature: Double? = nil,
        temperatureUnit: TemperatureUnit = .fahrenheit,
        heartRate: Int? = nil,
        notes: String? = nil,
        photoData: Data? = nil,
        protocolUsed: String? = nil,
        breathingTechnique: String? = nil
    ) {
        self.id = id
        self.type = type
        self.date = date
        self.duration = duration
        self.temperature = temperature
        self.temperatureUnit = temperatureUnit
        self.heartRate = heartRate
        self.notes = notes
        self.photoData = photoData
        self.protocolUsed = protocolUsed
        self.breathingTechnique = breathingTechnique
    }
    
    // MARK: - Computed Properties
    
    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
        }
        return "\(seconds)s"
    }
    
    var temperatureFormatted: String? {
        guard let temp = temperature else { return nil }
        return String(format: "%.0f%@", temp, temperatureUnit.symbol)
    }
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<21: return "Evening"
        default: return "Night"
        }
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Session, rhs: Session) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Session Statistics

struct SessionStatistics {
    var totalSessions: Int = 0
    var totalColdSessions: Int = 0
    var totalSaunaSessions: Int = 0
    var totalDuration: TimeInterval = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var averageDuration: TimeInterval = 0
    var averageTemperature: Double?
    var sessionsThisWeek: Int = 0
    var sessionsThisMonth: Int = 0
    
    var totalDurationFormatted: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    var averageDurationFormatted: String {
        let minutes = Int(averageDuration) / 60
        let seconds = Int(averageDuration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

// MARK: - Day Sessions

struct DaySessions: Identifiable {
    let id = UUID()
    let date: Date
    let sessions: [Session]
    
    var hasCold: Bool {
        sessions.contains { $0.type == .coldPlunge }
    }
    
    var hasSauna: Bool {
        sessions.contains { $0.type == .sauna }
    }
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Sample Data

extension Session {
    static let sampleCold = Session(
        type: .coldPlunge,
        date: Date(),
        duration: 180,
        temperature: 50,
        temperatureUnit: .fahrenheit,
        heartRate: 72,
        notes: "Felt great after morning coffee"
    )
    
    static let sampleSauna = Session(
        type: .sauna,
        date: Date().addingTimeInterval(-3600),
        duration: 900,
        temperature: 180,
        temperatureUnit: .fahrenheit,
        heartRate: 95,
        notes: "15 minutes, deep relaxation"
    )
    
    static let sampleSessions: [Session] = [
        Session(type: .coldPlunge, date: Date(), duration: 180, temperature: 50),
        Session(type: .sauna, date: Date().addingTimeInterval(-3600), duration: 900, temperature: 180),
        Session(type: .coldPlunge, date: Date().addingTimeInterval(-86400), duration: 120, temperature: 55),
        Session(type: .sauna, date: Date().addingTimeInterval(-86400 * 2), duration: 600, temperature: 175),
        Session(type: .coldPlunge, date: Date().addingTimeInterval(-86400 * 3), duration: 150, temperature: 48),
    ]
}
