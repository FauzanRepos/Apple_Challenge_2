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
    
    @Environment(\.dismiss) private var dismiss
    @State private var isLocalPlayerReady: Bool = false
    @State private var showAbout = false
    @State private var navigateToGame = false
    
    private var localPlayer: NetworkPlayer? {
        multipeerManager.players.first { $0.peerID == multipeerManager.localPeerID.displayName }
    }
    
    private var allPlayersReady: Bool {
        let nonHostPlayers = multipeerManager.players.filter { !multipeerManager.isHost || $0.peerID != multipeerManager.localPeerID.displayName }
        return nonHostPlayers.allSatisfy { $0.isReady } && nonHostPlayers.count > 0
    }
    
    var body: some View {
        VStack {
            ZStack {
                
                Color("spaceMazeBG")
                    .ignoresSafeArea()
                
                Image("LobbyPage")
                    .resizable()
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 18) {
                    ZStack {
                        HStack {
                            Button(action: {
                                multipeerManager.disconnect()
                                dismiss()
                            }) {
                                Image("Back_Button")
                                    .resizable()
                                    .frame(width: 40, height: 32)
                            }
                            .padding(.top, UIScreen.main.bounds.height * 0.085)
                            .padding(.leading, 16)
                            
                            Spacer()
                        }
                        
                        Text("Space Maze")
                            .font(.custom("VCROSDMono", size: 36))
                            .foregroundColor(Color("text"))
                            .padding(.top, UIScreen.main.bounds.height * 0.075)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Ship code display
                    VStack(spacing: 8) {
                        Text("Ship Code")
                            .font(.custom("VCROSDMono", size: 32))
                            .foregroundStyle(Color("text"))
                            .multilineTextAlignment(.center)
                        
                        Text(multipeerManager.sessionCode)
                            .font(.custom("VCROSDMono", size: 32))
                            .foregroundStyle(Color("text"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                            .tracking(16)
                            .multilineTextAlignment(.center)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color("text").opacity(0.5), lineWidth: 2)
                            )
                        
                        Text("Share this code with\nfellow space crew")
                            .font(.custom("VCROSDMono", size: 16))
                            .foregroundStyle(Color("text"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 56)
                    
                    PlayerListView()
                        .environmentObject(multipeerManager)
                    
                    Spacer(minLength: UIScreen.main.bounds.height * 0.0235)
                    
                    ZStack(alignment: .top) {
                        Image("Assistant")
                            .resizable()
                            .frame(width: UIScreen.main.bounds.width * 0.8, height: 120)
                        
                        Text("Get ready and wait for\nyour commander to start\nthe game")
                            .font(.custom("VCROSDMono", size: 14))
                            .foregroundStyle(Color("text"))
                            .frame(width: UIScreen.main.bounds.width * 0.8, alignment: .leading)
                            .padding(.leading, UIScreen.main.bounds.width * 0.53)
                            .padding(.top, UIScreen.main.bounds.height * 0.0375)
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.8, height: 120)
                    .padding(.top, -UIScreen.main.bounds.height * 0.195)
                    
                    // Host controls
                    VStack(spacing: 32) {
                        StartGameSliderView(onComplete: {
                            gameManager.startGame()
                            navigateToGame = true
                        })
//                        if multipeerManager.isHost {
//                            if multipeerManager.players.count >= Constants.minPlayers {
//                                if allPlayersReady {
//                                    StartGameSliderView(onComplete: {
//                                        gameManager.startGame()
//                                    })
//                                } else {
//                                    Text("Waiting for all players to be ready...")
//                                        .foregroundColor(Color("text"))
//                                }
//                            } else {
//                                Text("Need at least \(Constants.minPlayers) players to start")
//                                    .foregroundColor(Color("text"))
//                            }
//                        } else {
//                            // Non-host player controls
//                            ReadyButtonView(
//                                isReady: $isLocalPlayerReady,
//                                onReady: {
//                                    updateLocalPlayerReadyStatus()
//                                }
//                            )
//                            
//                            if isLocalPlayerReady {
//                                Text("Waiting for host to start the game...")
//                                    .foregroundColor(Color("text"))
//                            } else {
//                                Text("Tap ready when you're prepared to play!")
//                                    .foregroundColor(Color("text"))
//                            }
//                        }
                        
                        HStack {
                            Text("ver. 1.0")
                                .font(.custom("VCROSDMono", size: 16))
                                .foregroundStyle(Color("text"))
                            
                            Spacer()
                            
                            Image("About_Button")
                                .resizable()
                                .frame(width: 70, height: 30)
                                .onTapGesture {
                                    showAbout = true
                                }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, UIScreen.main.bounds.height * 0.067)
                }
            }
        }
        .ignoresSafeArea(.all)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToGame) {
            GameView()
                .navigationBarBackButtonHidden(true)
                .environmentObject(gameManager)
                .environmentObject(multipeerManager)
        }
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
