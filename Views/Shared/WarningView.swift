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
    
    @StateObject var permissionManager = LANPermissionManager()
    @State private var navigateToHome = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color("spaceMazeBG")
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    // Icons
                    HStack(spacing: 40) {
                        Image(systemName: "wifi")
                        Image(systemName: "dot.radiowaves.left.and.right")
                    }
                    .font(.system(size: 40))
                    .foregroundColor(Color("yellowHighlightText"))

                    // Game description
                    Text("Space Maze is a cooperative game played with 2–4 people in the same group.\nEach player needs a phone")
                        .multilineTextAlignment(.center)
                        .font(.custom("Menlo", size: 16))
                        .foregroundColor(Color("text"))
                        .padding(.horizontal)

                    // Tip
                    Text("Tips: make sure you can communicate with fellow space crew")
                        .multilineTextAlignment(.center)
                        .font(.custom("Menlo", size: 16))
                        .foregroundColor(Color("text"))
                        .padding(.horizontal)

                    // Warning
                    Text("WARNING: This game contains flashing lights.")
                        .multilineTextAlignment(.center)
                        .font(.custom("Menlo-Bold", size: 16))
                        .foregroundColor(Color("yellowHighlightText"))
                        .padding(.horizontal)
                        .padding(.top)

                    Spacer()

                    // Continue Button
                    Button(action: {
                        permissionManager.onPermissionStatusChanged = { hasPermission in
                            if hasPermission {
                                navigateToHome = true
                            } else {
                                navigateToHome = true // Temp allow nav to home regardless
//                                print("Permission denied")
                            }
                        }
                        
                        permissionManager.triggerPermissionPrompt()
                    }) {
                        Text("CONTINUE")
                            .font(.custom("Menlo-Bold", size: 18))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.green, lineWidth: 2)
                                    .background(Color.gray.opacity(0.3))
                            )
                            .foregroundColor(Color("yellowHighlightText"))
                            .padding(.horizontal, 30)
                    }

                    Spacer(minLength: 30)
                }
            }
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView()
            }
        }
    }
}

#Preview {
    WarningView()
}
