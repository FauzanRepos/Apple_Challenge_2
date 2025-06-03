//
//  GameViewController.swift
//  Space Maze
//
//  Created by SpaceMaze-ADA_Team_8 on 20/05/2025.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI
import SpriteKit

struct GameViewController: UIViewControllerRepresentable {
    @ObservedObject private var gameManager = GameManager.shared
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let skView = SKView()
        
        // Configure SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsPhysics = true
        skView.ignoresSiblingOrder = true
        
        // Configure view to ignore safe areas
        skView.translatesAutoresizingMaskIntoConstraints = false
        controller.view = skView
        
        // Add constraints to fill the entire view
        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            skView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
            skView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor)
        ])
        
        // Create and configure the game scene
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .aspectFill
        
        // Set the GameScene reference in GameManager for camera control
        gameManager.setCurrentGameScene(scene)
        
        skView.presentScene(scene)
        
        // Load level after scene is set up
        DispatchQueue.main.async {
            print("[GameViewController] Loading level before scene creation...")
            self.gameManager.loadLevel(1)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let skView = uiViewController.view as? SKView,
              let scene = skView.scene as? GameScene else { return }
        
        let manager = GameManager.shared
        scene.isPaused = manager.isPaused || manager.resumeCountdownActive
        
        // Handle countdown overlay
        handleCountdownOverlay(in: uiViewController, manager: manager)
    }
    
    private func handleCountdownOverlay(in controller: UIViewController, manager: GameManager) {
        let overlayTag = 12345
        
        if manager.resumeCountdownActive {
            // Remove existing overlay if present
            controller.view.subviews
                .filter { $0.tag == overlayTag }
                .forEach { $0.removeFromSuperview() }
            
            // Create new overlay
            let overlay = ResumeCountdownOverlay(count: manager.resumeCountdownValue)
            let hostingController = UIHostingController(rootView: overlay)
            
            // Configure hosting controller
            hostingController.view.backgroundColor = .clear
            hostingController.view.frame = controller.view.bounds
            hostingController.view.tag = overlayTag
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // Add as child view controller
            controller.addChild(hostingController)
            controller.view.addSubview(hostingController.view)
            hostingController.didMove(toParent: controller)
        } else {
            // Remove overlay when countdown is not active
            if let childController = controller.children.first(where: { $0.view?.tag == overlayTag }) {
                childController.willMove(toParent: nil)
                childController.view.removeFromSuperview()
                childController.removeFromParent()
            }
            
            // Also remove any lingering views with the tag
            controller.view.subviews
                .filter { $0.tag == overlayTag }
                .forEach { $0.removeFromSuperview() }
        }
    }
}
