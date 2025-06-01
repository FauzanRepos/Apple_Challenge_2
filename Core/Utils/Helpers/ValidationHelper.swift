//
//  ValidationHelper.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation

struct ValidationHelper {
    static func isValidPlayerName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 16
    }
    
    static func isValidRoomCode(_ code: String) -> Bool {
        return GameCodeManager.shared.validate(code)
    }
}
