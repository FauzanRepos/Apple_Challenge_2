//
//  RoomModel.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import Foundation

/// Represents a multiplayer room (for lobby UI and sync)
struct Room: Codable, Identifiable {
    let id: String
    var code: String
    var players: [NetworkPlayer]
    var isOpen: Bool
    
    init(id: String = UUID().uuidString, code: String, players: [NetworkPlayer] = [], isOpen: Bool = true) {
        self.id = id
        self.code = code
        self.players = players
        self.isOpen = isOpen
    }
}
