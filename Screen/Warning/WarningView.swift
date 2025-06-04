import SwiftUI

struct WarningView: View {
    @EnvironmentObject var sessionState: SessionState
    @StateObject private var audioManager = AudioManager.shared
    
    var body: some View {
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
                        // WiFi and Bluetooth icons
                        HStack(spacing: 20) {
                            Image("WIFI_Icon")
                                .resizable()
                                .frame(width: 24, height: 24)
                            Image("BT_Icon")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        .padding(.top, 60)

                        // Main text content
                        VStack(spacing: 8) {
                            Text("Space Maze is a")
                                .pixelTextStyle()
                            Text("cooperative game played")
                                .pixelTextStyle()
                            Text("with 2 - 4 people in the")
                                .pixelTextStyle()
                            Text("same group.")
                                .pixelTextStyle()
                        }
                        .padding(.top, 40)

                        Text("Each player needs a phone")
                            .pixelTextStyle()
                            .padding(.top, 30)

                        // Tips section
                        VStack(spacing: 8) {
                            Text("Tips: make sure you can")
                                .pixelTextStyle()
                            Text("communicate with fellow")
                                .pixelTextStyle()
                            Text("space crew")
                                .pixelTextStyle()
                        }
                        .padding(.top, 30)

                        // Warning text
                        VStack(spacing: 5) {
                            Text("WARNING: This game")
                                .warningTextStyle()
                            Text("contains flashing lights.")
                                .warningTextStyle()
                        }
                        .padding(.top, 30)

                        Spacer()

                        // Continue button
                        Button(action: {
                            // Start playing background music
                            audioManager.playBGM()
                            // Set warning as seen
                            sessionState.hasSeenWarning = true
                        }) {
                            ZStack {
                                Image("Continue_Button")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 60)

                                Text("CONTINUE")
                                    .pixelTextStyle(color: .green)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }

                // Bottom gray border area
                Rectangle()
                    .fill(Color(red: 0.5, green: 0.5, blue: 0.5))
                    .frame(height: 20)
            }
        }
    }
}
