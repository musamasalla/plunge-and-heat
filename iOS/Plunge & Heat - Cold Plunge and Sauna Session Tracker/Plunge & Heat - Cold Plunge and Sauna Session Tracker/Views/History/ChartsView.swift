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
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var settings = SettingsManager.shared
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedChartType: ChartType = .sessions
    @State private var animateCharts = false
    
    enum TimeRange: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case threeMonths = "90D"
        case year = "1Y"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }
    
    enum ChartType: String, CaseIterable {
        case sessions = "Sessions"
        case duration = "Duration"
        case temperature = "Temperature"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Time range selector
                        timeRangeSelector
                        
                        // Chart type selector
                        chartTypeSelector
                        
                        // Main chart
                        mainChartCard
                        
                        // Summary stats
                        summaryStatsSection
                        
                        // Session type breakdown
                        sessionTypeBreakdown
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.coldPrimary)
                }
            }
            .onAppear {
                withAnimation(.spring().delay(0.3)) {
                    animateCharts = true
                }
            }
        }
    }
    
    // MARK: - Time Range Selector
    
    private var timeRangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    HapticFeedback.light()
                    withAnimation(.spring()) {
                        selectedTimeRange = range
                    }
                }) {
                    Text(range.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTimeRange == range ? .white : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTimeRange == range ?
                            AppTheme.coldPrimary : Color.clear
                        )
                }
            }
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Chart Type Selector
    
    private var chartTypeSelector: some View {
        HStack(spacing: 12) {
            ForEach(ChartType.allCases, id: \.self) { type in
                ChartTypeButton(
                    title: type.rawValue,
                    icon: iconForChartType(type),
                    isSelected: selectedChartType == type
                ) {
                    HapticFeedback.light()
                    withAnimation(.spring()) {
                        selectedChartType = type
                    }
                }
            }
        }
    }
    
    private func iconForChartType(_ type: ChartType) -> String {
        switch type {
        case .sessions: return "number.circle"
        case .duration: return "clock"
        case .temperature: return "thermometer.medium"
        }
    }
    
    // MARK: - Main Chart Card
    
    private var mainChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(chartTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(chartSubtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Text(trendText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(trendColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(trendColor.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Chart
            if filteredSessions.isEmpty {
                EmptyChartView()
            } else {
                chartView
                    .frame(height: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
        )
    }
    
    @ViewBuilder
    private var chartView: some View {
        switch selectedChartType {
        case .sessions:
            sessionsChart
        case .duration:
            durationChart
        case .temperature:
            temperatureChart
        }
    }
    
    private var chartTitle: String {
        switch selectedChartType {
        case .sessions: return "Sessions Over Time"
        case .duration: return "Duration Progress"
        case .temperature: return "Temperature Tolerance"
        }
    }
    
    private var chartSubtitle: String {
        "Last \(selectedTimeRange.days) days"
    }
    
    private var trendText: String {
        let trend = calculateTrend()
        if trend > 0 {
            return "+\(Int(trend))%"
        } else if trend < 0 {
            return "\(Int(trend))%"
        }
        return "—"
    }
    
    private var trendColor: Color {
        let trend = calculateTrend()
        if trend > 0 { return .green }
        if trend < 0 { return .red }
        return AppTheme.textSecondary
    }
    
    private func calculateTrend() -> Double {
        // Simple trend calculation
        let halfPoint = selectedTimeRange.days / 2
        let firstHalf = filteredSessions.filter {
            $0.date > Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date())! &&
            $0.date < Calendar.current.date(byAdding: .day, value: -halfPoint, to: Date())!
        }.count
        let secondHalf = filteredSessions.filter {
            $0.date >= Calendar.current.date(byAdding: .day, value: -halfPoint, to: Date())!
        }.count
        
        guard firstHalf > 0 else { return secondHalf > 0 ? 100 : 0 }
        return Double(secondHalf - firstHalf) / Double(firstHalf) * 100
    }
    
    // MARK: - Sessions Chart
    
    private var sessionsChart: some View {
        Chart {
            ForEach(sessionChartData, id: \.date) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Sessions", animateCharts ? item.count : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.coldPrimary, AppTheme.coldSecondary],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: selectedTimeRange == .week ? 1 : 7)) { _ in
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                    .foregroundStyle(AppTheme.textTertiary.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }
    
    // MARK: - Duration Chart
    
    private var durationChart: some View {
        Chart {
            ForEach(durationChartData, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Duration", animateCharts ? item.duration : 0)
                )
                .foregroundStyle(AppTheme.coldPrimary)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                
                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Duration", animateCharts ? item.duration : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.coldPrimary.opacity(0.3), AppTheme.coldPrimary.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: selectedTimeRange == .week ? 1 : 7)) { _ in
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                    .foregroundStyle(AppTheme.textTertiary.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }
    
    // MARK: - Temperature Chart
    
    private var temperatureChart: some View {
        Chart {
            ForEach(temperatureChartData, id: \.date) { item in
                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Temperature", animateCharts ? item.temperature : 50)
                )
                .foregroundStyle(item.type == .coldPlunge ? AppTheme.coldPrimary : AppTheme.heatPrimary)
                .symbolSize(100)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: selectedTimeRange == .week ? 1 : 7)) { _ in
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                    .foregroundStyle(AppTheme.textTertiary.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }
    
    // MARK: - Summary Stats Section
    
    private var summaryStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                SummaryStatCard(
                    title: "Total Sessions",
                    value: "\(filteredSessions.count)",
                    icon: "number.circle.fill",
                    color: .purple
                )
                
                SummaryStatCard(
                    title: "Total Time",
                    value: formatDuration(filteredSessions.reduce(0) { $0 + $1.duration }),
                    icon: "clock.fill",
                    color: .blue
                )
            }
            
            HStack(spacing: 12) {
                SummaryStatCard(
                    title: "Cold Plunges",
                    value: "\(filteredSessions.filter { $0.type == .coldPlunge }.count)",
                    icon: "snowflake",
                    color: AppTheme.coldPrimary
                )
                
                SummaryStatCard(
                    title: "Sauna Sessions",
                    value: "\(filteredSessions.filter { $0.type == .sauna }.count)",
                    icon: "flame.fill",
                    color: AppTheme.heatPrimary
                )
            }
        }
    }
    
    // MARK: - Session Type Breakdown
    
    private var sessionTypeBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Breakdown")
                .font(.headline)
                .foregroundColor(.white)
            
            let coldCount = filteredSessions.filter { $0.type == .coldPlunge }.count
            let saunaCount = filteredSessions.filter { $0.type == .sauna }.count
            let total = max(coldCount + saunaCount, 1)
            
            VStack(spacing: 12) {
                BreakdownRow(
                    title: "Cold Plunge",
                    count: coldCount,
                    percentage: Double(coldCount) / Double(total),
                    color: AppTheme.coldPrimary
                )
                
                BreakdownRow(
                    title: "Sauna",
                    count: saunaCount,
                    percentage: Double(saunaCount) / Double(total),
                    color: AppTheme.heatPrimary
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.cardBackground)
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredSessions: [Session] {
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date())!
        return dataManager.sessions.filter { $0.date >= startDate }
    }
    
    private var sessionChartData: [(date: Date, count: Int)] {
        var data: [(date: Date, count: Int)] = []
        let calendar = Calendar.current
        
        for i in (0..<selectedTimeRange.days).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let dayStart = calendar.startOfDay(for: date)
                let count = filteredSessions.filter { calendar.isDate($0.date, inSameDayAs: dayStart) }.count
                data.append((dayStart, count))
            }
        }
        return data
    }
    
    private var durationChartData: [(date: Date, duration: Double)] {
        sessionChartData.map { item in
            let totalDuration = filteredSessions
                .filter { Calendar.current.isDate($0.date, inSameDayAs: item.date) }
                .reduce(0) { $0 + $1.duration }
            return (item.date, totalDuration / 60) // Convert to minutes
        }
    }
    
    private var temperatureChartData: [(date: Date, temperature: Double, type: SessionType)] {
        filteredSessions.compactMap { session in
            guard let temp = session.temperature else { return nil }
            return (session.date, temp, session.type)
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Chart Type Button

struct ChartTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppTheme.coldPrimary : AppTheme.cardBackground)
            )
        }
    }
}

// MARK: - Empty Chart View

struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textTertiary)
            
            Text("No data yet")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Start logging sessions to see your progress")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Summary Stat Card

struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
    }
}

// MARK: - Breakdown Row

struct BreakdownRow: View {
    let title: String
    let count: Int
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(count) sessions")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.surfaceBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Preview

#Preview {
    ChartsView()
}
