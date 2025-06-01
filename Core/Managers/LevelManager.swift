//
//  LevelManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import SwiftUI

final class LevelManager: ObservableObject {
    static let shared = LevelManager()
    
    @Published var currentLevelData: LevelData? = nil
    @Published var backgroundImageName: String = ""
    @Published var planetAssetPrefix: String = ""
    
    private init() {}
    
    func loadLevel(_ level: Int) {
        let fileName = "level\(level)"
        guard let data = LevelManager.readLevelFile(named: fileName) else {
            print("[LevelManager] Failed to load level file \(fileName)")
            currentLevelData = nil
            return
        }
        currentLevelData = data
        backgroundImageName = "Background_\(level)"
        planetAssetPrefix = "Planets/Planet\(level)/"
    }
    
    static func readLevelFile(named fileName: String) -> LevelData? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "txt", subdirectory: "Resources/Levels") else { return nil }
        guard let content = try? String(contentsOf: url) else { return nil }
        return LevelData.parse(from: content)
    }
}
