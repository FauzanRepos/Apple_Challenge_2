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
    
    private init() {}
    
    // MARK: - Incoming Data Handler
    func handleIncomingData(_ data: Data, from peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(MultiplayerMessage.self, from: data) else {
            print("[PlayerSyncManager] Failed to decode message from \(peerID.displayName)")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.processMessage(message, from: peerID)
        }
    }
    
    private func processMessage(_ message: MultiplayerMessage, from peerID: MCPeerID) {
        switch message.type {
        case .playerUpdate:
            handlePlayerUpdate(message)
            
        case .gameEvent:
            handleGameEvent(message)
            
        case .playerListUpdate:
            handlePlayerListUpdate(message)
            
        case .teamLivesUpdate:
            handleTeamLivesUpdate(message)
            
        case .cameraUpdate:
            handleCameraUpdate(message)
        }
    }
    
    private func handlePlayerUpdate(_ message: MultiplayerMessage) {
        guard let playerState = message.playerState else { return }
        
        // Find and update the corresponding NetworkPlayer
        if let playerIndex = MultipeerManager.shared.players.firstIndex(where: { $0.id == playerState.id }) {
            MultipeerManager.shared.players[playerIndex].update(from: playerState)
        } else {
            // Player not found, add them
            let newPlayer = NetworkPlayer(from: playerState)
            MultipeerManager.shared.players.append(newPlayer)
        }
    }
    
    private func handleGameEvent(_ message: MultiplayerMessage) {
        guard let event = message.gameEvent else { return }
        
        switch event.type {
        case .pause:
            if let playerID = event.playerID {
                GameManager.shared.pauseGame(by: playerID)
            }
            
        case .resumeRequest:
            if let playerID = event.playerID {
                GameManager.shared.resumeGameWithCountdown(by: playerID)
            }
            
        case .cameraMoved:
            if let camPos = event.cameraPosition {
                GameManager.shared.setCameraPosition(camPos)
            }
            
        default:
            GameManager.shared.handleGameEvent(event)
        }
    }
    
    private func handlePlayerListUpdate(_ message: MultiplayerMessage) {
        guard let playerList = message.playerList else { return }
        
        // Update entire player list
        MultipeerManager.shared.players = playerList.map { NetworkPlayer(from: $0) }
    }
    
    private func handleTeamLivesUpdate(_ message: MultiplayerMessage) {
        guard let lives = message.teamLives else { return }
        GameManager.shared.setTeamLives(lives)
    }
    
    private func handleCameraUpdate(_ message: MultiplayerMessage) {
        guard let position = message.cameraPosition else { return }
        GameManager.shared.setCameraPosition(position)
    }
    
    // MARK: - Outgoing Sync
    func broadcastPlayerUpdate(_ player: NetworkPlayer) {
        let playerState = player.toPlayerState()
        let message = MultiplayerMessage(
            type: .playerUpdate,
            senderID: MultipeerManager.shared.localPeerID.displayName,
            playerState: playerState
        )
        sendMessage(message)
    }
    
    func broadcastGameEvent(_ event: GameEvent) {
        let message = MultiplayerMessage(
            type: .gameEvent,
            senderID: MultipeerManager.shared.localPeerID.displayName,
            gameEvent: event
        )
        sendMessage(message)
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
        let playerStates = players.map { $0.toPlayerState() }
        let message = MultiplayerMessage(
            type: .playerListUpdate,
            senderID: MultipeerManager.shared.localPeerID.displayName,
            playerList: playerStates
        )
        sendMessage(message)
    }
    
    func broadcastCameraPosition(_ position: CGPoint) {
        let message = MultiplayerMessage(
            type: .cameraUpdate,
            senderID: MultipeerManager.shared.localPeerID.displayName,
            cameraPosition: position
        )
        sendMessage(message)
    }
    
    func broadcastTeamLives(_ lives: Int) {
        let message = MultiplayerMessage(
            type: .teamLivesUpdate,
            senderID: MultipeerManager.shared.localPeerID.displayName,
            teamLives: lives
        )
        sendMessage(message)
    }
    
    // MARK: - Message Sending
    private func sendMessage(_ message: MultiplayerMessage) {
        guard let data = try? JSONEncoder().encode(message) else {
            print("[PlayerSyncManager] Failed to encode message")
            return
        }
        
        MultipeerManager.shared.sendToAll(data)
    }
}
