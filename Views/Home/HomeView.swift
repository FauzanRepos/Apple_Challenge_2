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
                
                Button(action: { showLobby = true }) {
                    Image("Button")
                        .resizable()
                        .frame(width: 220, height: 54)
                        .overlay(
                            Text("Create / Join Room")
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
        }
    }
}
