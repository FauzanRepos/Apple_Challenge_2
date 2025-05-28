//
//  LobbyView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct LobbyView: View {
    
    @State private var selectedRoomIndex: Int? = nil
    
    var rooms: [(Room)] = [
        Room(name: "Room 1", capacity: 4, filledCapacity: 3),
        Room(name: "Room 2", capacity: 4, filledCapacity: 0),
        Room(name: "Room 3", capacity: 4, filledCapacity: 2),
        Room(name: "Room 4", capacity: 4, filledCapacity: 0),
        Room(name: "Room 5", capacity: 4, filledCapacity: 1),
        Room(name: "Room 6", capacity: 4, filledCapacity: 0)
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 4) {
                    ForEach(rooms.indices, id: \.self) { index in
                        RoomRowView(room: rooms[index], isSelected: selectedRoomIndex == index)
                            .onTapGesture {
                                selectedRoomIndex = index
                            }
                    }
                    Spacer()
                }
                .padding(.vertical)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .padding(.horizontal)
                
                NavigationLink(destination: GameViewWrapper().ignoresSafeArea()
                    .navigationBarBackButtonHidden(true)) {
                    Text("Enter")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .padding(.horizontal)
                        .background(Color(.systemGray4))
                        .cornerRadius(10)
                        .padding(.vertical)
                        .padding(.horizontal)
                }
                
            }
            .padding(.top)
            .toolbar {
                ToolbarItem (placement: .topBarLeading) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.black)
                        .background(Color(.systemGray5))
                }
                ToolbarItem (placement: .principal) {
                    Text("SwiftFun")
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            //        .navigationDestination(isPresented: $goToGame) {
            //            GameViewWrapper()
            //        }
        }
    }
}

#Preview {
    LobbyView()
}
