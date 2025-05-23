//
//  RoomModel.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Paul Hudson. All rights reserved.
//

import Foundation

struct Room: Identifiable {
    
    let id = UUID()
    let name: String
    let capacity: Int
    let filledCapacity: Int

}
