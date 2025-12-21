//
//  PlungeHeatWidgets.swift
//  PlungeHeatWidgets
//
//  Created by Musa Masalla on 2025/12/17.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct PlungeHeatEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let todaySessions: Int
    let lastSessionType: String?
    let configuration: ConfigurationAppIntent
}

// MARK: - Timeline Provider

struct PlungeHeatProvider: AppIntentTimelineProvider {
    typealias Entry = PlungeHeatEntry
    typealias Intent = ConfigurationAppIntent
    
    func placeholder(in context: Context) -> PlungeHeatEntry {
        PlungeHeatEntry(
            date: Date(),
            currentStreak: 7,
            todaySessions: 1,
            lastSessionType: "Cold Plunge",
            configuration: ConfigurationAppIntent()
        )
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> PlungeHeatEntry {
        let data = loadSharedData()
        return PlungeHeatEntry(
            date: Date(),
            currentStreak: data.streak,
            todaySessions: data.todaySessions,
            lastSessionType: data.lastSessionType,
            configuration: configuration
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<PlungeHeatEntry> {
        let data = loadSharedData()
        let entry = PlungeHeatEntry(
            date: Date(),
            currentStreak: data.streak,
            todaySessions: data.todaySessions,
            lastSessionType: data.lastSessionType,
            configuration: configuration
        )
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadSharedData() -> (streak: Int, todaySessions: Int, lastSessionType: String?) {
        let defaults = UserDefaults(suiteName: "group.com.plungeheat.app")
        let streak = defaults?.integer(forKey: "currentStreak") ?? 0
        let todaySessions = defaults?.integer(forKey: "todaySessions") ?? 0
        let lastType = defaults?.string(forKey: "lastSessionType")
        return (streak, todaySessions, lastType)
    }
}

// MARK: - Theme Colors

private extension Color {
    static let widgetBackground = Color(red: 0.039, green: 0.086, blue: 0.157) // #0A1628
    static let coldAccent = Color(red: 0.31, green: 0.76, blue: 0.97) // #4FC3F7
    static let heatAccent = Color(red: 1.0, green: 0.42, blue: 0.21) // #FF6B35
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: PlungeHeatEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header icons
            HStack(spacing: 6) {
                Image(systemName: "snowflake")
                    .foregroundColor(.coldAccent)
                Image(systemName: "flame.fill")
                    .foregroundColor(.heatAccent)
            }
            .font(.headline)
            
            Spacer()
            
            // Streak display
            if entry.configuration.showStreak {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    Text("\(entry.currentStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text("day streak")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Today count
            HStack(spacing: 4) {
                Text("\(entry.todaySessions)")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("today")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: PlungeHeatEntry
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side - Stats
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(spacing: 6) {
                    Image(systemName: "snowflake")
                        .foregroundColor(.coldAccent)
                    Image(systemName: "flame.fill")
                        .foregroundColor(.heatAccent)
                    
                    Text("Plunge & Heat")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Streak
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.currentStreak)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("day streak")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Today sessions
                HStack(spacing: 4) {
                    Text("\(entry.todaySessions)")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text("sessions today")
                        .foregroundColor(.white.opacity(0.6))
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            // Right side - Quick actions
            VStack(spacing: 10) {
                QuickActionButton(
                    icon: "snowflake",
                    label: "Cold",
                    color: .coldAccent
                )
                
                QuickActionButton(
                    icon: "flame.fill",
                    label: "Sauna",
                    color: .heatAccent
                )
            }
            .padding(.trailing, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        if let url = URL(string: "plungeheat://log/\(label.lowercased())") {
            Link(destination: url) {
                buttonContent
            }
        } else {
            buttonContent
        }
    }
    
    private var buttonContent: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
            Text(label)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(.white)
        .frame(width: 56, height: 48)
        .background(color.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Widget Configuration

struct PlungeHeatWidget: Widget {
    let kind: String = "PlungeHeatWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: PlungeHeatProvider()
        ) { entry in
            PlungeHeatWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.widgetBackground
                }
        }
        .configurationDisplayName("Plunge & Heat")
        .description("Track your cold plunge and sauna streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PlungeHeatWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: PlungeHeatEntry
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    PlungeHeatWidget()
} timeline: {
    PlungeHeatEntry(date: Date(), currentStreak: 7, todaySessions: 1, lastSessionType: "Cold Plunge", configuration: ConfigurationAppIntent())
}

#Preview(as: .systemMedium) {
    PlungeHeatWidget()
} timeline: {
    PlungeHeatEntry(date: Date(), currentStreak: 14, todaySessions: 2, lastSessionType: "Sauna", configuration: ConfigurationAppIntent())
}
