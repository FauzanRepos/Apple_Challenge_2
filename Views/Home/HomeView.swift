//
//  HomeView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var multipeerManager: MultipeerManager
    @EnvironmentObject var storageManager: StorageManager
    
    @State private var showLobby = false
    @State private var showSettings = false
    @State private var showAbout = false
    
    @State private var roomCode: String = ""
    @State private var showCodeInput = false
    
    // Helper to generate a random 6-character alphanumeric code
    private func generateRoomCode() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<4).map { _ in chars.randomElement()! })
    }
    
    var body: some View {
        ZStack {
            Image("HomePage")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 28) {
                Spacer().frame(height: 60)
                
                HighScoreView()
                    .environmentObject(storageManager)
                    .padding(.bottom, 16)
                
                Text("👩‍🚀 Captain says: Work together and get every marble home!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                // CREATE ROOM BUTTON
                Button(action: {
                    roomCode = generateRoomCode()
                    multipeerManager.hostGame(sessionCode: roomCode)
                    showLobby = true
                }) {
                    Image("Button")
                        .resizable()
                        .frame(width: 220, height: 54)
                        .overlay(
                            Text("Create Room")
                                .font(.title2)
                                .foregroundColor(.white)
                                .bold()
                        )
                }
                // JOIN ROOM BUTTON
                Button(action: { showCodeInput = true }) {
                    Image("Button")
                        .resizable()
                        .frame(width: 220, height: 54)
                        .overlay(
                            Text("Join Room")
                                .font(.title2)
                                .foregroundColor(.white)
                                .bold()
                        )
                }
                
                Button(action: { showSettings = true }) {
                    Image("LongButton")
                        .resizable()
                        .frame(width: 220, height: 44)
                        .overlay(
                            Text("Settings")
                                .font(.body)
                                .foregroundColor(.white)
                        )
                }
                
                Button(action: { showAbout = true }) {
                    Image("Q_Button")
                        .resizable()
                        .frame(width: 54, height: 54)
                }
                
                Spacer()
            }
            .sheet(isPresented: $showLobby) {
                LobbyView()
                    .environmentObject(gameManager)
                    .environmentObject(multipeerManager)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(gameManager)
                    .environmentObject(storageManager)
            }
            .sheet(isPresented: $showAbout) {
                WarningView(message: "This is about the game")
            }
            .sheet(isPresented: $showCodeInput) {
                VStack(spacing: 16) {
                    Text("Enter Room Code to Join")
                        .font(.title2)
                    TextField("Room Code", text: $roomCode)
                        .textCase(.uppercase)
                        .keyboardType(.asciiCapable)
                        .multilineTextAlignment(.center)
                        .frame(width: 120)
                        .textFieldStyle(.roundedBorder)
                    Button("Join") {
                        multipeerManager.joinGame(sessionCode: roomCode)
                        showCodeInput = false
                        showLobby = true
                    }
                    .disabled(roomCode.count != 4)
                    Button("Cancel") {
                        showCodeInput = false
                        roomCode = ""
                    }
                }
                .padding()
            }
        }
    }
}
