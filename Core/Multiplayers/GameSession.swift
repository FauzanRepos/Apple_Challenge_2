//
//  GameSession.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import MultipeerConnectivity

/// Represents a running multiplayer game session.
final class GameSession: ObservableObject {
    static let shared = GameSession()
    
    @Published var sessionID: String = UUID().uuidString
    @Published var hostPeerID: MCPeerID?
    @Published var players: [NetworkPlayer] = []
    @Published var isActive: Bool = false
    @Published var startedAt: Date? = nil
    
    private init() {}
    
    func startSession(with host: MCPeerID, players: [NetworkPlayer]) {
        self.sessionID = UUID().uuidString
        self.hostPeerID = host
        self.players = players
        self.isActive = true
        self.startedAt = Date()
    }
    
    func endSession() {
        self.isActive = false
        self.players.removeAll()
        self.sessionID = UUID().uuidString
        self.hostPeerID = nil
        self.startedAt = nil
    }
}
