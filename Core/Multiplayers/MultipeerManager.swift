//
//  MultipeerManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import Combine

class MultipeerManager: NSObject, ObservableObject {
    static let shared = MultipeerManager()
    
    // MARK: - Published Properties
    @Published var sessionState: StateS = .notConnected
    @Published var connectedPlayers: [NetworkPlayer] = []
    @Published var isHost: Bool = false
    @Published var gameCode: String = ""
    @Published var connectionError: String?
    
    // MARK: - MultipeerConnectivity Properties
    private let serviceType = "spacemaze-game"
    private var peerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    // MARK: - Game Properties
    private var localPlayer: NetworkPlayer
    private var gameSession: GameSession?
    
    // MARK: - Delegates
    weak var gameDelegate: MultipeerGameDelegate?
    
    private override init() {
        // Create peer ID with device name
        let deviceName = UIDevice.current.name
        self.peerID = MCPeerID(displayName: deviceName)
        
        // Create session
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        
        // Create local player
        self.localPlayer = NetworkPlayer(
            id: peerID.displayName,
            name: StorageManager.shared.getPlayerName(),
            peerID: peerID,
            isHost: false,
            isReady: false
        )
        
        super.init()
        
        session.delegate = self
    }
    
    // MARK: - Host Functions
    func createGame() -> String {
        print("🏠 Creating new game as host")
        
        // Generate unique game code
        gameCode = GameCodeManager.generateGameCode()
        isHost = true
        localPlayer.isHost = true
        
        // Add local player to connected players
        connectedPlayers = [localPlayer]
        
        // Start advertising
        startAdvertising()
        
        // Create game session
        gameSession = GameSession(
            gameCode: gameCode,
            hostPlayer: localPlayer,
            maxPlayers: Constants.maxPlayersPerRoom
        )
        
        sessionState = .hosting
        
        print("✅ Game created with code: \(gameCode)")
        return gameCode
    }
    
    private func startAdvertising() {
        stopAdvertising() // Stop any existing advertiser
        
        let discoveryInfo = [
            "gameCode": gameCode,
            "hostName": localPlayer.name,
            "playerCount": "\(connectedPlayers.count)",
            "maxPlayers": "\(Constants.maxPlayersPerRoom)"
        ]
        
        advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        print("📡 Started advertising game: \(gameCode)")
    }
    
