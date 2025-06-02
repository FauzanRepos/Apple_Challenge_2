//
//  LobbyView.swift
//  Space Maze
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var multipeerManager: MultipeerManager
    @EnvironmentObject var gameManager: GameManager
    
    @Environment(\.presentationMode) var presentationMode
    @State private var isLocalPlayerReady: Bool = false
    
    private var localPlayer: NetworkPlayer? {
        multipeerManager.players.first { $0.peerID == multipeerManager.localPeerID.displayName }
    }
    
    private var allPlayersReady: Bool {
        let nonHostPlayers = multipeerManager.players.filter { !multipeerManager.isHost || $0.peerID != multipeerManager.localPeerID.displayName }
        return nonHostPlayers.allSatisfy { $0.isReady } && nonHostPlayers.count > 0
    }
    
    var body: some View {
        VStack(spacing: 18) {
            // Close button
            HStack {
                Spacer()
                Button(action: {
                    multipeerManager.disconnect()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title)
                        .padding()
                }
            }
            
            // Ship code display
            VStack(spacing: 8) {
                Text("Ship Code")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text(multipeerManager.sessionCode)
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
            }
            .padding(.top, 16)
            
            // Player list
            PlayerListView()
                .environmentObject(multipeerManager)
            
            Spacer()
            
            // Host controls
            if multipeerManager.isHost {
                VStack(spacing: 16) {
                    if multipeerManager.players.count >= Constants.minPlayers {
                        if allPlayersReady {
                            StartGameSliderView(onSlide: {
                                gameManager.startGame()
                            })
                        } else {
                            Text("Waiting for all players to be ready...")
                                .foregroundColor(.orange)
                                .font(.headline)
                        }
                    } else {
                        Text("Need at least \(Constants.minPlayers) players to start")
                            .foregroundColor(.red)
                            .font(.headline)
                    }
                }
                .padding(.top, 30)
            } else {
                // Non-host player controls
                VStack(spacing: 16) {
                    ReadyButtonView(
                        isReady: $isLocalPlayerReady,
                        onReady: {
                            updateLocalPlayerReadyStatus()
                        }
                    )
                    
                    if isLocalPlayerReady {
                        Text("Waiting for host to start the game...")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    } else {
                        Text("Tap ready when you're prepared to play!")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                }
                .padding(.top, 20)
            }
            
            Spacer()
        }
        .background(
            Image("background")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
        )
        .onAppear {
            // Initialize local player ready status
            if let player = localPlayer {
                isLocalPlayerReady = player.isReady
            }
        }
        .onDisappear {
            // Clean up if view is dismissed
            multipeerManager.stopHosting()
            multipeerManager.stopBrowsing()
        }
    }
    
    // MARK: - Helper Methods
    private func updateLocalPlayerReadyStatus() {
        guard let localPlayer = localPlayer else { return }
        
        // Update local state
        localPlayer.isReady = isLocalPlayerReady
        
        // Broadcast the update to all players
        PlayerSyncManager.shared.broadcastPlayerUpdate(localPlayer)
        
        print("[LobbyView] Local player ready status: \(isLocalPlayerReady)")
    }
}
