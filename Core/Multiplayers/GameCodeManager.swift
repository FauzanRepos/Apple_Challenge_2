//
//  GameCodeManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation

/// Generates and validates session codes for joining/hosting multiplayer
final class GameCodeManager {
    static let shared = GameCodeManager()
    private init() {}
    
    // 6-character uppercase session code
    func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<4).map { _ in chars.randomElement()! })
    }
    
    func validate(_ code: String) -> Bool {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return code.count == 4 && code.uppercased().rangeOfCharacter(from: allowed.inverted) == nil
    }
}
