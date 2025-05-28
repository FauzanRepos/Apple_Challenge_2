//
//  MultiplayerHUDView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct MultiplayerHUDView: View {
    
    // MARK: - Properties
    let gameState: GameState
    let players: [NetworkPlayer]
    let currentLevel: Int
    let missionClue: String
    let showFullHUD: Bool
    
    @State private var showPlayerList = false
    @State private var showMissionDetails = false
    @State private var animateAlert = false
    @State private var lastPlayerCount: Int = 0
    
    // MARK: - Initialization
    init(
        gameState: GameState,
        players: [NetworkPlayer] = [],
        currentLevel: Int = 1,
        missionClue: String = "Find the space station!",
        showFullHUD: Bool = true
    ) {
        self.gameState = gameState
        self.players = players
        self.currentLevel = currentLevel
        self.missionClue = missionClue
        self.showFullHUD = showFullHUD
        self._lastPlayerCount = StateS(initialValue: players.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top HUD Elements
            topHUDElements
            
            Spacer()
            
            // Bottom HUD Elements
            if showFullHUD {
                bottomHUDElements
            }
        }
        .onChange(of: players.count) { oldValue, newValue in
            handlePlayerCountChange(from: oldValue, to: newValue)
        }
    }
    
    // MARK: - Top HUD Elements
    private var topHUDElements: some View {
        HStack {
            // Mission clue panel
            missionCluePanel
            
            Spacer()
            
            // Connection status and player count
            connectionStatusPanel
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Mission Clue Panel
    private var missionCluePanel: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showMissionDetails.toggle()
            }
        }) {
            HStack(spacing: 8) {
                // Mission icon
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(animateAlert ? 10 : -10))
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateAlert)
                
                // Mission text
                VStack(alignment: .leading, spacing: 2) {
                    Text("MISSION")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text(missionClue)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(showMissionDetails ? nil : 1)
                        .multilineTextAlignment(.leading)
                }
                
                // Expand indicator
                if !showMissionDetails {
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(missionBackground)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var missionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.6), Color.orange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .orange.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Connection Status Panel
    private var connectionStatusPanel: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showPlayerList.toggle()
            }
        }) {
            HStack(spacing: 8) {
                // Connection quality indicator
                connectionQualityIndicator
                
                // Player count
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(connectedPlayersCount)/\(players.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .monospacedDigit()
                    
                    Text("CREW")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // Expand indicator
                Image(systemName: showPlayerList ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(connectionBackground)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var connectionQualityIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(connectionBarColor(for: index))
                    .frame(width: 3, height: CGFloat(4 + index * 2))
                    .scaleEffect(y: connectionBarScale(for: index))
                    .animation(.easeInOut(duration: 0.5), value: averageConnectionQuality)
            }
        }
    }
    
    private var connectionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(connectionBorderColor, lineWidth: 1)
            )
            .shadow(color: connectionBorderColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Bottom HUD Elements
    private var bottomHUDElements: some View {
        VStack(spacing: 12) {
            // Expanded player list
            if showPlayerList {
                expandedPlayerList
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            // Game status bar
            gameStatusBar
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Expanded Player List
    private var expandedPlayerList: some View {
        VStack(spacing: 6) {
            ForEach(players.sorted(by: { $0.score > $1.score }), id: \.id) { player in
                PlayerStatusRowView(player: player)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Game Status Bar
    private var gameStatusBar: some View {
        HStack(spacing: 16) {
            // Level progress
            levelProgressIndicator
            
            Spacer()
            
            // Team performance
            teamPerformanceIndicator
            
            Spacer()
            
            // Game timer
            gameTimerIndicator
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Status Indicators
    private var levelProgressIndicator: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("LEVEL \(currentLevel)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            ProgressView(value: gameState.levelProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(width: 60, height: 4)
        }
    }
    
    private var teamPerformanceIndicator: some View {
        VStack(spacing: 2) {
            Text("TEAM")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text(teamPerformanceText)
                .font(.caption)
                .foregroundColor(.white)
                .monospacedDigit()
        }
    }
    
    private var gameTimerIndicator: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("TIME")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            Text(gameState.gameTime)
                .font(.caption)
                .foregroundColor(.white)
                .monospacedDigit()
        }
    }
    
    // MARK: - Computed Properties
    private var connectedPlayersCount: Int {
        return players.filter { $0.isConnected() }.count
    }
    
    private var averageConnectionQuality: NetworkQuality {
        let qualities = players.compactMap { $0.connectionQuality }
        guard !qualities.isEmpty else { return .good }
        
        let averageRawValue = qualities.reduce(0) { $0 + $1.rawValue.hashValue } / qualities.count
        return NetworkQuality.allCases[min(averageRawValue, NetworkQuality.allCases.count - 1)]
    }
    
    private var connectionBorderColor: Color {
        switch averageConnectionQuality {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .orange
        case .terrible: return .red
        }
    }
    
    private var teamPerformanceText: String {
        let aliveCount = players.filter { $0.isAlive }.count
        return "\(aliveCount)/\(players.count)"
    }
    
    // MARK: - Connection Quality Methods
    private func connectionBarColor(for index: Int) -> Color {
        let qualityLevel = connectionQualityLevel()
        
        if index < qualityLevel {
            switch averageConnectionQuality {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .yellow
            case .poor, .terrible: return .red
            }
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private func connectionBarScale(for index: Int) -> CGFloat {
        let qualityLevel = connectionQualityLevel()
        return index < qualityLevel ? 1.0 : 0.3
    }
    
    private func connectionQualityLevel() -> Int {
        switch averageConnectionQuality {
        case .excellent: return 3
        case .good: return 2
        case .fair: return 1
        case .poor, .terrible: return 0
        }
    }
    
    // MARK: - Event Handlers
    private func handlePlayerCountChange(from oldValue: Int, to newValue: Int) {
        lastPlayerCount = oldValue
        
        if newValue != oldValue {
            // Trigger alert animation
            withAnimation(.easeInOut(duration: 0.5)) {
                animateAlert = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                animateAlert = false
            }
        }
    }
    
    // MARK: - Mission Clues
    static func getMissionClue(for level: Int, checkpointsRemaining: Int) -> String {
        if checkpointsRemaining == 0 {
            return "All checkpoints secured! Find the space station!"
        }
        
        let clues = [
            "Navigate through the maze to find all checkpoints",
            "Work together to reach each checkpoint safely",
            "Avoid the red vortexes - they're deadly!",
            "Collect power-ups to enhance your abilities",
            "Some crew members can scroll the map at edges",
            "Stay close to your team for better coordination",
            "The space station awaits at the end",
            "Time is running out - move quickly!"
        ]
        
        let baseIndex = (level - 1) % clues.count
        return clues[baseIndex]
    }
}

// MARK: - Player Status Row
struct PlayerStatusRowView: View {
    let player: NetworkPlayer
    
    var body: some View {
        HStack(spacing: 8) {
            // Player status indicator
            playerStatusIndicator
            
            // Player name and role
            VStack(alignment: .leading, spacing: 1) {
                Text(player.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(player.roleText)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Connection quality
            HStack(spacing: 2) {
                Circle()
                    .fill(Color(hex: player.connectionQuality.color) ?? .gray)
                    .frame(width: 6, height: 6)
                
                Text(player.ping < 0.1 ? "\(Int(player.ping * 1000))ms" : "---")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .monospacedDigit()
            }
            
            // Player score
            Text("\(player.score)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(playerBackgroundColor)
        )
        .opacity(player.isAlive ? 1.0 : 0.6)
    }
    
    private var playerStatusIndicator: some View {
        ZStack {
            Circle()
                .fill(player.isLocal ? Color.green : Color.blue)
                .frame(width: 12, height: 12)
            
            if !player.isAlive {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            } else if player.isReady {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var playerBackgroundColor: Color {
        if player.isLocal {
            return Color.green.opacity(0.2)
        } else if player.isHost {
            return Color.blue.opacity(0.2)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
}

// MARK: - Compact Multiplayer HUD
struct CompactMultiplayerHUDView: View {
    let players: [NetworkPlayer]
    let gameState: GameState
    
    var body: some View {
        HStack(spacing: 12) {
            // Quick player indicators
            HStack(spacing: 4) {
                ForEach(players.prefix(6), id: \.id) { player in
                    Circle()
                        .fill(player.isAlive ? (player.isLocal ? .green : .blue) : .red)
                        .frame(width: 8, height: 8)
                        .opacity(player.isConnected() ? 1.0 : 0.4)
                }
                
                if players.count > 6 {
                    Text("+\(players.count - 6)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Team lives
            HStack(spacing: 2) {
                Image(systemName: "heart.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
                
                Text("\(gameState.teamLives)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
        )
    }
}

// MARK: - Extensions
extension Color {
    init?(hex: String) {
        let r, g, b, a: Double
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = Double((hexNumber & 0xff000000) >> 24) / 255
                    g = Double((hexNumber & 0x00ff0000) >> 16) / 255
                    b = Double((hexNumber & 0x0000ff00) >> 8) / 255
                    a = Double(hexNumber & 0x000000ff) / 255
                    
                    self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
                    return
                }
            } else if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = Double((hexNumber & 0xff0000) >> 16) / 255
                    g = Double((hexNumber & 0x00ff00) >> 8) / 255
                    b = Double(hexNumber & 0x0000ff) / 255
                    
                    self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
                    return
                }
            }
        }
        
        return nil
    }
}

// MARK: - Preview
#Preview {
    let gameState = GameState()
    let players = NetworkPlayerFactory.createTestPlayers(count: 4)
    
    return VStack {
        MultiplayerHUDView(
            gameState: gameState,
            players: players,
            currentLevel: 3,
            missionClue: "Navigate through the space debris field and find all crew checkpoints before time runs out!"
        )
        
        Spacer()
        
        CompactMultiplayerHUDView(players: players, gameState: gameState)
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}
