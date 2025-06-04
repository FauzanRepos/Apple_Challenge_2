import SwiftUI

struct HighScoreView: View {
    @Binding var isPresented: Bool
    @StateObject private var highScoreManager = HighScoreManager.shared
    @State private var showClearConfirmation = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            // Content
            VStack(spacing: 20) {
                // Header
                Text("HIGH SCORES")
                    .font(.custom("PressStart2P-Regular", size: 32))
                    .foregroundColor(.green)
                    .padding(.top, 20)
                
                // Score List
                if highScoreManager.scores.isEmpty {
                    VStack {
                        Spacer()
                        Text("No High Scores Yet!")
                            .font(.custom("PressStart2P-Regular", size: 24))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Text("Complete levels to set records")
                            .font(.custom("PressStart2P-Regular", size: 16))
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            // Header Row
                            ScoreRowHeader()
                                .padding(.horizontal)
                                .padding(.bottom, 5)
                            
                            ForEach(highScoreManager.scores, id: \.date) { score in
                                ScoreRow(
                                    levelName: "Level \(score.level) Section \(score.score)",
                                    score: score.score,
                                    date: score.date
                                )
                            }
                        }
                        .padding()
                    }
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }
                
                // Buttons
                HStack(spacing: 20) {
                    // Clear Scores Button
                    if !highScoreManager.scores.isEmpty {
                        Button(action: {
                            showClearConfirmation = true
                        }) {
                            Text("CLEAR")
                                .font(.custom("PressStart2P-Regular", size: 16))
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }
                    
                    // Close Button
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("CLOSE")
                            .font(.custom("PressStart2P-Regular", size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .alert("Clear High Scores?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    highScoreManager.clearHighScores()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}

// MARK: - Score Row Header
struct ScoreRowHeader: View {
    var body: some View {
        HStack {
            Text("LEVEL")
                .foregroundColor(.yellow)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text("SCORE")
                .foregroundColor(.yellow)
                .frame(width: 80, alignment: .trailing)
            
            Text("DATE")
                .foregroundColor(.yellow)
                .frame(width: 80, alignment: .trailing)
        }
        .font(.custom("PressStart2P-Regular", size: 12))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Score Row View
struct ScoreRow: View {
    let levelName: String
    let score: Int
    let date: Date
    
    var body: some View {
        HStack {
            // Level Name
            Text(levelName)
                .foregroundColor(.white)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            // Score
            Text("\(score)")
                .foregroundColor(.white)
                .frame(width: 80, alignment: .trailing)
            
            // Date
            Text(date.formatted(.dateTime.month().day()))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 80, alignment: .trailing)
                .font(.system(size: 14))
        }
        .font(.custom("PressStart2P-Regular", size: 14))
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
        )
    }
} 