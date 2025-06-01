//
//  Level.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

/// Parsed level structure (used by GameScene and LevelManager)
struct LevelData: Codable {
    let wallRects: [CGRect]
    let checkpointPositions: [CGPoint]
    let vortexPositions: [CGPoint]
    let oilPositions: [CGPoint]
    let grassPositions: [CGPoint]
    let start: CGPoint
    let finish: CGPoint
    
    // MARK: - Parse from .txt file
    static func parse(from text: String) -> LevelData? {
        var wallRects: [CGRect] = []
        var checkpointPositions: [CGPoint] = []
        var vortexPositions: [CGPoint] = []
        var oilPositions: [CGPoint] = []
        var grassPositions: [CGPoint] = []
        var start = CGPoint.zero
        var finish = CGPoint.zero
        
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("WALLS") {
                // WALLS x1,y1,w1,h1;x2,y2,w2,h2;...
                let rects = trimmed.dropFirst(5).split(separator: ";")
                for r in rects {
                    let nums = r.split(separator: ",").compactMap { Double($0) }
                    if nums.count == 4 {
                        let rect = CGRect(x: nums[0], y: nums[1], width: nums[2], height: nums[3])
                        wallRects.append(rect)
                    }
                }
            } else if trimmed.hasPrefix("CHECKPOINTS") {
                // CHECKPOINTS x1,y1;x2,y2;...
                let pts = trimmed.dropFirst(11).split(separator: ";")
                for pt in pts {
                    let nums = pt.split(separator: ",").compactMap { Double($0) }
                    if nums.count == 2 {
                        checkpointPositions.append(CGPoint(x: nums[0], y: nums[1]))
                    }
                }
            } else if trimmed.hasPrefix("VORTEX") {
                // VORTEX x1,y1;x2,y2;...
                let pts = trimmed.dropFirst(6).split(separator: ";")
                for pt in pts {
                    let nums = pt.split(separator: ",").compactMap { Double($0) }
                    if nums.count == 2 {
                        vortexPositions.append(CGPoint(x: nums[0], y: nums[1]))
                    }
                }
            } else if trimmed.hasPrefix("OIL") {
                // OIL x1,y1;x2,y2;...
                let pts = trimmed.dropFirst(3).split(separator: ";")
                for pt in pts {
                    let nums = pt.split(separator: ",").compactMap { Double($0) }
                    if nums.count == 2 {
                        oilPositions.append(CGPoint(x: nums[0], y: nums[1]))
                    }
                }
            } else if trimmed.hasPrefix("GRASS") {
                // GRASS x1,y1;x2,y2;...
                let pts = trimmed.dropFirst(5).split(separator: ";")
                for pt in pts {
                    let nums = pt.split(separator: ",").compactMap { Double($0) }
                    if nums.count == 2 {
                        grassPositions.append(CGPoint(x: nums[0], y: nums[1]))
                    }
                }
            } else if trimmed.hasPrefix("START") {
                // START x,y
                let comps = trimmed.components(separatedBy: " ")
                if comps.count == 2, let xy = comps.last?.split(separator: ","),
                   xy.count == 2, let x = Double(xy[0]), let y = Double(xy[1]) {
                    start = CGPoint(x: x, y: y)
                }
            } else if trimmed.hasPrefix("FINISH") {
                // FINISH x,y
                let comps = trimmed.components(separatedBy: " ")
                if comps.count == 2, let xy = comps.last?.split(separator: ","),
                   xy.count == 2, let x = Double(xy[0]), let y = Double(xy[1]) {
                    finish = CGPoint(x: x, y: y)
                }
            }
        }
        
        return LevelData(
            wallRects: wallRects,
            checkpointPositions: checkpointPositions,
            vortexPositions: vortexPositions,
            oilPositions: oilPositions,
            grassPositions: grassPositions,
            start: start,
            finish: finish
        )
    }
}
