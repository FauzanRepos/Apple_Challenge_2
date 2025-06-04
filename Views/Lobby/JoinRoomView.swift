//
//  JoinRoomView.swift
//  Space Maze
//
//  Created by WESLY CHAU LI ZHAN on 01/06/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct JoinRoomView: View {
    @EnvironmentObject var multipeerManager: MultipeerManager
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var audioManager: AudioManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var roomCode: String = ""
    @State private var showCodeInput = false
    @State private var navigateToLobby = false
    @State private var isJoining = false
    
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
                                audioManager.playSFX("sfx_buttonclick", xtension: "wav")
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
                    
                    VStack(spacing: 8) {
                        Text("Ship Code")
                            .font(.custom("VCROSDMono", size: 32))
                            .foregroundStyle(Color("text"))
                            .multilineTextAlignment(.center)
                        
                        // Clickable code area
                        Button(action: {
                            audioManager.playSFX("sfx_buttonclick", xtension: "wav")
                            showCodeInput = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: UIScreen.main.bounds.width * 0.547, height: 60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color("text").opacity(0.5), lineWidth: 2)
                                    )
                                
                                if roomCode.isEmpty {
                                    Text("")
                                        .font(.custom("VCROSDMono", size: 24))
                                        .foregroundStyle(Color("text").opacity(0.6))
                                } else {
                                    Text(roomCode)
                                        .font(.custom("VCROSDMono", size: 32))
                                        .foregroundStyle(Color("text"))
                                        .tracking(16)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Text("Enter the code given\n by your commander")
                            .font(.custom("VCROSDMono", size: 16))
                            .foregroundStyle(Color("text"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 56)
                    
                    // Empty player list area (placeholder)
                    VStack {
                        Text("Connecting...")
                            .font(.custom("VCROSDMono", size: 20))
                            .foregroundStyle(Color("text").opacity(0.6))
                            .padding(.top, 40)
                        
                        if isJoining {
                            ProgressView()
                                .tint(Color("text"))
                                .padding(.top, 40)
                        }
                    }
                    .frame(height: 120)
                    
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
                    
                    // Join button area
                    VStack(spacing: 32) {
                        VStack {
                            if !roomCode.isEmpty && gameManager.gameCode.validate(roomCode) {
                                Button(action: {
                                    audioManager.playSFX("sfx_buttonclick", xtension: "wav")
                                    joinRoom()
                                }) {
                                    ZStack {
                                        Image("Button")
                                            .resizable()
                                            .frame(width: 220, height: 70)
                                        Text("JOIN MISSION")
                                            .font(.custom("VCROSDMono", size: 24))
                                            .foregroundStyle(Color("text"))
                                            .tracking(2)
                                    }
                                }
                                .disabled(isJoining)
                            }
                        }
                        .frame(height: 70)
                        
                        HStack {
                            Text("ver. 1.0")
                                .font(.custom("VCROSDMono", size: 16))
                                .foregroundStyle(Color("text"))
                            
                            Spacer()
                            
                            Image("About_Button")
                                .resizable()
                                .frame(width: 70, height: 30)
                                .onTapGesture {
                                    audioManager.playSFX("sfx_buttonclick", xtension: "wav")
//                                    showAbout = true
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
        .navigationDestination(isPresented: $navigateToLobby) {
            LobbyView()
                .navigationBarBackButtonHidden(true)
                .environmentObject(gameManager)
                .environmentObject(multipeerManager)
                .environmentObject(audioManager)
        }
        .sheet(isPresented: $showCodeInput) {
            VStack(spacing: 24) {
                Text("Enter Ship Code")
                    .font(.custom("VCROSDMono", size: 24))
                    .foregroundColor(Color("text"))
                
                TextField("XXXX", text: $roomCode)
                    .textCase(.uppercase)
                    .keyboardType(.asciiCapable)
                    .multilineTextAlignment(.center)
                    .font(.custom("VCROSDMono", size: 32))
                    .foregroundColor(Color("text"))
                    .frame(width: 200)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("text").opacity(0.5), lineWidth: 2)
                    )
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        audioManager.playSFX("sfx_buttonclick", xtension: "wav")
                        showCodeInput = false
                        roomCode = ""
                    }
                    .font(.custom("VCROSDMono", size: 18))
                    .foregroundColor(Color("text"))
                    .padding()
                    .background(Color.red.opacity(0.3))
                    .cornerRadius(8)
                    
                    Button("Confirm") {
                        audioManager.playSFX("sfx_buttonclick", xtension: "wav")
                        showCodeInput = false
                    }
                    .font(.custom("VCROSDMono", size: 18))
                    .foregroundColor(Color("text"))
                    .padding()
                    .background(Color.green.opacity(0.3))
                    .cornerRadius(8)
                    .disabled(roomCode.isEmpty)
                }
            }
            .padding(40)
            .background(Color("spaceMazeBG"))
            .cornerRadius(20)
            .padding()
        }
    }
    
    private func joinRoom() {
        isJoining = true
        multipeerManager.joinGame(sessionCode: roomCode.uppercased())
        
        // Wait a moment for connection, then navigate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            navigateToLobby = true
            isJoining = false
        }
    }
} 
