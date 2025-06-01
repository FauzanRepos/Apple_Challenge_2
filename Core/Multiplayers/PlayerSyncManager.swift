//
//  PlayerSyncManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import MultipeerConnectivity

/// Handles all player/game state sync via MultipeerConnectivity
final class PlayerSyncManager {
    static let shared = PlayerSyncManager()
    
    // MARK: - Incoming Data Handler
    func handleIncomingData(_ data: Data, from peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(NetworkMessage.self, from: data) else { return }
        switch message.type {
        case .playerUpdate:
            if let update = message.playerUpdate {
                MultipeerManager.shared.players = MultipeerManager.shared.players.map { player in
                    if player.id == update.id {
                        player.position = update.position
                        player.velocity = update.velocity
                        player.lives = update.lives
                        player.score = update.score
                        player.isReady = update.isReady
                        player.lastSeen = Date()
                    }
                    return player
                }
            }
        case .gameEvent:
            // Broadcast game events (death, checkpoint, mission, etc)
            if let event = message.gameEvent {
                GameManager.shared.handleGameEvent(event)
            }
        }
    }
    
    // MARK: - Outgoing Sync
    func broadcastPlayerUpdate(_ player: NetworkPlayer) {
        let message = NetworkMessage(type: .playerUpdate, playerUpdate: player, gameEvent: nil)
        guard let data = try? JSONEncoder().encode(message) else { return }
        MultipeerManager.shared.sendToAll(data)
    }
    
    func broadcastGameEvent(_ event: GameEvent) {
        let message = NetworkMessage(type: .gameEvent, playerUpdate: nil, gameEvent: event)
        guard let data = try? JSONEncoder().encode(message) else { return }
        MultipeerManager.shared.sendToAll(data)
    }
}
