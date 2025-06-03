//
//  WarningView.swift
//  Space Maze
//
//  Created by WESLY CHAU LI ZHAN on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI
import MultipeerConnectivity

struct WarningView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var multipeerManager: MultipeerManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var permissionManager: LANPermissionManager
    @State private var navigateToHome = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color("spaceMazeBG")
                    .ignoresSafeArea()
                
                Image("AlertPage")
                    .resizable()
                    .ignoresSafeArea(.all)
                
                VStack(alignment: .leading, spacing: 20) {
                    Spacer(minLength: 170)
                    
                    // Icons
                    HStack(alignment: .center, spacing: 40) {
                        Image("WiFi_Icon")
                            .resizable()
                            .frame(width: 45, height: 36)
                        Image("BT_Icon")
                            .resizable()
                            .frame(width: 32, height: 45)
                    }
                    .foregroundColor(Color("yellowHighlightText"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Game description
                    Text("Space Maze is a cooperative game played with 2–4 people in the same group.\nEach player needs a phone")
                        .multilineTextAlignment(.leading)
                        .font(.custom("VCROSDMono", size: 20))
                        .foregroundColor(Color("text"))
                        .padding(.horizontal, 50)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Tip
                    Text("Tips: make sure you can communicate with fellow space crew")
                        .multilineTextAlignment(.leading)
                        .font(.custom("VCROSDMono", size: 20))
                        .foregroundColor(Color("text"))
                        .padding(.horizontal, 50)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Warning
                    Text("WARNING: This game contains flashing lights.")
                        .multilineTextAlignment(.leading)
                        .font(.custom("VCROSDMono", size: 20))
                        .foregroundColor(Color("yellowHighlightText"))
                        .padding(.horizontal, 50)
                        .padding(.top)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 150)
                    
                    // Continue Button
                    Button(action: {
                        permissionManager.onPermissionStatusChanged = { hasPermission in
                            if hasPermission {
                                navigateToHome = true
                            } else {
                                navigateToHome = true // Temp allow nav to home regardless
                                print("Permission denied")
                            }
                        }
                        navigateToHome = true
                        permissionManager.triggerPermissionPrompt()
                    }) {
                        ZStack {
                            Image("Button")
                                .resizable()
                                .frame(width: 340, height: 70)
                            Text("CONTINUE")
                                .font(.custom("VCROSDMono", size: 36))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .foregroundColor(Color("text"))
                                .padding(.horizontal, 30)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView()
                    .environmentObject(gameManager)
                    .environmentObject(multipeerManager)
                    .environmentObject(audioManager)
                    .environmentObject(settingsManager)
                    .environmentObject(storageManager)
            }
        }
    }
}

#Preview {
    WarningView()
        .environmentObject(GameManager.shared)
        .environmentObject(MultipeerManager.shared)
        .environmentObject(AudioManager.shared)
        .environmentObject(SettingsManager.shared)
        .environmentObject(StorageManager.shared)
        .environmentObject(LANPermissionManager.shared)
}
