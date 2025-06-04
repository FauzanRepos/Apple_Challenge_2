//
//  LobbyView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

// MARK: - Room Model
struct Room: Identifiable {
    let id = UUID()
    let name: String
    let capacity: Int
    let filledCapacity: Int
}

// MARK: - RoomRowView
struct RoomRowView: View {
    let room: Room
    var capacityText: String {
        "\(room.filledCapacity)/\(room.capacity)"
    }
    var isSelected: Bool = false

    var body: some View {
        VStack (spacing: 4) {
            HStack {
                Circle()
                    .strokeBorder(.gray.opacity(0.4), lineWidth: 2)
                    .background(Circle().fill(isSelected ? .gray : .clear))
                    .frame(width: 16, height: 16)
                    .padding(.horizontal, 8)
                
                Text(room.name)
                    .foregroundStyle(.black)
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                
                Spacer()
                
                Rectangle()
                    .fill(.black)
                    .frame(width: 2, height: 32)
                
                Text(capacityText)
                    .foregroundStyle(.black)
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .padding(.leading, 48)
            }
            .padding(.horizontal)
            
            Rectangle()
                .fill(.black)
                .frame(maxWidth: .infinity, minHeight: 2, maxHeight: 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

// MARK: - LobbyView
struct LobbyView: View {
    let isHost: Bool
    @State private var showGameplay = false
    @State private var sliderOffset: CGFloat = 0
    @State private var isSwipeComplete = false
    @State private var showSettings = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(red: 0.2, green: 0.2, blue: 0.2)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Top gray border area
                    Rectangle()
                        .fill(Color(red: 0.5, green: 0.5, blue: 0.5))
                        .frame(height: 20)
                    
                    // Main content area
                    ZStack {
                        // Green background
                        Color(red: 0.2, green: 0.8, blue: 0.2)
                        
                        VStack(spacing: 0) {
                            // Room name with icon
                            HStack(spacing: 12) {
                                Image("Compass")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                Text("SwiftFun")
                                    .pixelTextStyle(color: .yellow)
                            }
                            .padding(.top, 40)
                            
                            // Ship Code
                            VStack(spacing: 12) {
                                Text("Ship Code")
                                    .pixelTextStyle()
                                
                                Text("A1B2")
                                    .pixelTextStyle()
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                
                                Text("Share the code with")
                                    .pixelTextStyle()
                                Text("fellow space crew")
                                    .pixelTextStyle()
                            }
                            .padding(.top, 30)
                            
                            // Player list
                            VStack(spacing: 16) {
                                PlayerRow(name: "Jo", isReady: true)
                                PlayerRow(name: "Rachel", isReady: false)
                                PlayerRow(name: "Pauzan", isReady: true)
                                PlayerRow(name: "Wesly", isReady: false)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                            
                            // Character with speech bubble
                            HStack {
                                Image("HQ_Character")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                
                                // Speech bubble
                                ZStack {
                                    Image("PopUp")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 60)
                                    
                                    Text("As a commander, make sure\nevery crew is ready before\nstarting the game!")
                                        .pixelTextStyle()
                                        .multilineTextAlignment(.leading)
                                        .font(.custom("PressStart2P-Regular", size: 12))
                                        .padding(.horizontal, 20)
                                }
                            }
                            .padding(.top, 30)
                            
                            Spacer()
                            
                            // Swipe to Start (only shown for host)
                            // if isHost {
                                ZStack {
                                    Image("StartGame_Slider_Base")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 50)
                                    
                                    HStack {
                                        Image("StartGame_Slider_Ball")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40)
                                            .offset(x: sliderOffset)
                                            .gesture(
                                                DragGesture()
                                                    .onChanged { gesture in
                                                        if !isSwipeComplete {
                                                            sliderOffset = min(max(0, gesture.translation.width), 100)
                                                        }
                                                    }
                                                    .onEnded { gesture in
                                                        if sliderOffset > 80 {
                                                            withAnimation {
                                                                sliderOffset = 100
                                                                isSwipeComplete = true
                                                            }
                                                            showGameplay = true
                                                        } else {
                                                            withAnimation {
                                                                sliderOffset = 0
                                                            }
                                                        }
                                                    }
                                            )
                                        
                                        Text(isSwipeComplete ? "Starting..." : "Swipe to Start")
                                            .pixelTextStyle()
                                            .padding(.horizontal)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                            // }
                            
                            // Version and About
                            HStack {
                                Text("ver.1.0")
                                    .pixelTextStyle(color: .yellow)
                                    .font(.system(size: 12))
                                
                                Spacer()
                                
                                Button(action: {
                                    showSettings = true
                                }) {
                                    Image("About_Button")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 25)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                        }
                    }
                    
                    // Bottom gray border area
                    Rectangle()
                        .fill(Color(red: 0.5, green: 0.5, blue: 0.5))
                        .frame(height: 20)
                }
            }
            .navigationDestination(isPresented: $showGameplay) {
                GameViewWrapper(isHost: isHost)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

struct PlayerRow: View {
    let name: String
    let isReady: Bool
    
    var body: some View {
        HStack {
            Text("• \(name)")
                .pixelTextStyle()
            
            Spacer()
            
            Image(isReady ? "Circle_Light_Green" : "Circle_Light_White")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        }
    }
}

#Preview {
    LobbyView(isHost: true)
}
