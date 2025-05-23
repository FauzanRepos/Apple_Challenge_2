//
//  RoomListItemView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Paul Hudson. All rights reserved.
//

import SwiftUI

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
                    .strokeBorder(Color(.systemGray3), lineWidth: 2)
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

#Preview {
    RoomRowView(room: Room(name: "Test Room", capacity: 4, filledCapacity: 2), isSelected: false)
}
