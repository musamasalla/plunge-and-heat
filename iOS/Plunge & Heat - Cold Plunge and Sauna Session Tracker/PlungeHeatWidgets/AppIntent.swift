//
//  AppIntent.swift
//  PlungeHeatWidgets
//
//  Created by Musa Masalla on 2025/12/17.
//

import WidgetKit
import AppIntents

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { IntentDescription("Configure the Plunge & Heat widget.") }
    
    @Parameter(title: "Show Streak", default: true)
    var showStreak: Bool
}
