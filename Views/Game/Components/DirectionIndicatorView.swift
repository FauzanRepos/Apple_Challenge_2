//
//  DirectionIndicatorView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI
import CoreGraphics

struct DirectionIndicatorView: View {
    
    // MARK: - Properties
    let playerPosition: CGPoint
    let targetPosition: CGPoint
    let style: DirectionIndicatorStyle
    let size: DirectionIndicatorSize
    let showDistance: Bool
    
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    
    // MARK: - Computed Properties
    private var angle: Double {
        let dx = targetPosition.x - playerPosition.x
        let dy = targetPosition.y - playerPosition.y
        let radians = atan2(dy, dx)
        return radians * 180 / .pi
    }
    
    private var distance: CGFloat {
        return playerPosition.distance(to: targetPosition)
    }
    
    private var isNearTarget: Bool {
        return distance < 100
    }
    
    private var urgencyLevel: UrgencyLevel {
        switch distance {
        case 0..<50: return .veryClose
        case 50..<150: return .close
        case 150..<300: return .moderate
        case 300..<500: return .far
        default: return .veryFar
        }
    }
    
    // MARK: - Initialization
    init(
        playerPosition: CGPoint,
        targetPosition: CGPoint,
        style: DirectionIndicatorStyle = .compass,
        size: DirectionIndicatorSize = .medium,
        showDistance: Bool = true
    ) {
        self.playerPosition = playerPosition
        self.targetPosition = targetPosition
        self.style = style
        self.size = size
        self.showDistance = showDistance
    }
    
    var body: some View {
        ZStack {
            // Background circle
            backgroundCircle
            
            // Main indicator
            mainIndicator
            
            // Distance display
            if showDistance && style != .minimal {
                distanceDisplay
            }
            
            // Urgency effects
            urgencyEffects
        }
        .frame(width: size.dimension, height: size.dimension)
        .onAppear {
            startAnimations()
        }
        .onChange(of: distance) { _, _ in
            updateAnimations()
        }
    }
    
