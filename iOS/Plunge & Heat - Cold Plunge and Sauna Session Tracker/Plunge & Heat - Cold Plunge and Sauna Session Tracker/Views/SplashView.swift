//
//  SplashView.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/18.
//

import SwiftUI

// MARK: - Splash View (for programmatic launch screen)

struct SplashView: View {
    @State private var showLogo = false
    @State private var showText = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0A1628"), Color(hex: "0F1F35"), Color(hex: "0A1628")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.coldPrimary.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseScale)
                    
                    // Icon container
                    ZStack {
                        // Snowflake
                        Image(systemName: "snowflake")
                            .font(.system(size: 44))
                            .foregroundColor(AppTheme.coldPrimary)
                            .offset(x: -15, y: -10)
                        
                        // Flame
                        Image(systemName: "flame.fill")
                            .font(.system(size: 44))
                            .foregroundColor(AppTheme.heatPrimary)
                            .offset(x: 15, y: 10)
                    }
                }
                .scaleEffect(showLogo ? 1 : 0.5)
                .opacity(showLogo ? 1 : 0)
                
                // App name
                VStack(spacing: 8) {
                    Text("Plunge & Heat")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Cold Plunge & Sauna Tracker")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .opacity(showText ? 1 : 0)
                .offset(y: showText ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                showLogo = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showText = true
            }
            
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
            }
        }
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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

#Preview {
    SplashView()
}
