//
//  ChartsView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI
import Charts

// MARK: - Charts View

struct ChartsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var settings = SettingsManager.shared
    
    @State private var selectedTimeRange: TimeRange = .month
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time range picker
                        timeRangePicker
                        
                        // Sessions per week chart
                        sessionsChart
                        
                        // Duration progression
                        durationChart
                        
                        // Temperature progression
                        if hasTemperatureData {
                            temperatureChart
                        }
                        
                        // Type distribution
                        typeDistributionChart
                    }
                    .padding()
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.coldPrimary)
                }
            }
        }
    }
    
    // MARK: - Time Range Picker
    
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Sessions Chart
    
    private var sessionsChart: some View {
        ChartCard(title: "Sessions Over Time", icon: "chart.bar.fill") {
            if sessionsData.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(sessionsData) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Sessions", item.count)
                    )
                    .foregroundStyle(
                        item.type == .coldPlunge ? AppTheme.coldPrimary : AppTheme.heatPrimary
                    )
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: xAxisStride)) { value in
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 200)
            }
        }
    }
    
    // MARK: - Duration Chart
    
    private var durationChart: some View {
        ChartCard(title: "Duration Progression", icon: "clock.fill") {
            if durationData.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(durationData) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Minutes", item.minutes)
                    )
                    .foregroundStyle(item.type == .coldPlunge ? AppTheme.coldPrimary : AppTheme.heatPrimary)
                    .symbol(Circle())
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Minutes", item.minutes)
                    )
                    .foregroundStyle(
                        (item.type == .coldPlunge ? AppTheme.coldPrimary : AppTheme.heatPrimary)
                            .opacity(0.1)
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartYAxisLabel("Minutes")
                .frame(height: 200)
            }
        }
    }
    
    // MARK: - Temperature Chart
    
    private var temperatureChart: some View {
        ChartCard(title: "Temperature Tolerance", icon: "thermometer.medium") {
            if temperatureData.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(temperatureData) { item in
                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Temp", item.temperature)
                    )
                    .foregroundStyle(item.type == .coldPlunge ? AppTheme.coldPrimary : AppTheme.heatPrimary)
                    .symbol(Circle())
                    
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Temp", item.temperature)
                    )
                    .foregroundStyle(item.type == .coldPlunge ? AppTheme.coldPrimary : AppTheme.heatPrimary)
                    .interpolationMethod(.catmullRom)
                }
                .chartYAxisLabel(settings.temperatureUnit.symbol)
                .frame(height: 200)
            }
        }
    }
    
    // MARK: - Type Distribution
    
    private var typeDistributionChart: some View {
        ChartCard(title: "Session Distribution", icon: "chart.pie.fill") {
            let coldCount = filteredSessions.filter { $0.type == .coldPlunge }.count
            let saunaCount = filteredSessions.filter { $0.type == .sauna }.count
            
            if coldCount == 0 && saunaCount == 0 {
                emptyChartPlaceholder
            } else {
                HStack(spacing: 40) {
                    // Pie chart representation
                    ZStack {
                        Circle()
                            .stroke(AppTheme.cardBackground, lineWidth: 20)
                            .frame(width: 120, height: 120)
                        
                        if coldCount + saunaCount > 0 {
                            Circle()
                                .trim(from: 0, to: CGFloat(coldCount) / CGFloat(coldCount + saunaCount))
                                .stroke(AppTheme.coldPrimary, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                            
                            Circle()
                                .trim(from: CGFloat(coldCount) / CGFloat(coldCount + saunaCount), to: 1)
                                .stroke(AppTheme.heatPrimary, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                        }
                        
                        Text("\(coldCount + saunaCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 16) {
                        LegendItem(color: AppTheme.coldPrimary, label: "Cold Plunge", value: coldCount)
                        LegendItem(color: AppTheme.heatPrimary, label: "Sauna", value: saunaCount)
                    }
                }
                .frame(height: 150)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyChartPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title)
                .foregroundColor(AppTheme.textTertiary)
            
            Text("Not enough data")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Data Helpers
    
    private var filteredSessions: [Session] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        }
        
        return dataManager.sessions.filter { $0.date >= startDate }
    }
    
    private var xAxisStride: Int {
        switch selectedTimeRange {
        case .week: return 1
        case .month: return 5
        case .year: return 30
        }
    }
    
    private var sessionsData: [SessionChartItem] {
        let calendar = Calendar.current
        var result: [SessionChartItem] = []
        
        for session in filteredSessions {
            let day = calendar.startOfDay(for: session.date)
            result.append(SessionChartItem(date: day, type: session.type, count: 1))
        }
        
        return result
    }
    
    private var durationData: [DurationChartItem] {
        filteredSessions.map { session in
            DurationChartItem(
                date: session.date,
                type: session.type,
                minutes: session.duration / 60
            )
        }
    }
    
    private var temperatureData: [TemperatureChartItem] {
        filteredSessions.compactMap { session in
            guard let temp = session.temperature else { return nil }
            return TemperatureChartItem(
                date: session.date,
                type: session.type,
                temperature: temp
            )
        }
    }
    
    private var hasTemperatureData: Bool {
        !temperatureData.isEmpty
    }
}

// MARK: - Chart Card

struct ChartCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.coldPrimary)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            content
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusLarge)
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String
    let value: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text("\(value) sessions")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

// MARK: - Chart Data Models

struct SessionChartItem: Identifiable {
    let id = UUID()
    let date: Date
    let type: SessionType
    let count: Int
}

struct DurationChartItem: Identifiable {
    let id = UUID()
    let date: Date
    let type: SessionType
    let minutes: Double
}

struct TemperatureChartItem: Identifiable {
    let id = UUID()
    let date: Date
    let type: SessionType
    let temperature: Double
}

// MARK: - Preview

#Preview {
    ChartsView()
}
