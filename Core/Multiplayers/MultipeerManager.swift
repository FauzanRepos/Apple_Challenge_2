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

/// Manages peer-to-peer networking for multiplayer using MultipeerConnectivity
final class MultipeerManager: NSObject, ObservableObject {
    static let shared = MultipeerManager()
    
    // MARK: - Published Peer State
    @Published var players: [NetworkPlayer] = []
    @Published var isHost: Bool = false
    @Published var sessionCode: String = ""
    @Published var connected: Bool = false
    @Published var localPeerID: MCPeerID!
    @Published var session: MCSession!
    @Published var advertiser: MCNearbyServiceAdvertiser?
    @Published var browser: MCNearbyServiceBrowser?
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var isReady: Bool = false
    @Published var state: MultipeerState = .idle
    
    private let serviceType = "space-maze"
    private let displayName = UIDevice.current.name
    private var cancelBag = Set<AnyCancellable>()
    
    // MARK: - Init
    private override init() {
        super.init()
        localPeerID = MCPeerID(displayName: displayName)
        session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }
    
    // MARK: - Host Game
    func hostGame(sessionCode: String) {
        self.sessionCode = sessionCode
        isHost = true
        
        // Create local player with color index 0 (host is always first)
        let localPlayer = NetworkPlayerFactory.createLocalPlayer(name: displayName, colorIndex: 0)
        players = [localPlayer]
        
        state = .hosting
        advertiser = MCNearbyServiceAdvertiser(
            peer: localPeerID,
            discoveryInfo: ["code": sessionCode],
            serviceType: serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        print("[MultipeerManager] Hosting game with code: \(sessionCode)")
    }
    
    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        state = .idle
        isHost = false
        clearPlayers()
        
        print("[MultipeerManager] Stopped hosting")
    }
    
    // MARK: - Join Game
    func joinGame(sessionCode: String) {
        self.sessionCode = sessionCode
        isHost = false
        
        // Create local player (color will be assigned by host)
        let localPlayer = NetworkPlayerFactory.createLocalPlayer(name: displayName)
        players = [localPlayer]
        
        state = .browsing
        browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        print("[MultipeerManager] Joining game with code: \(sessionCode)")
    }
    
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        state = .idle
        clearPlayers()
        
        print("[MultipeerManager] Stopped browsing")
    }
    
    // MARK: - Player Management
    private func clearPlayers() {
        players.removeAll()
    }
    
    func addPlayer(_ peerID: MCPeerID) {
        // Assign next available color index
        let colorIndex = players.count % Constants.playerColors.count
        let newPlayer = NetworkPlayer(
            id: UUID().uuidString,
            peerID: peerID.displayName,
            colorIndex: colorIndex
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.players.append(newPlayer)
            print("[MultipeerManager] Added player: \(peerID.displayName) (color: \(colorIndex))")
        }
    }
    
    func removePlayer(with peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.players.removeAll { $0.peerID == peerID.displayName }
            print("[MultipeerManager] Removed player: \(peerID.displayName)")
        }
    }
    
    // MARK: - Send Data
    func sendToAll(_ data: Data) {
        guard !session.connectedPeers.isEmpty else {
            print("[MultipeerManager] No connected peers to send data to")
            return
        }
        
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("[MultipeerManager] Failed to send data: \(error)")
        }
    }
    
    func sendToPeer(_ data: Data, peer: MCPeerID) {
        do {
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print("[MultipeerManager] Failed to send data to \(peer.displayName): \(error)")
        }
    }
    
    // MARK: - Connection Status
    private func updateConnectionStatus() {
        let wasConnected = connected
        connected = !session.connectedPeers.isEmpty
        
        if connected != wasConnected {
            print("[MultipeerManager] Connection status changed: \(connected)")
        }
    }
    
    // MARK: - Disconnect
    func disconnect() {
        session.disconnect()
        stopHosting()
        stopBrowsing()
        state = .idle
        clearPlayers()
        connected = false
        
        print("[MultipeerManager] Disconnected from session")
    }
}

// MARK: - MCSessionDelegate
extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch state {
            case .connecting:
                print("[MultipeerManager] Connecting to: \(peerID.displayName)")
                
            case .connected:
                print("[MultipeerManager] Connected to: \(peerID.displayName)")
                self.addPlayer(peerID)
                self.updateConnectionStatus()
                
            case .notConnected:
                print("[MultipeerManager] Disconnected from: \(peerID.displayName)")
                self.removePlayer(with: peerID)
                self.updateConnectionStatus()
                
                // Pause game if someone disconnects during gameplay
                if GameManager.shared.currentLevel > 0 {
                    PlayerSyncManager.shared.broadcastPause(by: self.localPeerID.displayName)
                }
                
            @unknown default:
                print("[MultipeerManager] Unknown session state: \(state)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        PlayerSyncManager.shared.handleIncomingData(data, from: peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not implemented for this game
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not implemented for this game
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not implemented for this game
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        // Accept all certificates for local network gaming
        certificateHandler(true)
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("[MultipeerManager] Failed to start advertising: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("[MultipeerManager] Received invitation from: \(peerID.displayName)")
        
        // Auto-accept invitations when hosting
        if isHost && players.count < Constants.maxPlayers {
            invitationHandler(true, session)
        } else {
            invitationHandler(false, nil)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("[MultipeerManager] Failed to start browsing: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("[MultipeerManager] Found peer: \(peerID.displayName)")
        
        // Check if this peer has the correct session code
        if let code = info?["code"], code == self.sessionCode {
            print("[MultipeerManager] Session code matches, inviting peer")
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("[MultipeerManager] Lost peer: \(peerID.displayName)")
    }
}

/// Multiplayer state for UI
enum MultipeerState {
    case idle
    case hosting
    case browsing
}
