//
//  NetworkMessage.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation

/// Network message wrapper for sending/receiving between peers.
struct NetworkMessage: Codable {
    enum MessageType: String, Codable {
        case playerUpdate
        case gameEvent
    }
    
    let type: MessageType
    let playerUpdate: NetworkPlayer?
    let gameEvent: GameEvent?
}