    // MARK: - Client Functions
    func joinGame(with code: String, completion: @escaping (Bool, String?) -> Void) {
        print("🔍 Attempting to join game with code: \(code)")
        
        guard GameCodeManager.validateCode(code) else {
            completion(false, "Invalid game code format")
            return
        }
        
        gameCode = code
        isHost = false
        localPlayer.isHost = false
        sessionState = .searchingForGame
        
        // Start browsing for the game
        startBrowsing { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.sessionState = .connecting
                } else {
                    self?.sessionState = .notConnected
                }
                completion(success, error)
            }
        }
    }
    
    private func startBrowsing(completion: @escaping (Bool, String?) -> Void) {
        stopBrowsing() // Stop any existing browser
        
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        // Set timeout for finding the game
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            if self?.sessionState == .searchingForGame {
                self?.stopBrowsing()
                completion(false, "Game not found. Please check the code and try again.")
            }
        }
    }
    
    // MARK: - Session Management
    func setPlayerReady(_ isReady: Bool) {
        localPlayer.isReady = isReady
        
        // Update local player in the list
        if let index = connectedPlayers.firstIndex(where: { $0.id == localPlayer.id }) {
            connectedPlayers[index].isReady = isReady
        }
        
        // Send ready state to other players
        sendPlayerReadyState(isReady)
        
        print("✅ Player ready state: \(isReady)")
    }
    
    func startGame() {
        guard isHost else {
            print("❌ Only host can start the game")
            return
        }
        
        guard connectedPlayers.count >= 2 else {
            print("❌ Need at least 2 players to start")
            return
        }
        
        guard connectedPlayers.allSatisfy({ $0.isReady }) else {
            print("❌ All players must be ready")
            return
        }
        
        print("🚀 Starting multiplayer game")
        
        // Assign player types
        assignPlayerTypes()
        
        // Send game start message to all players
        sendGameStart()
        
        // Update session state
        sessionState = .gameInProgress
        
        // Notify delegate
        gameDelegate?.gameDidStart(with: connectedPlayers)
    }
    
    private func assignPlayerTypes() {
        let totalPlayers = connectedPlayers.count
        let mapMoverCount = max(1, totalPlayers / 3) // 1/3 of players can move map
        
        for (index, _) in connectedPlayers.enumerated() {
            if index < mapMoverCount {
                connectedPlayers[index].playerType = .mapMover
            } else {
                connectedPlayers[index].playerType = .regular
            }
        }
        
        print("🎮 Assigned player types: \(mapMoverCount) map movers, \(totalPlayers - mapMoverCount) regular players")
    }
    
    // MARK: - Message Sending
    func sendPlayerMovement(_ position: CGPoint, velocity: CGVector) {
        let message = MessageFactory.createPlayerMovementMessage(
            playerId: localPlayer.id,
            position: position,
            velocity: velocity
            // timestamp: Date().timeIntervalSince1970
        )
        sendMessage(message)
    }
    
    func sendCheckpointReached(_ checkpointId: String, playerId: String) {
        let message = MessageFactory.createCheckpointMessage(
            playerId: playerId,
            checkpointId: checkpointId
        )
        sendMessage(message)
    }
    
    func sendPlayerDied(_ playerId: String) {
        let message = MessageFactory.playerDied(playerId: playerId)
        sendMessage(message)
    }
    
    func sendGamePaused() {
        let message = MessageFactory.gamePaused
        sendMessage(message)
    }
    
    func sendGameResumed() {
        let message = MessageFactory.gameResumed
        sendMessage(message)
    }
    
    func sendGameEnded(reason: GameEndReason) {
        let message = MessageFactory.createGameEndMessage(reason: reason)
        sendMessage(message)
    }
    
    private func sendPlayerReadyState(_ isReady: Bool) {
        let message = MessageFactory.createPlayerJoinedMessage(
            playerId: localPlayer.id,
            isReady: isReady
        )
        sendMessage(message)
    }
    
    private func sendGameStart() {
        let message = MessageFactory.createGameStartMessage(players: connectedPlayers)
        sendMessage(message)
    }
    
    private func sendMessage(_ message: NetworkMessage) {
        guard !session.connectedPeers.isEmpty else { return }
        
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("❌ Failed to send message: \(error)")
        }
    }
    
    // MARK: - Message Handling
    private func handleReceivedMessage(_ message: NetworkMessage) {
        DispatchQueue.main.async { [weak self] in
            switch message {
            case .playerJoined(let player):
                self?.handlePlayerJoined(player)
                
            case .playerLeft(let playerId):
                self?.handlePlayerLeft(playerId)
                
            case .playerReady(let playerId, let isReady):
                self?.handlePlayerReadyStateChanged(playerId, isReady: isReady)
                
            case .gameStart(let players):
                self?.handleGameStart(players)
                
            case .playerMovement(let playerId, let position, let velocity, let timestamp):
                self?.gameDelegate?.playerDidMove(playerId: playerId, position: position, velocity: velocity, timestamp: timestamp)
                
            case .checkpointReached(let checkpointId, let playerId):
                self?.gameDelegate?.checkpointReached(checkpointId, by: playerId)
                
            case .playerDied(let playerId):
                self?.gameDelegate?.playerDied(playerId)
                
            case .gamePaused:
                self?.gameDelegate?.gameDidPause()
                
            case .gameResumed:
                self?.gameDelegate?.gameDidResume()
                
            case .gameEnded(let reason):
                self?.gameDelegate?.gameDidEnd(reason: reason)
                
            default:
                print("⚠️ Unhandled message type: \(message.type)")
            }
        }
    }
    
    private func handlePlayerJoined(_ player: NetworkPlayer) {
        print("👋 Player joined: \(player.name)")
        
        if !connectedPlayers.contains(where: { $0.id == player.id }) {
            connectedPlayers.append(player)
        }
        
        // If we're the host, send current game state to new player
        if isHost {
            sendCurrentGameStateToPlayer(player)
        }
    }
    
    private func handlePlayerLeft(_ playerId: String) {
        print("👋 Player left: \(playerId)")
        
        connectedPlayers.removeAll { $0.id == playerId }
        
        // If host left and we're not the host, handle disconnection
        if !isHost && connectedPlayers.first(where: { $0.isHost })?.id == playerId {
            handleHostDisconnected()
        }
    }
    
    private func handlePlayerReadyStateChanged(_ playerId: String, isReady: Bool) {
        if let index = connectedPlayers.firstIndex(where: { $0.id == playerId }) {
            connectedPlayers[index].isReady = isReady
            print("✅ Player \(playerId) ready state: \(isReady)")
        }
    }
    
    private func handleGameStart(_ players: [NetworkPlayer]) {
        print("🚀 Game started with \(players.count) players")
        connectedPlayers = players
        sessionState = .gameInProgress
        gameDelegate?.gameDidStart(with: players)
    }
    
    private func sendCurrentGameStateToPlayer(_ player: NetworkPlayer) {
        // Send current player list
        let message = MessageFactory.createPlayerJoinedMessage(player: localPlayer)
        sendMessage(message)
    }
    
    private func handleHostDisconnected() {
        print("❌ Host disconnected")
        sessionState = .notConnected
        connectionError = "Host disconnected from the game"
        disconnect()
    }
    
    // MARK: - Connection Management
    func disconnect() {
        print("🔌 Disconnecting from multiplayer session")
        
        stopAdvertising()
        stopBrowsing()
        session.disconnect()
        
        // Reset state
        connectedPlayers.removeAll()
        gameCode = ""
        isHost = false
        localPlayer.isHost = false
        localPlayer.isReady = false
        sessionState = .notConnected
        gameSession = nil
    }
    
    private func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
    }
    
    private func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
    }
    
    // MARK: - App Lifecycle
    func handleAppDidEnterBackground() {
        // Pause the session but don't disconnect
        if sessionState == .gameInProgress {
            sendGamePaused()
        }
    }
    
    func handleAppWillEnterForeground() {
        // Resume the session if it was paused
        if sessionState == .gameInProgress {
            sendGameResumed()
        }
    }
    
    // MARK: - Utility
    func isConnected() -> Bool {
        return sessionState == .connected || sessionState == .gameInProgress
    }
    
    func getLocalPlayer() -> NetworkPlayer {
        return localPlayer
    }
    
    func updateLocalPlayerName(_ name: String) {
        localPlayer.name = name
        
        // Update in connected players list
        if let index = connectedPlayers.firstIndex(where: { $0.id == localPlayer.id }) {
            connectedPlayers[index].name = name
        }
    }
}