    // MARK: - Background Circle
    private var backgroundCircle: some View {
        Circle()
            .fill(backgroundGradient)
            .overlay(
                Circle()
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
    }
    
    // MARK: - Main Indicator
    private var mainIndicator: some View {
        Group {
            switch style {
            case .compass:
                compassIndicator
            case .arrow:
                arrowIndicator
            case .pointer:
                pointerIndicator
            case .minimal:
                minimalIndicator
            }
        }
        .rotationEffect(.degrees(angle))
        .scaleEffect(isAnimating ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isAnimating)
    }
    
    // MARK: - Indicator Styles
    private var compassIndicator: some View {
        VStack(spacing: 2) {
            // Main needle
            Rectangle()
                .fill(LinearGradient(
                    colors: [needleColor, needleColor.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: 3, height: size.needleLength)
                .clipShape(Capsule())
            
            // Compass dot
            Circle()
                .fill(needleColor)
                .frame(width: 6, height: 6)
        }
        .offset(y: -size.needleLength / 4)
    }
    
    private var arrowIndicator: some View {
        Image(systemName: "arrowtriangle.up.fill")
            .font(.system(size: size.iconSize, weight: .bold))
            .foregroundColor(needleColor)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
    }
    
    private var pointerIndicator: some View {
        Image(systemName: "location.north.fill")
            .font(.system(size: size.iconSize, weight: .medium))
            .foregroundColor(needleColor)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
    }
    
    private var minimalIndicator: some View {
        Rectangle()
            .fill(needleColor)
            .frame(width: 2, height: size.needleLength * 0.8)
            .clipShape(Capsule())
            .offset(y: -size.needleLength * 0.2)
    }
    
    // MARK: - Distance Display
    private var distanceDisplay: some View {
        VStack(spacing: 1) {
            Text(formatDistance(distance))
                .font(.system(size: size.textSize, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 1)
            
            Text("to target")
                .font(.system(size: size.textSize - 2, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 1)
        }
        .offset(y: size.dimension * 0.3)
    }
    
    // MARK: - Urgency Effects
    private var urgencyEffects: some View {
        Group {
            switch urgencyLevel {
            case .veryClose:
                // Intense pulsing ring
                Circle()
                    .stroke(Color.green, lineWidth: 3)
                    .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                    .opacity(pulseAnimation ? 0.0 : 0.8)
                    .animation(.easeOut(duration: 0.8).repeatForever(autoreverses: false), value: pulseAnimation)
                
            case .close:
                // Moderate pulsing
                Circle()
                    .stroke(Color.yellow, lineWidth: 2)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0.0 : 0.6)
                    .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: pulseAnimation)
                
            default:
                EmptyView()
            }
        }
    }
    
    // MARK: - Computed Styling Properties
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.black.opacity(0.8),
                Color.black.opacity(0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var borderColor: Color {
        switch urgencyLevel {
        case .veryClose: return .green
        case .close: return .yellow
        case .moderate: return .orange
        case .far: return .blue
        case .veryFar: return .gray
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .minimal: return 1
        default: return 2
        }
    }
    
    private var needleColor: Color {
        switch urgencyLevel {
        case .veryClose: return .green
        case .close: return .yellow
        case .moderate: return .orange
        case .far: return .blue
        case .veryFar: return .gray
        }
    }
    
    private var shadowColor: Color {
        return needleColor.opacity(0.3)
    }
    
    private var shadowRadius: CGFloat {
        return isNearTarget ? 8 : 4
    }
    
    // MARK: - Animation Methods
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
    
    private func updateAnimations() {
        // Trigger animation when distance changes significantly
        isAnimating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = false
        }
    }
    
    // MARK: - Helper Methods
    private func formatDistance(_ distance: CGFloat) -> String {
        let roundedDistance = Int(distance)
        
        if roundedDistance < 10 {
            return "CLOSE"
        } else if roundedDistance < 100 {
            return "\(roundedDistance)m"
        } else if roundedDistance < 1000 {
            return "\(roundedDistance/10*10)m"
        } else {
            return "\(roundedDistance/100)km"
        }
    }
}

// MARK: - Multi-Target Direction Indicator
struct MultiTargetDirectionIndicatorView: View {
    let playerPosition: CGPoint
    let targets: [DirectionTarget]
    let selectedTargetId: String?
    
    var body: some View {
        ZStack {
            ForEach(targets, id: \.id) { target in
                let isSelected = target.id == selectedTargetId
                
                DirectionIndicatorView(
                    playerPosition: playerPosition,
                    targetPosition: target.position,
                    style: isSelected ? .compass : .minimal,
                    size: isSelected ? .medium : .small,
                    showDistance: isSelected
                )
                .opacity(isSelected ? 1.0 : 0.6)
                .scaleEffect(isSelected ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 0.3), value: isSelected)
            }
        }
    }
}

// MARK: - Checkpoint Progress Indicator
struct CheckpointProgressIndicatorView: View {
    let playerPosition: CGPoint
    let checkpoints: [Checkpoint]
    let completedCheckpoints: Set<String>
    
    private var nextCheckpoint: Checkpoint? {
        checkpoints
            .filter { !completedCheckpoints.contains($0.id) }
            .min { checkpoint1, checkpoint2 in
                checkpoint1.position.distance(to: playerPosition) <
                checkpoint2.position.distance(to: playerPosition)
            }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Direction to next checkpoint
            if let checkpoint = nextCheckpoint {
                DirectionIndicatorView(
                    playerPosition: playerPosition,
                    targetPosition: checkpoint.position,
                    style: .compass,
                    size: .medium
                )
                
                // Progress indicator
                progressIndicator
            } else {
                // All checkpoints completed
                completedIndicator
            }
        }
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<checkpoints.count, id: \.self) { index in
                let checkpoint = checkpoints[index]
                let isCompleted = completedCheckpoints.contains(checkpoint.id)
                
                Circle()
                    .fill(isCompleted ? Color.green : Color.gray.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .scaleEffect(isCompleted ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isCompleted)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
        )
    }
    
    private var completedIndicator: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
            
            Text("All Checkpoints")
                .font(.caption2)
                .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 1)
                )
        )
    }
}

// MARK: - Supporting Types
enum DirectionIndicatorStyle {
    case compass    // Classic compass needle
    case arrow      // Simple arrow
    case pointer    // Location pointer
    case minimal    // Minimal line
}

enum DirectionIndicatorSize {
    case small, medium, large
    
    var dimension: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 60
        case .large: return 80
        }
    }
    
    var needleLength: CGFloat {
        return dimension * 0.4
    }
    
    var iconSize: CGFloat {
        return dimension * 0.3
    }
    
    var textSize: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        }
    }
}

enum UrgencyLevel {
    case veryClose, close, moderate, far, veryFar
}

struct DirectionTarget: Identifiable {
    let id: String
    let position: CGPoint
    let type: TargetType
    let priority: Int
}

enum TargetType {
    case checkpoint, finish, powerUp, player
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        DirectionIndicatorView(
            playerPosition: CGPoint(x: 100, y: 100),
            targetPosition: CGPoint(x: 200, y: 50),
            style: .compass,
            size: .medium
        )
        
        DirectionIndicatorView(
            playerPosition: CGPoint(x: 100, y: 100),
            targetPosition: CGPoint(x: 120, y: 110),
            style: .arrow,
            size: .small
        )
        
        CheckpointProgressIndicatorView(
            playerPosition: CGPoint(x: 100, y: 100),
            checkpoints: [
                Checkpoint(id: "1", position: CGPoint(x: 150, y: 150)),
                Checkpoint(id: "2", position: CGPoint(x: 200, y: 200)),
                Checkpoint(id: "3", position: CGPoint(x: 250, y: 250))
            ],
            completedCheckpoints: ["1"]
        )
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
