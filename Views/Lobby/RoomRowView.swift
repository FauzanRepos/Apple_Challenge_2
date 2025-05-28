//
//  RoomRowView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct RoomRowView: View {
    
    let room: Room
    var isSelected: Bool = false
    @State private var animateSelection: Bool = false
    @State private var pulseCapacity: Bool = false
    
    var capacityText: String {
        "\(room.filledCapacity)/\(room.capacity)"
    }
    
    var isAvailable: Bool {
        room.filledCapacity < room.capacity
    }
    
    var capacityColor: Color {
        let ratio = Double(room.filledCapacity) / Double(room.capacity)
        switch ratio {
        case 0.0..<0.5: return .green
        case 0.5..<0.8: return .yellow
        case 0.8..<1.0: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.green : Color.gray.opacity(0.5),
                            lineWidth: 2
                        )
                        .background(
                            Circle()
                                .fill(isSelected ? Color.green.opacity(0.3) : Color.clear)
                        )
                        .frame(width: 20, height: 20)
                        .scaleEffect(animateSelection ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: animateSelection)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .scaleEffect(animateSelection ? 1.1 : 0.9)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateSelection)
                    }
                }
                .padding(.leading, 8)
                
                // Room Name
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        // Status indicator
                        Circle()
                            .fill(isAvailable ? .green : .red)
                            .frame(width: 6, height: 6)
                            .scaleEffect(pulseCapacity ? 1.5 : 1.0)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseCapacity)
                        
                        Text(isAvailable ? "Available" : "Full")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Capacity Section
                HStack(spacing: 12) {
                    // Capacity visualization
                    HStack(spacing: 4) {
                        ForEach(0..<room.capacity, id: \.self) { index in
                            Circle()
                                .fill(index < room.filledCapacity ? capacityColor : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index < room.filledCapacity && pulseCapacity ? 1.3 : 1.0)
                                .animation(
                                    .easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.1),
                                    value: pulseCapacity
                                )
                        }
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 2, height: 32)
                        .opacity(0.5)
                    
                    // Capacity Text
                    Text(capacityText)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(capacityColor)
                        .frame(minWidth: 40)
                }
                .padding(.trailing, 8)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                        ? Color.green.opacity(0.15)
                        : Color.gray.opacity(0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected
                                ? Color.green.opacity(0.5)
                                : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? .green.opacity(0.3) : .clear,
                        radius: isSelected ? 8 : 0,
                        x: 0,
                        y: 4
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            
            // Separator Line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.gray.opacity(0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 32)
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                animateSelection = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateSelection = false
                }
            }
        }
        .onAppear {
            pulseCapacity = true
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        RoomRowView(
            room: Room(name: "Alpha Squad", capacity: 4, filledCapacity: 2),
            isSelected: false
        )
        
        RoomRowView(
            room: Room(name: "Beta Team", capacity: 4, filledCapacity: 4),
            isSelected: true
        )
        
        RoomRowView(
            room: Room(name: "Gamma Force", capacity: 6, filledCapacity: 1),
            isSelected: false
        )
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
