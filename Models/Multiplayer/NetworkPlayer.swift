//
//  NetworkPlayer.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CoreGraphics
import Combine

/// Represents a player in the multiplayer network - UI observable but not directly Codable
final class NetworkPlayer: ObservableObject, Identifiable {
    let id: String
    let peerID: String
    
    @Published var colorIndex: Int
    @Published var position: CGPoint
    @Published var velocity: CGVector
    @Published var lives: Int
    @Published var score: Int
    @Published var isReady: Bool
    @Published var lastSeen: Date
    @Published var assignedEdge: EdgeRole?
    
    var isMapMover: Bool {
        assignedEdge != nil
    }
    
    init(id: String, peerID: String, colorIndex: Int, position: CGPoint = .zero, velocity: CGVector = .zero, lives: Int = Constants.defaultPlayerLives, score: Int = 0, isReady: Bool = false, assignedEdge: EdgeRole? = nil) {
        self.id = id
        self.peerID = peerID
        self.colorIndex = colorIndex
        self.position = position
        self.velocity = velocity
        self.lives = lives
        self.score = score
        self.isReady = isReady
        self.assignedEdge = assignedEdge
        self.lastSeen = Date()
    }
    
    /// Create from PlayerState
    convenience init(from playerState: PlayerState) {
        self.init(
            id: playerState.id,
            peerID: playerState.peerID,
            colorIndex: playerState.colorIndex,
            position: playerState.position,
            velocity: playerState.velocity,
            lives: playerState.lives,
            score: playerState.score,
            isReady: playerState.isReady,
            assignedEdge: playerState.assignedEdge
        )
        self.lastSeen = playerState.lastSeen
    }
    
    /// Convert to PlayerState for network transmission
    func toPlayerState() -> PlayerState {
        return PlayerState(from: self)
    }
    
    /// Update from received PlayerState
    func update(from playerState: PlayerState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.colorIndex = playerState.colorIndex
            self.position = playerState.position
            self.velocity = playerState.velocity
            self.lives = playerState.lives
            self.score = playerState.score
            self.isReady = playerState.isReady
            self.assignedEdge = playerState.assignedEdge
            self.lastSeen = playerState.lastSeen
        }
    }
}

/// Factory for easy creation of NetworkPlayer
struct NetworkPlayerFactory {
    static func createLocalPlayer(name: String, colorIndex: Int = 0) -> NetworkPlayer {
        let peerID = UIDevice.current.name
        return NetworkPlayer(id: UUID().uuidString, peerID: peerID, colorIndex: colorIndex)
    }
}
