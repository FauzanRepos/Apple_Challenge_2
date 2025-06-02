//
//  MultiplayerMessage.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation

/// Network message wrapper for sending/receiving between peers
struct MultiplayerMessage: Codable {
    enum MessageType: String, Codable {
        case playerUpdate
        case gameEvent
        case playerListUpdate
        case teamLivesUpdate
        case cameraUpdate
    }
    
    let type: MessageType
    let timestamp: Date
    let senderID: String
    
    // Message payloads (only one should be non-nil per message)
    let playerState: PlayerState?
    let gameEvent: GameEvent?
    let playerList: [PlayerState]?
    let teamLives: Int?
    let cameraPosition: CGPoint?
    
    init(type: MessageType, senderID: String, playerState: PlayerState? = nil, gameEvent: GameEvent? = nil, playerList: [PlayerState]? = nil, teamLives: Int? = nil, cameraPosition: CGPoint? = nil) {
        self.type = type
        self.timestamp = Date()
        self.senderID = senderID
        self.playerState = playerState
        self.gameEvent = gameEvent
        self.playerList = playerList
        self.teamLives = teamLives
        self.cameraPosition = cameraPosition
    }
}
