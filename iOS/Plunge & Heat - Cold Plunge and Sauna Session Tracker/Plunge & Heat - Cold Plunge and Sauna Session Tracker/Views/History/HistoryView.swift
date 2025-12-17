//
//  HistoryView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

// MARK: - History View

struct HistoryView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var settings = SettingsManager.shared
    
    @State private var selectedDate = Date()
    @State private var selectedFilter: SessionFilter = .all
    @State private var showingChartsView = false
    @State private var selectedSession: Session?
    @State private var animateStats = false
    
    enum SessionFilter: String, CaseIterable {
        case all = "All"
        case coldPlunge = "Cold"
        case sauna = "Sauna"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Stats overview
                        statsOverview
                        
                        // Calendar strip
                        calendarStrip
                        
                        // Filter chips
                        filterChips
                        
                        // Sessions list
                        sessionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingChartsView = true }) {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundColor(AppTheme.coldPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingChartsView) {
                ChartsView()
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
            .onAppear {
                withAnimation(.spring().delay(0.2)) {
                    animateStats = true
                }
            }
        }
    }
    
    // MARK: - Stats Overview
    
    private var statsOverview: some View {
        HStack(spacing: 12) {
            AnimatedStatBox(
                value: dataManager.statistics.totalSessions,
                label: "Sessions",
                icon: "number.circle.fill",
                color: AppTheme.coldPrimary,
                animate: animateStats
            )
            
            AnimatedStatBox(
                value: Int(dataManager.statistics.totalDuration / 60),
                label: "Minutes",
                icon: "clock.fill",
                color: .purple,
                animate: animateStats
            )
            
            AnimatedStatBox(
                value: settings.longestStreak,
                label: "Best Streak",
                icon: "flame.fill",
                color: .orange,
                animate: animateStats
            )
        }
    }
    
    // MARK: - Calendar Strip
    
    private var calendarStrip: some View {
        VStack(spacing: 16) {
            // Month/Year header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(AppTheme.coldPrimary)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(AppTheme.coldPrimary)
                }
            }
            
            // Week days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            sessions: dataManager.sessionsForDate(date)
                        ) {
                            HapticFeedback.light()
                            withAnimation(.spring()) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Text("")
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
        )
    }
    
    // MARK: - Filter Chips
    
    private var filterChips: some View {
        HStack(spacing: 12) {
            ForEach(SessionFilter.allCases, id: \.self) { filter in
                FilterChip(
                    title: filter.rawValue,
                    isSelected: selectedFilter == filter,
                    color: chipColor(for: filter)
                ) {
                    HapticFeedback.light()
                    withAnimation(.spring()) {
                        selectedFilter = filter
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private func chipColor(for filter: SessionFilter) -> Color {
        switch filter {
        case .all: return AppTheme.coldPrimary
        case .coldPlunge: return AppTheme.coldPrimary
        case .sauna: return AppTheme.heatPrimary
        }
    }
    
    // MARK: - Sessions Section
    
    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(sessionsSectionTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(filteredSessions.count) sessions")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            
            if filteredSessions.isEmpty {
                EmptySessionsCard()
            } else {
                ForEach(filteredSessions) { session in
                    HistorySessionRow(session: session) {
                        selectedSession = session
                    }
                }
            }
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - Computed Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var daysInMonth: [Date?] {
        var days: [Date?] = []
        let calendar = Calendar.current
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return days
        }
        
        // Add empty cells for days before the first of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add days of the month
        var date = monthInterval.start
        while date < monthInterval.end {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return days
    }
    
    private var sessionsSectionTitle: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }
    
    private var filteredSessions: [Session] {
        let dateSessions = dataManager.sessionsForDate(selectedDate)
        switch selectedFilter {
        case .all: return dateSessions
        case .coldPlunge: return dateSessions.filter { $0.type == .coldPlunge }
        case .sauna: return dateSessions.filter { $0.type == .sauna }
        }
    }
    
    // MARK: - Actions
    
    private func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
            withAnimation(.spring()) {
                selectedDate = newDate
            }
        }
    }
    
    private func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
            withAnimation(.spring()) {
                selectedDate = newDate
            }
        }
    }
}

// MARK: - Animated Stat Box

struct AnimatedStatBox: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    let animate: Bool
    
    @State private var displayValue = 0
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(displayValue)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .onChange(of: animate) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    displayValue = value
                }
            }
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let sessions: [Session]
    let action: () -> Void
    
    private var hasCold: Bool { sessions.contains { $0.type == .coldPlunge } }
    private var hasHeat: Bool { sessions.contains { $0.type == .sauna } }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(textColor)
                
                // Session indicators
                if !sessions.isEmpty {
                    HStack(spacing: 2) {
                        if hasCold {
                            Circle()
                                .fill(AppTheme.coldPrimary)
                                .frame(width: 5, height: 5)
                        }
                        if hasHeat {
                            Circle()
                                .fill(AppTheme.heatPrimary)
                                .frame(width: 5, height: 5)
                        }
                    }
                } else {
                    Spacer()
                        .frame(height: 5)
                }
            }
            .frame(width: 40, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isToday && !isSelected ? AppTheme.coldPrimary : Color.clear, lineWidth: 1)
            )
        }
    }
    
    private var textColor: Color {
        if isSelected { return .white }
        if Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedDescending {
            return AppTheme.textTertiary
        }
        return .white
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return AppTheme.coldPrimary
        }
        return Color.clear
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? color : AppTheme.cardBackground)
                )
        }
    }
}

// MARK: - Empty Sessions Card

struct EmptySessionsCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 44))
                .foregroundColor(AppTheme.textTertiary)
            
            Text("No sessions")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Log your first session for this day")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [8]))
                        .foregroundColor(AppTheme.textTertiary.opacity(0.3))
                )
        )
    }
}

// MARK: - History Session Row

struct HistorySessionRow: View {
    let session: Session
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(session.type.gradient)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: session.type.icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.type.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 16) {
                        Label(session.durationFormatted, systemImage: "clock")
                        
                        if let temp = session.temperatureFormatted {
                            Label(temp, systemImage: "thermometer.medium")
                        }
                        
                        if let hr = session.heartRate {
                            Label("\(hr)", systemImage: "heart.fill")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatTime(session.date))
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.cardBackground)
            )
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
}
