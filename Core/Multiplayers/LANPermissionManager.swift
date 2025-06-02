//
//  NetService.swift
//  Space Maze
//
//  Created by WESLY CHAU LI ZHAN on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import SwiftUI

/// Handles LAN (local network) permission prompt required for MultipeerConnectivity
final class LANPermissionManager: NSObject, ObservableObject, MCNearbyServiceAdvertiserDelegate {
    static let shared = LANPermissionManager()
    
    private var peerID: MCPeerID!
    private var advertiser: MCNearbyServiceAdvertiser?
    @Published var isAdvertising = false
    @Published var hasPermission = false
    
    var onPermissionStatusChanged: ((Bool) -> Void)?
    
    override init() {
        super.init()
        setupPeerID()
    }
    
    private func setupPeerID() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "spacemaze")
        advertiser?.delegate = self
    }
    
    func triggerPermissionPrompt() {
        isAdvertising = true
        if advertiser == nil { setupPeerID() }
        advertiser?.startAdvertisingPeer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.advertiser?.stopAdvertisingPeer()
            self?.isAdvertising = false
        }
    }
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        hasPermission = true
        onPermissionStatusChanged?(true)
        invitationHandler(false, nil)
    }
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        isAdvertising = false
        if (error as NSError).domain == "NSNetServicesErrorDomain" {
            hasPermission = false
            onPermissionStatusChanged?(false)
        }
    }
}
