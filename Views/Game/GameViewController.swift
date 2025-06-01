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
    @ObservedObject private var gameManager = GameManager.shared
    
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
        guard let skView = uiViewController.view as? SKView,
              let scene = skView.scene else { return }
        let manager = GameManager.shared
        scene.isPaused = manager.isPaused || manager.resumeCountdownActive
        
        // Show SwiftUI countdown overlay if needed
        if manager.resumeCountdownActive {
            if let hostingController = uiViewController as? UIHostingController<ResumeCountdownOverlay> {
                hostingController.rootView.count = manager.resumeCountdownValue
            } else {
                let overlay = ResumeCountdownOverlay(count: manager.resumeCountdownValue)
                let hosting = UIHostingController(rootView: overlay)
                hosting.view.backgroundColor = .clear
                hosting.view.frame = uiViewController.view.bounds
                hosting.view.tag = 12345
                uiViewController.view.addSubview(hosting.view)
            }
        } else {
            // Remove overlay if present
            uiViewController.view.subviews
                .filter { $0.tag == 12345 }
                .forEach { $0.removeFromSuperview() }
        }
    }
}
