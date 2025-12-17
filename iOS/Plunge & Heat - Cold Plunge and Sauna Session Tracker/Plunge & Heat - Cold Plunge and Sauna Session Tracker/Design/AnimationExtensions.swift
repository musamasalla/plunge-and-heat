//
//  AnimationExtensions.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

// MARK: - Custom Transitions

extension AnyTransition {
    static var slideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    static var fadeScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        )
    }
    
    static var slideFromTrailing: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
    }
}

// MARK: - Animation Modifiers

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.9 : 1.0)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct ShimmerAnimation: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.2),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(70))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

struct BounceAnimation: ViewModifier {
    @State private var isBouncing = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isBouncing ? -5 : 0)
            .animation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true),
                value: isBouncing
            )
            .onAppear {
                isBouncing = true
            }
    }
}

struct GlowAnimation: ViewModifier {
    let color: Color
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isGlowing ? 0.6 : 0.2), radius: isGlowing ? 15 : 5)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
                value: isGlowing
            )
            .onAppear {
                isGlowing = true
            }
    }
}

// MARK: - View Extensions

extension View {
    func pulseAnimation() -> some View {
        modifier(PulseAnimation())
    }
    
    func shimmerAnimation() -> some View {
        modifier(ShimmerAnimation())
    }
    
    func bounceAnimation() -> some View {
        modifier(BounceAnimation())
    }
    
    func glowAnimation(color: Color = .white) -> some View {
        modifier(GlowAnimation(color: color))
    }
    
    // Success animation
    func successAnimation(trigger: Bool) -> some View {
        self
            .scaleEffect(trigger ? 1.0 : 0.8)
            .opacity(trigger ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: trigger)
    }
    
    // Card hover effect
    func cardHoverEffect(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
    }
}

// MARK: - Animated Counter

struct AnimatedCounter: View {
    let value: Int
    let font: Font
    let color: Color
    
    @State private var displayedValue: Int = 0
    
    var body: some View {
        Text("\(displayedValue)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    displayedValue = newValue
                }
            }
            .onAppear {
                displayedValue = value
            }
    }
}

// MARK: - Celebration Burst

struct CelebrationBurstView: View {
    @State private var particles: [BurstParticle] = []
    @State private var isAnimating = false
    
    let colors: [Color]
    
    init(colors: [Color] = [.yellow, .orange, .red, .green, .blue, .purple]) {
        self.colors = colors
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(
                            x: geometry.size.width / 2 + particle.offset.width,
                            y: geometry.size.height / 2 + particle.offset.height
                        )
                        .opacity(particle.opacity)
                }
            }
        }
        .onAppear {
            createBurst()
        }
    }
    
    private func createBurst() {
        for i in 0..<20 {
            let angle = Double(i) * (360.0 / 20.0) * .pi / 180
            let distance: CGFloat = CGFloat.random(in: 50...150)
            
            var particle = BurstParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...14),
                offset: .zero,
                opacity: 1.0
            )
            
            particles.append(particle)
            
            let index = particles.count - 1
            
            withAnimation(.easeOut(duration: 0.6)) {
                particles[index].offset = CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                )
            }
            
            withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
                particles[index].opacity = 0
            }
        }
    }
}

struct BurstParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var offset: CGSize
    var opacity: Double
}

// MARK: - Loading Dots

struct LoadingDotsView: View {
    @State private var activeIndex = 0
    let color: Color
    
    init(color: Color = AppTheme.coldPrimary) {
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .scaleEffect(activeIndex == index ? 1.3 : 1.0)
                    .opacity(activeIndex == index ? 1.0 : 0.5)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    activeIndex = (activeIndex + 1) % 3
                }
            }
        }
    }
}

// MARK: - Progress Ring

struct ProgressRingView: View {
    let progress: Double
    let lineWidth: CGFloat
    let gradient: LinearGradient
    
    init(progress: Double, lineWidth: CGFloat = 8, gradient: LinearGradient? = nil) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.gradient = gradient ?? LinearGradient(
            colors: [AppTheme.coldPrimary, AppTheme.coldSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.surfaceBackground, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

// MARK: - Preview

#Preview("Animations") {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        
        VStack(spacing: 30) {
            Text("Pulse Animation")
                .foregroundColor(.white)
                .pulseAnimation()
            
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.coldPrimary)
                .frame(width: 200, height: 50)
                .shimmerAnimation()
            
            Image(systemName: "arrow.down")
                .font(.title)
                .foregroundColor(.white)
                .bounceAnimation()
            
            Circle()
                .fill(AppTheme.heatPrimary)
                .frame(width: 60, height: 60)
                .glowAnimation(color: AppTheme.heatPrimary)
            
            ProgressRingView(progress: 0.7)
                .frame(width: 80, height: 80)
            
            LoadingDotsView()
        }
    }
}
