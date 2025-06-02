//
//  Room.swift
//  Space Maze
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import Foundation

/// Represents a multiplayer room (for lobby UI and sync) - Fixed to use PlayerState for Codable
struct Room: Codable, Identifiable {
    let id: String
    var code: String
    var players: [PlayerState]  // Changed from [NetworkPlayer] to [PlayerState]
    var isOpen: Bool
    
    init(id: String = UUID().uuidString, code: String, players: [PlayerState] = [], isOpen: Bool = true) {
        self.id = id
        self.code = code
        self.players = players
        self.isOpen = isOpen
    }
    
    /// Convenience initializer with NetworkPlayer array (converts to PlayerState)
    init(id: String = UUID().uuidString, code: String, networkPlayers: [NetworkPlayer] = [], isOpen: Bool = true) {
        self.id = id
        self.code = code
        self.players = networkPlayers.map { $0.toPlayerState() }
        self.isOpen = isOpen
    }
    
    /// Convert to NetworkPlayer array for UI usage
    func toNetworkPlayers() -> [NetworkPlayer] {
        return players.map { NetworkPlayer(from: $0) }
    }
}
