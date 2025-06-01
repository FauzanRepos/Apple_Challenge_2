//
//  GameViewController.swift
//  Project26
//
//  Created by SpaceMaze-ADA_Team_8 on 20/05/2025.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI
import SpriteKit

struct GameViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let skView = SKView()
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        let controller = UIViewController()
        controller.view = skView
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Optionally respond to SwiftUI state changes (pause, restart, etc.)
    }
}
