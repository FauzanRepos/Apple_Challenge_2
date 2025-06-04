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
    @EnvironmentObject var audioManager: AudioManager
    
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var navigateToLobby = false
    @State private var navigateToJoin = false
    
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
                    .padding(.top, UIScreen.main.bounds.height * 0.047)
                
                Spacer()
                
                ZStack(alignment: .top) {
                    Image("Assistant")
                        .resizable()
                        .frame(width: UIScreen.main.bounds.width * 0.8, height: 120)
                    
                    Text("This is HQ!")
                        .font(.custom("VCROSDMono", size: 16))
                        .foregroundStyle(Color("text"))
                        .frame(width: UIScreen.main.bounds.width * 0.8, alignment: .leading)
                        .padding(.leading, UIScreen.main.bounds.width * 0.53)
                        .padding(.top, UIScreen.main.bounds.height * 0.0493)
                }
                .frame(width: UIScreen.main.bounds.width * 0.8, height: 120)
                .padding(.top, -UIScreen.main.bounds.height * 0.2)
                
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
                            audioManager.playSFX("sfx_buttonclick", xtension: "wav")
                            var roomCode = gameManager.gameCode.generateCode()
                            multipeerManager.hostGame(sessionCode: roomCode)
                            navigateToLobby = true
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
                            audioManager.playSFX("sfx_buttonclick", xtension: "wav")
                            navigateToJoin = true
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
                            .onTapGesture {
                                audioManager.playSFX("sfx_buttonclick", xtension: "wav")
                                showAbout = true
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                }
                
                Button(action: { 
                    audioManager.playSFX("sfx_buttonclick", xtension: "wav")
                    showSettings = true 
                }) {
                    Image("LongButton")
                        .resizable()
                        .frame(width: 220, height: 44)
                        .overlay(
                            Text("Settings")
                                .font(.body)
                                .foregroundColor(.white)
                        )
                }
            }
            .padding(.top, UIScreen.main.bounds.height * 0.0235)
            .padding(.bottom, UIScreen.main.bounds.height * 0.0235)
//            .padding(.bottom, UIScreen.main.bounds.height * 0.067)
        }
        .navigationDestination(isPresented: $navigateToLobby) {
            LobbyView()
                .environmentObject(gameManager)
                .environmentObject(multipeerManager)
                .environmentObject(audioManager)
        }
        .navigationDestination(isPresented: $navigateToJoin) {
            JoinRoomView()
                .environmentObject(gameManager)
                .environmentObject(multipeerManager)
                .environmentObject(audioManager)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(gameManager)
                .environmentObject(storageManager)
        }
        .navigationBarBackButtonHidden(true)
    }
}
