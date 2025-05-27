//
//  AppDelegate.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import UIKit
import SwiftUI
import MultipeerConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize core managers
        _ = GameManager.shared
        _ = StorageManager.shared
        
        // Set up the main SwiftUI view
        let homeView = NavigationStack {
            HomeView()
        }
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: homeView)
        self.window = window
        window.makeKeyAndVisible()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Pause ongoing tasks, disable timers, invalidate graphics rendering callbacks
        // Games should use this method to pause the game
        GameManager.shared.pauseGame()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers
        // Save game state if needed
        StorageManager.shared.saveGameData()
        
        // Handle multiplayer disconnect gracefully
        MultipeerManager.shared.handleAppDidEnterBackground()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state
        // Undo changes made on entering the background
        MultipeerManager.shared.handleAppWillEnterForeground()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive
        // If the application was previously in the background, optionally refresh the user interface
        GameManager.shared.resumeGame()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate
        // Save data if appropriate
        StorageManager.shared.saveGameData()
        
        // Clean up multiplayer connections
        MultipeerManager.shared.disconnect()
    }
}
