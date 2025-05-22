//
//  GameViewController.swift
//  Project26
//
//  Created by SpaceMaze-ADA_Team_8 on 19/08/2016.
//  Copyright © 2016 Paul Hudson. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
//            // Load the SKScene from 'GameScene.sks'
//            if let scene = SKScene(fileNamed: "GameScene") {
//                // Set the scale mode to scale to fit the window
//                if UIDevice.current.userInterfaceIdiom == .pad {
//                    scene.scaleMode = .aspectFill
//                } else {
//                    scene.scaleMode = .aspectFit
//                }
//                
//                // Present the scene
//                view.presentScene(scene)
//            }
            
            let scene = GameScene(size: CGSize(width: 768, height: 1088))
            scene.scaleMode = .aspectFit  // or .aspectFill, etc.
            view.presentScene(scene)


            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }
//
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        // force landscape on phones, but allow everything on iPad
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            return [.landscapeLeft, .landscapeRight]
//        } else {
//            return .all
//        }
//    }
    
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        // force portrait on phones
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            return [.portrait]
//        } else {
//            return .all
//        }
//    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // force portrait on phones
            return [.portrait]
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
