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
            if let event = message.gameEvent {
                switch event.type {
                case .pause:
                    if let playerID = event.playerID {
                        GameManager.shared.pauseGame(by: playerID)
                    }
                case .resumeRequest:
                    if let playerID = event.playerID {
                        GameManager.shared.resumeGameWithCountdown(by: playerID)
                    }
                case .playerDeath:
                    if let lives = event.section {
                        GameManager.shared.setTeamLives(lives)
                    }
                default:
                    GameManager.shared.handleGameEvent(event)
                }
            }
        case .cameraMoved:
            if let event = message.gameEvent, let camPos = event.cameraPosition {
                GameManager.shared.cameraPosition = camPos
                // Or directly update scene camera if possible
                if let skView = UIApplication.shared.windows.first?.rootViewController?.view as? SKView,
                   let scene = skView.scene as? GameScene {
                    scene.centerCamera(on: camPos)
                }
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
    
    func broadcastPause(by playerID: String) {
        let event = GameEvent(type: .pause, playerID: playerID)
        broadcastGameEvent(event)
    }
    
    func broadcastResumeRequest(by playerID: String) {
        let event = GameEvent(type: .resumeRequest, playerID: playerID)
        broadcastGameEvent(event)
    }
    
    func broadcastAllPlayerUpdates(_ players: [NetworkPlayer]) {
        for player in players {
            broadcastPlayerUpdate(player)
        }
    }
    
    // Broadcast camera position to all peers
    func broadcastCameraPosition(_ position: CGPoint) {
        let event = GameEvent(type: .cameraMoved, cameraPosition: position)
        broadcastGameEvent(event)
    }

    // Broadcast team lives after a death
    func broadcastTeamLives(_ lives: Int) {
        let event = GameEvent(type: .playerDeath, section: lives)
        broadcastGameEvent(event)
    }
}
