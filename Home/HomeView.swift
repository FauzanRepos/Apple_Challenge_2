//
//  HomeView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @State private var navigateToLobby = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HighScoreView()
                Spacer()
                VStack (spacing: 40) {
                    StartGameSliderView {
                        navigateToLobby = true
                    }
                    
                    HStack {
                        Text("ver. 0.0.1")
                            .font(.system(size: 12))
                        Spacer()
                        Button("About") {
                            /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(.black)
                        .frame(height: 30)
                        .padding(.horizontal)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 20)
            .navigationDestination(isPresented: $navigateToLobby) {
                LobbyView()
            }
        }
    }
}

#Preview {
    HomeView()
}
