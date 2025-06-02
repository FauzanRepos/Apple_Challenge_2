//
//  PlayerState.swift
//  Space Maze
//
//  Created by Apple Dev on 01/06/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import UIKit
import Foundation
import CoreGraphics

/// Sync-safe player model for network transmission (no @Published properties)
struct PlayerState: Codable, Identifiable, Equatable {
    let id: String
    let peerID: String
    var colorIndex: Int
    var position: CGPoint
    var velocity: CGVector
    var lives: Int
    var score: Int
    var isReady: Bool
    var assignedEdge: EdgeRole?
    var lastSeen: Date
    
    var isMapMover: Bool {
        assignedEdge != nil
    }
    
    init(id: String, peerID: String, colorIndex: Int, position: CGPoint = .zero, velocity: CGVector = .zero, lives: Int = Constants.defaultPlayerLives, score: Int = 0, isReady: Bool = false, assignedEdge: EdgeRole? = nil, lastSeen: Date = Date()) {
        self.id = id
        self.peerID = peerID
        self.colorIndex = colorIndex
        self.position = position
        self.velocity = velocity
        self.lives = lives
        self.score = score
        self.isReady = isReady
        self.assignedEdge = assignedEdge
        self.lastSeen = lastSeen
    }
    
    /// Create from NetworkPlayer
    init(from networkPlayer: NetworkPlayer) {
        self.id = networkPlayer.id
        self.peerID = networkPlayer.peerID
        self.colorIndex = networkPlayer.colorIndex
        self.position = networkPlayer.position
        self.velocity = networkPlayer.velocity
        self.lives = networkPlayer.lives
        self.score = networkPlayer.score
        self.isReady = networkPlayer.isReady
        self.assignedEdge = networkPlayer.assignedEdge
        self.lastSeen = networkPlayer.lastSeen
    }
}

/// Factory for PlayerState creation
struct PlayerStateFactory {
    static func createLocalPlayerState(name: String, colorIndex: Int = 0) -> PlayerState {
        let peerID = UIDevice.current.name
        return PlayerState(
            id: UUID().uuidString,
            peerID: peerID,
            colorIndex: colorIndex
        )
    }
}
