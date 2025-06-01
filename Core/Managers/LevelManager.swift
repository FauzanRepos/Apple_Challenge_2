//
//  LevelManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//
import Foundation
import SwiftUI

/// Handles level loading, map data, and per-planet asset logic.
final class LevelManager: ObservableObject {
    static let shared = LevelManager()
    
    @Published var currentLevelData: LevelData? = nil
    @Published var backgroundImageName: String = ""
    @Published var planetAssetPrefix: String = ""
    
    private init() {}
    
    /// Loads level data from file (e.g., "level1.txt").
    func loadLevel(_ level: Int) {
        let fileName = "level\(level)"
        if let data = LevelManager.readLevelFile(named: fileName) {
            currentLevelData = data
            backgroundImageName = "Background_\(level)"
            planetAssetPrefix = "Planets/Planet\(level)/"
        }
    }
    
    static func readLevelFile(named fileName: String) -> LevelData? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "txt", subdirectory: "Resources/Levels") else { return nil }
        guard let content = try? String(contentsOf: url) else { return nil }
        return LevelData.parse(from: content)
    }
}

/// Parsed level structure (used by GameScene)
struct LevelData {
    let width: Int
    let height: Int
    let walls: [CGRect]
    let checkpoints: [CGPoint]
    let vortexes: [CGPoint]
    let oils: [CGPoint]
    let grasses: [CGPoint]
    let start: CGPoint
    let finish: CGPoint
    
    /// Parse from .txt file
    static func parse(from text: String) -> LevelData? {
        // For brevity, here is a simple parser for a basic level text format
        // You should expand this parser as needed for your level file format
        var width = 0, height = 0
        var walls: [CGRect] = []
        var checkpoints: [CGPoint] = []
        var vortexes: [CGPoint] = []
        var oils: [CGPoint] = []
        var grasses: [CGPoint] = []
        var start = CGPoint.zero
        var finish = CGPoint.zero
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("MAP") {
                let comps = trimmed.components(separatedBy: " ")
                if comps.count == 2, let mapDims = comps.last?.components(separatedBy: "x"),
                   mapDims.count == 2, let w = Int(mapDims[0]), let h = Int(mapDims[1]) {
                    width = w; height = h
                }
            } else if trimmed.hasPrefix("WALLS") {
                // ...parse wall positions, e.g., WALLS x1,y1,x2,y2;...
                // (for brevity, skipped detailed parsing, implement as needed)
            } else if trimmed.hasPrefix("CHECKPOINTS") {
                // ...parse checkpoint positions
            } else if trimmed.hasPrefix("VORTEX") {
                // ...parse vortex positions
            } else if trimmed.hasPrefix("OIL") {
                // ...parse oil positions
            } else if trimmed.hasPrefix("GRASS") {
                // ...parse grass positions
            } else if trimmed.hasPrefix("START") {
                // START x,y
                let comps = trimmed.components(separatedBy: " ")
                if comps.count == 2, let xy = comps.last?.components(separatedBy: ","), xy.count == 2,
                   let x = Double(xy[0]), let y = Double(xy[1]) {
                    start = CGPoint(x: x, y: y)
                }
            } else if trimmed.hasPrefix("FINISH") {
                let comps = trimmed.components(separatedBy: " ")
                if comps.count == 2, let xy = comps.last?.components(separatedBy: ","), xy.count == 2,
                   let x = Double(xy[0]), let y = Double(xy[1]) {
                    finish = CGPoint(x: x, y: y)
                }
            }
        }
        return LevelData(width: width, height: height, walls: walls, checkpoints: checkpoints, vortexes: vortexes, oils: oils, grasses: grasses, start: start, finish: finish)
    }
}
