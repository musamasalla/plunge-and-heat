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
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
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

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: PlungeHeatEntry
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0A1628"), Color(hex: "0F1F35")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "snowflake")
                        .foregroundColor(Color(hex: "4FC3F7"))
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color(hex: "FF6B35"))
                    Spacer()
                }
                .font(.title3)
                
                Spacer()
                
                // Streak
                if entry.configuration.showStreak {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(entry.currentStreak)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text("day streak")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Today's sessions
                HStack(spacing: 4) {
                    Text("\(entry.todaySessions)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("today")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: PlungeHeatEntry
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0A1628"), Color(hex: "0F1F35")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 16) {
                // Left side - Stats
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Image(systemName: "snowflake")
                            .foregroundColor(Color(hex: "4FC3F7"))
                        Image(systemName: "flame.fill")
                            .foregroundColor(Color(hex: "FF6B35"))
                        
                        Text("Plunge & Heat")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Streak
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(entry.currentStreak)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("day streak")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Right side - Quick actions
                VStack(spacing: 8) {
                    QuickActionButton(
                        icon: "snowflake",
                        label: "Cold",
                        color: Color(hex: "4FC3F7")
                    )
                    
                    QuickActionButton(
                        icon: "flame.fill",
                        label: "Sauna",
                        color: Color(hex: "FF6B35")
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        Link(destination: URL(string: "plungeheat://log/\(label.lowercased())")!) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 50)
            .background(color.opacity(0.3))
            .cornerRadius(12)
        }
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
                .containerBackground(.clear, for: .widget)
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

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
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
