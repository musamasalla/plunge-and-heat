//
//  Theme.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

// MARK: - App Theme

struct AppTheme {
    // MARK: - Cold Colors (Ice Blue Palette)
    static let coldPrimary = Color(red: 0.0, green: 0.71, blue: 0.89)      // #00B5E3
    static let coldSecondary = Color(red: 0.4, green: 0.85, blue: 0.95)    // #66D9F2
    static let coldAccent = Color(red: 0.2, green: 0.6, blue: 0.8)         // #3399CC
    static let coldBackground = Color(red: 0.05, green: 0.15, blue: 0.25) // Deep icy blue
    
    static let coldGradient = LinearGradient(
        colors: [coldPrimary, coldSecondary, Color.white.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Heat Colors (Warm Orange/Red Palette)
    static let heatPrimary = Color(red: 1.0, green: 0.4, blue: 0.2)        // #FF6633
    static let heatSecondary = Color(red: 1.0, green: 0.6, blue: 0.3)      // #FF994D
    static let heatAccent = Color(red: 0.9, green: 0.3, blue: 0.1)         // #E64D1A
    static let heatBackground = Color(red: 0.25, green: 0.1, blue: 0.05)   // Deep warm brown
    
    static let heatGradient = LinearGradient(
        colors: [heatPrimary, heatSecondary, Color.yellow.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Neutral Colors
    static let background = Color(red: 0.07, green: 0.07, blue: 0.1)       // #121219
    static let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.15)  // #1E1E26
    static let surfaceBackground = Color(red: 0.15, green: 0.15, blue: 0.18)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    
    // MARK: - Success/Warning/Error
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)            // Green
    static let warning = Color(red: 1.0, green: 0.8, blue: 0.2)            // Yellow
    static let error = Color(red: 1.0, green: 0.3, blue: 0.3)              // Red
    
    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let paddingXLarge: CGFloat = 32
    
    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 20
    static let cornerRadiusXLarge: CGFloat = 28
    
    // MARK: - Shadows
    static let shadowRadius: CGFloat = 10
    static let shadowOpacity: Double = 0.3
    
    // MARK: - Animation
    static let animationDuration: Double = 0.3
    static let springResponse: Double = 0.5
    static let springDamping: Double = 0.7
}

// MARK: - Session Type

enum SessionType: String, Codable, CaseIterable {
    case coldPlunge = "cold"
    case sauna = "sauna"
    
    var displayName: String {
        switch self {
        case .coldPlunge: return "Cold Plunge"
        case .sauna: return "Sauna"
        }
    }
    
    var icon: String {
        switch self {
        case .coldPlunge: return "snowflake"
        case .sauna: return "flame.fill"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .coldPlunge: return AppTheme.coldPrimary
        case .sauna: return AppTheme.heatPrimary
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .coldPlunge: return AppTheme.coldGradient
        case .sauna: return AppTheme.heatGradient
        }
    }
    
    var calendarDotColor: Color {
        switch self {
        case .coldPlunge: return AppTheme.coldPrimary
        case .sauna: return AppTheme.heatPrimary
        }
    }
}

// MARK: - Temperature Unit

enum TemperatureUnit: String, Codable, CaseIterable {
    case fahrenheit = "F"
    case celsius = "C"
    
    var displayName: String {
        switch self {
        case .fahrenheit: return "Fahrenheit (°F)"
        case .celsius: return "Celsius (°C)"
        }
    }
    
    var symbol: String {
        switch self {
        case .fahrenheit: return "°F"
        case .celsius: return "°C"
        }
    }
    
    func convert(_ value: Double, to unit: TemperatureUnit) -> Double {
        if self == unit { return value }
        switch (self, unit) {
        case (.fahrenheit, .celsius):
            return (value - 32) * 5 / 9
        case (.celsius, .fahrenheit):
            return value * 9 / 5 + 32
        default:
            return value
        }
    }
}

// MARK: - View Modifiers

struct GlassmorphicCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusLarge)
            .shadow(color: .black.opacity(0.2), radius: AppTheme.shadowRadius)
    }
}

extension View {
    func glassmorphic() -> some View {
        modifier(GlassmorphicCard())
    }
    
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Button Styles

struct SessionButtonStyle: ButtonStyle {
    let sessionType: SessionType
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = AppTheme.coldPrimary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, AppTheme.paddingLarge)
            .padding(.vertical, AppTheme.paddingMedium)
            .background(color)
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        
        VStack(spacing: 20) {
            Text("Cold Plunge")
                .font(.title)
                .foregroundColor(AppTheme.coldPrimary)
            
            Text("Sauna")
                .font(.title)
                .foregroundColor(AppTheme.heatPrimary)
            
            HStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.coldGradient)
                    .frame(width: 100, height: 100)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.heatGradient)
                    .frame(width: 100, height: 100)
            }
        }
    }
}
