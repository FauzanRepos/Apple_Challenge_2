//
//  LobbyView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var multipeerManager: MultipeerManager
    @EnvironmentObject var gameManager: GameManager
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 18) {
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
            
            Text("Ship Code: \(multipeerManager.sessionCode)")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.top, 16)
            
            PlayerListView()
                .environmentObject(multipeerManager)
            
            if multipeerManager.isHost {
                StartGameSliderView(onSlide: {
                    gameManager.startGame()
                })
                .padding(.top, 30)
            } else {
                Text("Waiting for host to start…")
                    .foregroundColor(.gray)
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
        .onDisappear {
            // Clean up if view is dismissed
            multipeerManager.stopHosting()
            multipeerManager.stopBrowsing()
        }
    }
}
