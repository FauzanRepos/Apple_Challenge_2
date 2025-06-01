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
        players = [NetworkPlayerFactory.createLocalPlayer(name: displayName)]
        state = .hosting
        advertiser = MCNearbyServiceAdvertiser(peer: localPeerID, discoveryInfo: ["code": sessionCode], serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }
    
    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        state = .idle
        isHost = false
        players.removeAll()
    }
    
    // MARK: - Join Game
    func joinGame(sessionCode: String) {
        self.sessionCode = sessionCode
        isHost = false
        players = [NetworkPlayerFactory.createLocalPlayer(name: displayName)]
        state = .browsing
        browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        state = .idle
        players.removeAll()
    }
    
    // MARK: - Send Data (sync, state, moves, etc)
    func sendToAll(_ data: Data) {
        if session.connectedPeers.count > 0 {
            try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        }
    }
    
    // MARK: - Disconnect
    func disconnect() {
        session.disconnect()
        stopHosting()
        stopBrowsing()
        state = .idle
        players.removeAll()
    }
}

// MARK: - MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate
extension MultipeerManager: MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    // Implement all required delegate methods
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connected = (state == .connected)
            if state == .notConnected {
                // Pause game for all players
                PlayerSyncManager.shared.broadcastPause(by: self.localPeerID.displayName)
            }
        }
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Pass to PlayerSyncManager or handle directly
        PlayerSyncManager.shared.handleIncomingData(data, from: peerID)
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) { certificateHandler(true) }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {}
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {}
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if let code = info?["code"], code == self.sessionCode {
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        }
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}

/// Multiplayer state for UI
enum MultipeerState {
    case idle
    case hosting
    case browsing
}
