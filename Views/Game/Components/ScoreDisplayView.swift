//
//  ScoreDisplayView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct ScoreDisplayView: View {
    
    // MARK: - Properties
    let score: Int
    let showAnimation: Bool
    let style: ScoreDisplayStyle
    
    @State private var animateScore = false
    @State private var lastScore: Int
    @State private var showScoreChange = false
    @State private var scoreChange = 0
    @State private var pulseEffect = false
    
    // MARK: - Initialization
    init(score: Int, showAnimation: Bool = true, style: ScoreDisplayStyle = .standard) {
        self.score = score
        self.showAnimation = showAnimation
        self.style = style
        self._lastScore = State(initialValue: score)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Score icon
            scoreIcon
            
            // Score display
            scoreText
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(scoreBackground)
        .scaleEffect(animateScore ? 1.1 : 1.0)
        .overlay(scoreChangeOverlay)
        .onChange(of: score) { oldValue, newValue in
            handleScoreChange(from: oldValue, to: newValue)
        }
    }
    
    // MARK: - Score Icon
    private var scoreIcon: some View {
        Group {
            switch style {
            case .standard:
                Image(systemName: "star.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.yellow)
                    .rotationEffect(.degrees(pulseEffect ? 360 : 0))
                    .scaleEffect(pulseEffect ? 1.2 : 1.0)
                    .shadow(color: .yellow.opacity(0.6), radius: pulseEffect ? 4 : 0)
                    .animation(.easeInOut(duration: 0.6), value: pulseEffect)
                
            case .team:
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                    .scaleEffect(pulseEffect ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.6), value: pulseEffect)
                
            case .individual:
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
                    .scaleEffect(pulseEffect ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.6), value: pulseEffect)
                
            case .minimal:
                EmptyView()
            }
        }
    }
    
    // MARK: - Score Text
    private var scoreText: some View {
        VStack(alignment: .leading, spacing: 1) {
            // Score label
            if style != .minimal {
                Text(scoreLabel)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.8), radius: 1, x: 0.5, y: 0.5)
            }
            
            // Score value
            Text(formatScore(score))
                .font(scoreFontSize)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 1)
                .monospacedDigit()
        }
    }
    
    // MARK: - Score Background
    private var scoreBackground: some View {
        RoundedRectangle(cornerRadius: style == .minimal ? 8 : 12)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: style == .minimal ? 8 : 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
    }
    
    // MARK: - Score Change Overlay
    private var scoreChangeOverlay: some View {
        Group {
            if showScoreChange && scoreChange != 0 && showAnimation {
                HStack(spacing: 2) {
                    Image(systemName: scoreChange > 0 ? "plus" : "minus")
                        .font(.caption)
                        .fontWeight(.bold)
                    
                    Text("\(abs(scoreChange))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
                .foregroundColor(scoreChange > 0 ? .green : .red)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.9))
                        .overlay(
                            Capsule()
                                .stroke(scoreChange > 0 ? Color.green : Color.red, lineWidth: 1)
                        )
                )
                .offset(y: -25)
                .opacity(showScoreChange ? 1.0 : 0.0)
                .scaleEffect(showScoreChange ? 1.0 : 0.3)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showScoreChange)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var scoreLabel: String {
        switch style {
        case .standard: return "Score"
        case .team: return "Team"
        case .individual: return "You"
        case .minimal: return ""
        }
    }
    
    private var scoreFontSize: Font {
        switch style {
        case .standard: return .callout
        case .team: return .callout
        case .individual: return .caption
        case .minimal: return .caption
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .standard: return Color.black.opacity(0.6)
        case .team: return Color.blue.opacity(0.3)
        case .individual: return Color.green.opacity(0.3)
        case .minimal: return Color.black.opacity(0.4)
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .standard: return Color.white.opacity(0.3)
        case .team: return Color.blue.opacity(0.6)
        case .individual: return Color.green.opacity(0.6)
        case .minimal: return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        return style == .minimal ? 0 : 1
    }
    
    private var shadowColor: Color {
        switch style {
        case .standard: return Color.black.opacity(0.4)
        case .team: return Color.blue.opacity(0.3)
        case .individual: return Color.green.opacity(0.3)
        case .minimal: return Color.black.opacity(0.2)
        }
    }
    
    private var shadowRadius: CGFloat {
        return style == .minimal ? 2 : 4
    }
    
    // MARK: - Methods
    private func formatScore(_ score: Int) -> String {
        if score >= 1000000 {
            return String(format: "%.1fM", Double(score) / 1000000.0)
        } else if score >= 1000 {
            return String(format: "%.1fK", Double(score) / 1000.0)
        } else {
            return "\(score)"
        }
    }
    
    private func handleScoreChange(from oldValue: Int, to newValue: Int) {
        let change = newValue - oldValue
        lastScore = oldValue
        
        if change != 0 && showAnimation {
            // Trigger score change animation
            showScoreChangeAnimation(change)
            
            // Trigger pulse effect
            triggerPulseEffect()
            
            // Haptic feedback for positive score
            if change > 0 {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    private func showScoreChangeAnimation(_ change: Int) {
        scoreChange = change
        showScoreChange = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showScoreChange = false
        }
    }
    
    private func triggerPulseEffect() {
        withAnimation(.easeInOut(duration: 0.2)) {
            animateScore = true
            pulseEffect = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                animateScore = false
                pulseEffect = false
            }
        }
    }
}

// MARK: - Score Display Styles
enum ScoreDisplayStyle {
    case standard    // Default with icon and label
    case team       // Team score with blue theme
    case individual // Individual player score with green theme
    case minimal    // Compact version without icon
}

// MARK: - Multiplayer Score Board
struct MultiplayerScoreBoardView: View {
    let players: [NetworkPlayer]
    let teamScore: Int
    
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Team score
            ScoreDisplayView(score: teamScore, style: .team)
            
            // Toggle button for player details
            if players.count > 1 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showDetails.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                        Text("\(players.count) players")
                            .font(.caption2)
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Individual player scores
            if showDetails {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(players.sorted(by: { $0.score > $1.score }), id: \.id) { player in
                        PlayerScoreRowView(player: player)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Player Score Row
struct PlayerScoreRowView: View {
    let player: NetworkPlayer
    
    var body: some View {
        HStack(spacing: 8) {
            // Player indicator
            Circle()
                .fill(player.isLocal ? Color.green : Color.blue)
                .frame(width: 6, height: 6)
            
            // Player name
            Text(player.displayName)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
            
            Spacer()
            
            // Individual score
            ScoreDisplayView(score: player.score, showAnimation: false, style: .minimal)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.3))
        )
    }
}

// MARK: - Score Milestone View
struct ScoreMilestoneView: View {
    let milestone: ScoreMilestone
    let currentScore: Int
    
    @State private var showCelebration = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Milestone icon
            Image(systemName: milestone.icon)
                .font(.caption)
                .foregroundColor(milestone.color)
                .scaleEffect(showCelebration ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: showCelebration)
            
            // Progress bar
            ProgressView(value: min(Double(currentScore), Double(milestone.target)), total: Double(milestone.target))
                .progressViewStyle(LinearProgressViewStyle(tint: milestone.color))
                .frame(width: 80, height: 4)
            
            // Target score
            Text("\(milestone.target)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.4))
        )
        .onChange(of: currentScore) { oldValue, newValue in
            if newValue >= milestone.target && oldValue < milestone.target {
                triggerCelebration()
            }
        }
    }
    
    private func triggerCelebration() {
        showCelebration = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCelebration = false
        }
    }
}

// MARK: - Score Milestone Model
struct ScoreMilestone {
    let target: Int
    let icon: String
    let color: Color
    
    static let milestones: [ScoreMilestone] = [
        ScoreMilestone(target: 100, icon: "star", color: .yellow),
        ScoreMilestone(target: 500, icon: "star.fill", color: .orange),
        ScoreMilestone(target: 1000, icon: "crown", color: .purple),
        ScoreMilestone(target: 5000, icon: "crown.fill", color: .gold)
    ]
}

// MARK: - Extensions
extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ScoreDisplayView(score: 1250, style: .standard)
        ScoreDisplayView(score: 850, style: .team)
        ScoreDisplayView(score: 420, style: .individual)
        ScoreDisplayView(score: 99, style: .minimal)
        
        MultiplayerScoreBoardView(
            players: NetworkPlayerFactory.createTestPlayers(count: 3),
            teamScore: 1500
        )
        
        ScoreMilestoneView(
            milestone: ScoreMilestone.milestones[0],
            currentScore: 75
        )
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
