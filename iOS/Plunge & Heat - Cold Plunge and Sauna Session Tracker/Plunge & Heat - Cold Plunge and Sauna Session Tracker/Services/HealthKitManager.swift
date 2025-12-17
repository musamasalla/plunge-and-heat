//
//  HealthKitManager.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import Foundation
import HealthKit
import SwiftUI
import Combine

// MARK: - HealthKit Manager

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    // MARK: - Published Properties
    
    @Published var isAuthorized = false
    @Published var latestHeartRate: Double?
    @Published var latestHRV: Double?
    @Published var restingHeartRate: Double?
    @Published var averageSleepHours: Double?
    
    @Published var hrvTrend: [HealthDataPoint] = []
    @Published var restingHRTrend: [HealthDataPoint] = []
    
    // MARK: - Types
    
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
    private let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
    private let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession)!
    
    // MARK: - Initialization
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func checkAuthorizationStatus() {
        guard isHealthKitAvailable else {
            isAuthorized = false
            return
        }
        
        let status = healthStore.authorizationStatus(for: heartRateType)
        isAuthorized = status == .sharingAuthorized
    }
    
    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }
        
        let readTypes: Set<HKObjectType> = [
            heartRateType,
            hrvType,
            restingHRType,
            sleepType
        ]
        
        let writeTypes: Set<HKSampleType> = [
            mindfulType
        ]
        
        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        checkAuthorizationStatus()
    }
    
    // MARK: - Read Data
    
    func fetchLatestHeartRate() async throws -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            Task { @MainActor in
                guard error == nil,
                      let sample = samples?.first as? HKQuantitySample else {
                    return
                }
                let hr = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                self?.latestHeartRate = hr
            }
        }
        healthStore.execute(query)
        return latestHeartRate
    }
    
    func fetchLatestHRV() async throws -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: hrvType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            Task { @MainActor in
                guard error == nil,
                      let sample = samples?.first as? HKQuantitySample else {
                    return
                }
                let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                self?.latestHRV = hrv
            }
        }
        healthStore.execute(query)
        return latestHRV
    }
    
    func fetchRestingHeartRate() async throws -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: restingHRType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            Task { @MainActor in
                guard error == nil,
                      let sample = samples?.first as? HKQuantitySample else {
                    return
                }
                let rhr = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                self?.restingHeartRate = rhr
            }
        }
        healthStore.execute(query)
        return restingHeartRate
    }
    
    func fetchHRVTrend(days: Int = 30) async throws {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        let query = HKSampleQuery(
            sampleType: hrvType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            Task { @MainActor in
                guard error == nil, let samples = samples as? [HKQuantitySample] else { return }
                
                self?.hrvTrend = samples.map { sample in
                    HealthDataPoint(
                        date: sample.endDate,
                        value: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    )
                }
            }
        }
        healthStore.execute(query)
    }
    
    func fetchRestingHRTrend(days: Int = 30) async throws {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        let query = HKSampleQuery(
            sampleType: restingHRType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            Task { @MainActor in
                guard error == nil, let samples = samples as? [HKQuantitySample] else { return }
                
                self?.restingHRTrend = samples.map { sample in
                    HealthDataPoint(
                        date: sample.endDate,
                        value: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    )
                }
            }
        }
        healthStore.execute(query)
    }
    
    // MARK: - Write Data
    
    func saveMindfulSession(duration: TimeInterval, date: Date = Date()) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let startDate = date.addingTimeInterval(-duration)
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: date
        )
        
        try await healthStore.save(sample)
    }
    
    // MARK: - Live Heart Rate Monitoring
    
    func startHeartRateMonitoring(updateHandler: @escaping (Double) -> Void) {
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { _, samples, _, _, error in
            guard error == nil, let samples = samples as? [HKQuantitySample] else { return }
            if let latestSample = samples.last {
                let hr = latestSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                Task { @MainActor in
                    updateHandler(hr)
                }
            }
        }
        
        query.updateHandler = { _, samples, _, _, error in
            guard error == nil, let samples = samples as? [HKQuantitySample] else { return }
            if let latestSample = samples.last {
                let hr = latestSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                Task { @MainActor in
                    updateHandler(hr)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Insights
    
    func generateInsights(sessions: [Session]) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Analyze morning vs evening sessions
        let calendar = Calendar.current
        let morningSessions = sessions.filter {
            let hour = calendar.component(.hour, from: $0.date)
            return hour >= 5 && hour < 12
        }
        
        if morningSessions.count > sessions.count / 2 {
            insights.append(HealthInsight(
                title: "Morning Person",
                description: "You do most of your sessions before noon. Research shows morning cold exposure may boost alertness throughout the day.",
                iconName: "sunrise.fill",
                color: .orange
            ))
        }
        
        // Check HRV correlation if we have data
        if !hrvTrend.isEmpty && !sessions.isEmpty {
            insights.append(HealthInsight(
                title: "HRV Tracking",
                description: "Your HRV data is being tracked. Consistent cold exposure may improve HRV over time.",
                iconName: "heart.text.square.fill",
                color: .purple
            ))
        }
        
        // Streak insight
        let streak = SettingsManager.shared.currentStreak
        if streak >= 7 {
            insights.append(HealthInsight(
                title: "\(streak)-Day Streak!",
                description: "Amazing consistency! Your body is adapting to regular practice.",
                iconName: "flame.fill",
                color: .orange
            ))
        }
        
        return insights
    }
}

// MARK: - Supporting Types

struct HealthDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct HealthInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let color: Color
}

enum HealthKitError: Error {
    case notAvailable
    case notAuthorized
    case queryFailed
}
