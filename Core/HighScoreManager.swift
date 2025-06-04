import Foundation
import Combine

struct LevelScore: Codable {
    let level: Int
    let score: Int
    let date: Date
}

class HighScoreManager: ObservableObject {
    static let shared = HighScoreManager()
    private let userDefaults = UserDefaults.standard
    private let highScoresKey = "highScores"
    private let maxScoresPerLevel = 10
    
    @Published private(set) var scores: [LevelScore] = []
    
    private init() {
        // Load scores from UserDefaults when initializing
        scores = loadScores()
    }
    
    // Save a new score
    func saveScore(level: Int, score: Int) {
        let newScore = LevelScore(level: level, score: score, date: Date())
        var allScores = scores
        
        // Add new score
        allScores.append(newScore)
        
        // Sort by level first, then by score (higher scores first), then by date (most recent first)
        allScores.sort { (score1, score2) -> Bool in
            if score1.level == score2.level {
                if score1.score == score2.score {
                    return score1.date > score2.date
                }
                return score1.score > score2.score
            }
            return score1.level > score2.level
        }
        
        // Keep only the top scores for each level
        var filteredScores: [LevelScore] = []
        var currentLevel: Int?
        var scoresForCurrentLevel = 0
        
        for score in allScores {
            if currentLevel != score.level {
                currentLevel = score.level
                scoresForCurrentLevel = 0
            }
            
            if scoresForCurrentLevel < maxScoresPerLevel {
                filteredScores.append(score)
                scoresForCurrentLevel += 1
            }
        }
        
        // Update scores and save to UserDefaults
        scores = filteredScores
        saveScores()
    }
    
    // Load scores from UserDefaults
    private func loadScores() -> [LevelScore] {
        guard let data = userDefaults.data(forKey: highScoresKey) else {
            return []
        }
        
        do {
            let scores = try JSONDecoder().decode([LevelScore].self, from: data)
            return scores
        } catch {
            print("Error loading high scores: \(error)")
            return []
        }
    }
    
    // Save scores to UserDefaults
    private func saveScores() {
        do {
            let data = try JSONEncoder().encode(scores)
            userDefaults.set(data, forKey: highScoresKey)
        } catch {
            print("Error saving high scores: \(error)")
        }
    }
    
    // Clear all high scores
    func clearHighScores() {
        scores = []
        userDefaults.removeObject(forKey: highScoresKey)
    }
    
    // Get high scores for a specific level
    func getHighScores(forLevel level: Int) -> [LevelScore] {
        return scores.filter { (score: LevelScore) -> Bool in
            score.level == level
        }
    }
    
    // Get the highest score for a specific level
    func getHighestScore(forLevel level: Int) -> LevelScore? {
        return scores.first { (score: LevelScore) -> Bool in
            score.level == level
        }
    }
    
    // Get the overall highest score
    func getOverallHighestScore() -> LevelScore? {
        return scores.first
    }
} 