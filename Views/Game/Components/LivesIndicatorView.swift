//
//  LivesIndicatorView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct LivesIndicatorView: View {
    
    // MARK: - Properties
    let lives: Int
    let maxLives: Int
    let showAnimation: Bool
    
    @State private var animateHeartbeat = false
    @State private var animateLoss = false
    @State private var lastLives: Int
    
    // MARK: - Initialization
    init(lives: Int, maxLives: Int = 5, showAnimation: Bool = true) {
        self.lives = lives
        self.maxLives = maxLives
        self.showAnimation = showAnimation
        self._lastLives = State(initialValue: lives)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Lives label
            Text("Lives:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 1)
            
            // Hearts display
            HStack(spacing: 4) {
                ForEach(0..<maxLives, id: \.self) { index in
                    heartView(for: index)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .onChange(of: lives) { oldValue, newValue in
            handleLivesChange(from: oldValue, to: newValue)
        }
        .onAppear {
            if showAnimation {
                startHeartbeatAnimation()
            }
        }
    }
    
    // MARK: - Heart View
    private func heartView(for index: Int) -> some View {
        let isAlive = index < lives
        let isRecentlyLost = index >= lives && index < lastLives && animateLoss
        
        return ZStack {
            // Heart background/shadow
            Image(systemName: "heart.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black.opacity(0.3))
                .offset(x: 1, y: 1)
            
            // Main heart
            Image(systemName: isAlive ? "heart.fill" : "heart")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(heartColor(for: index))
                .scaleEffect(heartScale(for: index))
                .opacity(heartOpacity(for: index))
                .animation(.easeInOut(duration: 0.3), value: lives)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: animateHeartbeat)
            
            // Loss animation overlay
            if isRecentlyLost {
                lossAnimationOverlay
            }
            
            // Critical warning overlay
            if lives <= 1 && isAlive && showAnimation {
                criticalWarningOverlay
            }
        }
    }
    
    // MARK: - Heart Properties
    private func heartColor(for index: Int) -> Color {
        let isAlive = index < lives
        
        if !isAlive {
            return .gray.opacity(0.4)
        }
        
        // Color based on remaining lives
        switch lives {
        case 5: return .green
        case 4: return .yellow
        case 3: return .orange
        case 2: return .red.opacity(0.8)
        case 1: return .red
        default: return .gray
        }
    }
    
    private func heartScale(for index: Int) -> CGFloat {
        let isAlive = index < lives
        
        if !isAlive {
            return 0.8
        }
        
        // Animate heartbeat for low lives
        if lives <= 2 && animateHeartbeat && showAnimation {
            return 1.2
        }
        
        return 1.0
    }
    
    private func heartOpacity(for index: Int) -> Double {
        let isAlive = index < lives
        return isAlive ? 1.0 : 0.6
    }
    
    // MARK: - Animation Overlays
    private var lossAnimationOverlay: some View {
        VStack {
            // Breaking animation
            ForEach(0..<6, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: 8))
                    .foregroundColor(.red)
                    .offset(
                        x: CGFloat.random(in: -15...15),
                        y: CGFloat.random(in: -15...15)
                    )
                    .opacity(animateLoss ? 0.0 : 1.0)
                    .animation(
                        .easeOut(duration: 0.6)
                        .delay(Double(i) * 0.1),
                        value: animateLoss
                    )
            }
        }
    }
    
    private var criticalWarningOverlay: some View {
        Circle()
            .stroke(Color.red, lineWidth: 2)
            .frame(width: 24, height: 24)
            .scaleEffect(animateHeartbeat ? 1.5 : 1.0)
            .opacity(animateHeartbeat ? 0.0 : 0.8)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: false), value: animateHeartbeat)
    }
    
    // MARK: - Animation Methods
    private func handleLivesChange(from oldValue: Int, to newValue: Int) {
        lastLives = oldValue
        
        if newValue < oldValue && showAnimation {
            // Lives lost - trigger loss animation
            triggerLossAnimation()
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
        
        // Update heartbeat animation based on current lives
        if newValue <= 2 && showAnimation {
            startHeartbeatAnimation()
        }
    }
    
    private func triggerLossAnimation() {
        animateLoss = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            animateLoss = false
        }
    }
    
    private func startHeartbeatAnimation() {
        guard showAnimation else { return }
        
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            animateHeartbeat = true
        }
    }
}

// MARK: - Team Lives Indicator
struct TeamLivesIndicatorView: View {
    let teamLives: Int
    let maxTeamLives: Int
    let playerCount: Int
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Team lives
            LivesIndicatorView(lives: teamLives, maxLives: maxTeamLives)
            
            // Player count
            if playerCount > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(playerCount) crew")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.4))
                )
            }
        }
    }
}

// MARK: - Animated Lives Counter
struct AnimatedLivesCounterView: View {
    let currentLives: Int
    let previousLives: Int
    
    @State private var showChange = false
    @State private var changeAmount = 0
    
    var body: some View {
        ZStack {
            LivesIndicatorView(lives: currentLives, maxLives: 5)
            
            // Change indicator
            if showChange && changeAmount != 0 {
                HStack {
                    Image(systemName: changeAmount > 0 ? "plus" : "minus")
                        .font(.caption)
                        .fontWeight(.bold)
                    
                    Text("\(abs(changeAmount))")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(changeAmount > 0 ? .green : .red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            Capsule()
                                .stroke(changeAmount > 0 ? Color.green : Color.red, lineWidth: 1)
                        )
                )
                .offset(y: -30)
                .opacity(showChange ? 1.0 : 0.0)
                .scaleEffect(showChange ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showChange)
            }
        }
        .onChange(of: currentLives) { oldValue, newValue in
            let change = newValue - oldValue
            if change != 0 {
                showChangeAnimation(change)
            }
        }
    }
    
    private func showChangeAnimation(_ change: Int) {
        changeAmount = change
        showChange = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showChange = false
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        LivesIndicatorView(lives: 5, maxLives: 5)
        LivesIndicatorView(lives: 3, maxLives: 5)
        LivesIndicatorView(lives: 1, maxLives: 5)
        TeamLivesIndicatorView(teamLives: 3, maxTeamLives: 5, playerCount: 4)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
