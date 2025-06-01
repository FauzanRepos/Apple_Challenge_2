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

/// Represents a player in the multiplayer network (syncs between devices)
final class NetworkPlayer: ObservableObject, Identifiable, Codable {
    let id: String
    let peerID: String
    @Published var colorIndex: Int
    @Published var position: CGPoint
    @Published var velocity: CGVector
    @Published var lives: Int
    @Published var score: Int
    @Published var isReady: Bool
    @Published var lastSeen: Date
    
    // MapMover/edge role logic
    @Published var assignedEdge: EdgeRole?
    var isMapMover: Bool { assignedEdge != nil }
    
    enum CodingKeys: String, CodingKey {
        case id, peerID, colorIndex, position, velocity, lives, score, isReady, assignedEdge, lastSeen
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
    
    // Codable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        peerID = try container.decode(String.self, forKey: .peerID)
        colorIndex = try container.decode(Int.self, forKey: .colorIndex)
        position = try container.decode(CGPoint.self, forKey: .position)
        velocity = try container.decode(CGVector.self, forKey: .velocity)
        lives = try container.decode(Int.self, forKey: .lives)
        score = try container.decode(Int.self, forKey: .score)
        isReady = try container.decode(Bool.self, forKey: .isReady)
        assignedEdge = try container.decodeIfPresent(EdgeRole.self, forKey: .assignedEdge)
        lastSeen = try container.decode(Date.self, forKey: .lastSeen)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(peerID, forKey: .peerID)
        try container.encode(colorIndex, forKey: .colorIndex)
        try container.encode(position, forKey: .position)
        try container.encode(velocity, forKey: .velocity)
        try container.encode(lives, forKey: .lives)
        try container.encode(score, forKey: .score)
        try container.encode(isReady, forKey: .isReady)
        try container.encodeIfPresent(assignedEdge, forKey: .assignedEdge)
        try container.encode(lastSeen, forKey: .lastSeen)
    }
}

/// Factory for easy creation of NetworkPlayer
struct NetworkPlayerFactory {
    static func createLocalPlayer(name: String, colorIndex: Int = 0) -> NetworkPlayer {
        let peerID = UIDevice.current.name
        return NetworkPlayer(id: UUID().uuidString, peerID: peerID, colorIndex: colorIndex)
    }
}
