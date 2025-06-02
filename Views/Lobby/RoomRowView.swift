//
//  RoomListItemView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct RoomRowView: View {
    let room: Room
    var onJoin: () -> Void
    
    var body: some View {
        HStack {
            Text("Room: \(room.code)")
                .font(.body)
                .foregroundColor(.white)
            Spacer()
            Text("\(room.players.count) players")
                .foregroundColor(.gray)
            Button(action: onJoin) {
                Text("Join")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(10)
    }
}
