//
//  Room.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation

struct Room: Identifiable {
    
    let id = UUID()
    let name: String
    let capacity: Int
    let filledCapacity: Int

}