// MARK: - MCSessionDelegate
extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch state {
            case .connected:
                print("✅ Connected to peer: \(peerID.displayName)")
                
                if !self.isHost {
                    self.sessionState = .connected
                    
                    // Send join message to host
                    let message = MessageFactory.createPlayerJoinedMessage(player: self.localPlayer)
                    self.sendMessage(message)
                }
                
            case .connecting:
                print("🔄 Connecting to peer: \(peerID.displayName)")
                
            case .notConnected:
                print("❌ Disconnected from peer: \(peerID.displayName)")
                
                // Remove player from connected list
                self.connectedPlayers.removeAll { $0.peerID == peerID }
                
                // Handle disconnection
                if self.connectedPlayers.isEmpty && !self.isHost {
                    self.sessionState = .notConnected
                }
                
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(NetworkMessage.self, from: data)
            handleReceivedMessage(message)
        } catch {
            print("❌ Failed to decode received message: \(error)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used in this implementation
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used in this implementation
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used in this implementation
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        print("📨 Received invitation from: \(peerID.displayName)")
        
        // Check if we have room for more players
        if connectedPlayers.count < Constants.maxPlayersPerRoom {
            invitationHandler(true, session)
        } else {
            print("❌ Game is full, rejecting invitation")
            invitationHandler(false, nil)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        print("🔍 Found peer: \(peerID.displayName)")
        
        // Check if this is the game we're looking for
        guard let discoveredCode = info?["gameCode"],
              discoveredCode == gameCode else {
            print("❌ Game code doesn't match: \(info?["gameCode"] ?? "nil") != \(gameCode)")
            return
        }
        
        print("✅ Found matching game, sending invitation")
        
        // Send invitation to join
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        
        // Stop browsing once we found the game
        stopBrowsing()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("❌ Lost peer: \(peerID.displayName)")
    }
}

// MARK: - Delegate Protocol
protocol MultipeerGameDelegate: AnyObject {
    func gameDidStart(with players: [NetworkPlayer])
    func gameDidEnd(reason: GameEndReason)
    func gameDidPause()
    func gameDidResume()
    func playerDidMove(playerId: String, position: CGPoint, velocity: CGVector, timestamp: TimeInterval)
    func checkpointReached(_ checkpointId: String, by playerId: String)
    func playerDied(_ playerId: String)
}
