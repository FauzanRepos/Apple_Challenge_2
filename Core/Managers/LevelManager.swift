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
        print("[LevelManager] Attempting to load level file: \(fileName)")
        guard let data = LevelManager.readLevelFile(named: fileName) else {
            print("[LevelManager] Failed to load level file \(fileName)")
            currentLevelData = nil
            return
        }
        print("[LevelManager] Successfully loaded level data")
        currentLevelData = data
        print("[LevelManager] Current level data set: \(String(describing: currentLevelData))")
    }
    
    static func readLevelFile(named fileName: String) -> LevelData? {
        print("[LevelManager] Looking for file: \(fileName).txt in Resources/Content")
        
        // First, check if the file exists in the bundle
        let bundle = Bundle.main
        print("[LevelManager] Bundle paths: \(bundle.paths(forResourcesOfType: "txt", inDirectory: nil))")
        
        guard let url = bundle.url(forResource: fileName, withExtension: "txt"/*, subdirectory: "Resources/Content"*/) else {
            print("[LevelManager] ERROR: Could not find file \(fileName).txt in Resources/Content")
            return nil
        }
        print("[LevelManager] Found file at: \(url.path)")
        
        do {
            let content = try String(contentsOf: url)
            print("[LevelManager] Successfully read file contents: \(content.prefix(100))...")
            let levelData = LevelData.parse(from: content)
            print("[LevelManager] Parse result: \(String(describing: levelData))")
            return levelData
        } catch {
            print("[LevelManager] ERROR: Could not read file contents: \(error)")
            return nil
        }
    }
}
