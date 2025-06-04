import SwiftUI

struct HomeView: View {
    @State private var showCreateRoomLobby = false
    @State private var showJoinRoomLobby = false
    @State private var showSettings = false
    @State private var showHighScores = false
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var highScoreManager = HighScoreManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(red: 0.2, green: 0.2, blue: 0.2)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Top gray border area
                    Rectangle()
                        .fill(Color(red: 0.5, green: 0.5, blue: 0.5))
                        .frame(height: 20)
                    
                    // Main content area
                    ZStack {
                        // Green background
                        Color(red: 0.2, green: 0.8, blue: 0.2)
                        
                        VStack(spacing: 0) {
                            // High Score section
                            VStack(spacing: 8) {
                                Button(action: {
                                    showHighScores = true
                                }) {
                                    ZStack {
                                        // Score background
                                        Image("Wooden_Board")
                                            .resizable()
                                            .frame(height: 120)
                                        
                                        VStack(spacing: 12) {
                                            Text("High Score")
                                                .pixelTextStyle(color: .yellow)
                                                .padding(.top, 8)
                                            
                                            ZStack {
                                                Rectangle()
                                                    .fill(Color(red: 0.2, green: 0.8, blue: 0.2))
                                                    .frame(height: 40)
                                                
                                                if let topScore = highScoreManager.scores.first {
                                                    Text("Level \(topScore.level) Section \(topScore.score)")
                                                        .pixelTextStyle()
                                                } else {
                                                    Text("No Record")
                                                        .pixelTextStyle()
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.bottom, 8)
                                        }
                                    }
                                }
                                
                                // Score dots
                                HStack(spacing: 20) {
                                    ForEach(0..<6) { _ in
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                            .padding(.top, 40)
                            
                            Spacer()
                            
                            // Character with speech bubble
                            HStack {
                                Image("HQ_Character")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                
                                // Speech bubble
                                ZStack {
                                    Image("PopUp")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 50)
                                    
                                    Text("This is HQ!")
                                        .pixelTextStyle()
                                        .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 40)
                            
                            // Action buttons
                            HStack(spacing: 20) {
                                Button(action: {
                                    showCreateRoomLobby = true
                                }) {
                                    ZStack {
                                        Image("Small_Grey_Button")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 150)
                                        
                                        Text("CREATE\nROOM")
                                            .pixelTextStyle(color: .green)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                
                                Button(action: {
                                    showJoinRoomLobby = true
                                }) {
                                    ZStack {
                                        Image("Small_Grey_Button")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 150)
                                        
                                        Text("JOIN\nROOM")
                                            .pixelTextStyle(color: .green)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                            .padding(.bottom, 40)
                            
                            // Version and About
                            HStack {
                                Text("ver.1.0")
                                    .pixelTextStyle(color: .yellow)
                                    .font(.system(size: 12))
                                
                                Spacer()
                                
                                Button(action: {
                                    showSettings = true
                                }) {
                                    Image("About_Button")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 25)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                        }
                    }
                    
                    // Bottom gray border area
                    Rectangle()
                        .fill(Color(red: 0.5, green: 0.5, blue: 0.5))
                        .frame(height: 20)
                }
            }
            .navigationDestination(isPresented: $showCreateRoomLobby) {
                LobbyView(isHost: true)
            }
            .navigationDestination(isPresented: $showJoinRoomLobby) {
                LobbyView(isHost: false)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showHighScores) {
                HighScoreView(isPresented: $showHighScores)
            }
            .onAppear {
                audioManager.playBGM()
            }
        }
    }
}
