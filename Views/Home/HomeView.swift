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
    
    var body: some View {
        ZStack {
            
            Color("spaceMazeBG")
                .ignoresSafeArea()
            
            Image("HomePage")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack() {
                HighScoreView()
                    .environmentObject(storageManager)
                    .padding(.top, 40)
                
//                ZStack {
                    Spacer()
                    
//                    Text("👩‍🚀 Captain says: Work together and get every marble home!")
//                        .font(.custom("VCROSDMono", size: 30))
//                        .foregroundColor(Color("text"))
//                    
//                }
                
                
                VStack (spacing: 25) {
                    HStack (spacing: 36) {
                        ZStack {
                            Image("Button")
                                .resizable()
                                .frame(width: 142, height: 73)
                            
                            Text("CREATE\nROOM")
                                .font(.custom("VCROSDMono", size: 22))
                                .foregroundStyle(Color("text"))
                                .frame(width: 142, height: 73)
                                .tracking(2)
                                .multilineTextAlignment(.center)
                        }
                        .onTapGesture {
                            roomCode = gameManager.gameCode.generateCode()
                            multipeerManager.hostGame(sessionCode: roomCode)
                            showLobby = true
                        }
                        
                        ZStack {
                            Image("Button")
                                .resizable()
                                .frame(width: 142, height: 73)
                            Text("JOIN\nROOM")
                                .font(.custom("VCROSDMono", size: 22))
                                .foregroundStyle(Color("text"))
                                .frame(width: 142, height: 73)
                                .tracking(2)
                                .multilineTextAlignment(.center)
                        }
                        .onTapGesture {
                            showCodeInput = true
                        }
                            
                    }
                    
                    HStack {
                        Text("ver. 1.0")
                            .font(.custom("VCROSDMono", size: 16))
                            .foregroundStyle(Color("text"))
                        
                        Spacer()
                        
                        Image("About_Button")
                            .resizable()
                            .frame(width: 70, height: 30)
                            .padding(.horizontal)
                            .onTapGesture {
                                showAbout = true
                            }
                    }
                    .padding(.horizontal)
                }
                
//                // CREATE ROOM BUTTON
//                Button(action: {
//                    roomCode = gameManager.gameCode.generateCode()
//                    multipeerManager.hostGame(sessionCode: roomCode)
//                    showLobby = true
//                }) {
//                    Image("Button")
//                        .resizable()
//                        .frame(width: 220, height: 54)
//                        .overlay(
//                            Text("Create Room")
//                                .font(.title2)
//                                .foregroundColor(.white)
//                                .bold()
//                        )
//                }
//                // JOIN ROOM BUTTON
//                Button(action: { showCodeInput = true }) {
//                    Image("Button")
//                        .resizable()
//                        .frame(width: 220, height: 54)
//                        .overlay(
//                            Text("Join Room")
//                                .font(.title2)
//                                .foregroundColor(.white)
//                                .bold()
//                        )
//                }
                
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
                
//                Button(action: { showAbout = true }) {
//                    Image("Q_Button")
//                        .resizable()
//                        .frame(width: 54, height: 54)
//                }
            }
            .padding(.vertical, 20)
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
                        multipeerManager.joinGame(sessionCode: roomCode.uppercased())
                        showCodeInput = false
                        showLobby = true
                    }
                    .disabled(!gameManager.gameCode.validate(roomCode))
                    Button("Cancel") {
                        showCodeInput = false
                        roomCode = ""
                    }
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}
