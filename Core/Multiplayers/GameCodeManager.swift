//
//  GameCodeManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation

class GameCodeManager {
    
    // MARK: - Constants
    private static let codeLength = 6
    private static let validCharacters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    private static let excludedCharacters = "IO01" // Confusing characters
    
    // Code expiration time (10 minutes)
    static let codeExpirationTime: TimeInterval = 10 * 60
    
    // MARK: - Active Codes Storage
    private static var activeCodes: [String: GameCodeInfo] = [:]
    private static let codesQueue = DispatchQueue(label: "gameCodes", qos: .userInitiated)
    
    // MARK: - Code Generation
    static func generateGameCode() -> String {
        var code: String
        
        repeat {
            code = generateRandomCode()
        } while isCodeInUse(code)
        
        // Store the code as active
        registerCode(code)
        
        print("🎲 Generated game code: \(code)")
        return code
    }
    
    private static func generateRandomCode() -> String {
        return String((0..<codeLength).map { _ in
            validCharacters.randomElement()!
        })
    }
    
    // MARK: - Code Validation
    static func validateCode(_ code: String) -> Bool {
        // Check length
        guard code.count == codeLength else {
            return false
        }
        
        // Check characters
        let codeUppercased = code.uppercased()
        for character in codeUppercased {
            if !validCharacters.contains(character) {
                return false
            }
        }
        
        // Check for excluded confusing characters
        for character in excludedCharacters {
            if codeUppercased.contains(character) {
                return false
            }
        }
        
        return true
    }
    
    static func isValidFormat(_ code: String) -> Bool {
        return validateCode(code)
    }
    
    // MARK: - Code Management
    static func registerCode(_ code: String) {
        codesQueue.async {
            let codeInfo = GameCodeInfo(
                code: code,
                createdAt: Date(),
                isActive: true
            )
            activeCodes[code] = codeInfo
            
            // Clean up expired codes
            cleanupExpiredCodes()
        }
    }
    
    static func isCodeInUse(_ code: String) -> Bool {
        return codesQueue.sync {
            guard let codeInfo = activeCodes[code] else {
                return false
            }
            
            // Check if code has expired
            if codeInfo.isExpired {
                activeCodes.removeValue(forKey: code)
                return false
            }
            
            return codeInfo.isActive
        }
    }
    
    static func activateCode(_ code: String) -> Bool {
        return codesQueue.sync {
            guard validateCode(code) else {
                print("❌ Invalid code format: \(code)")
                return false
            }
            
            guard let codeInfo = activeCodes[code], !codeInfo.isExpired else {
                print("❌ Code not found or expired: \(code)")
                return false
            }
            
            activeCodes[code]?.isActive = true
            print("✅ Code activated: \(code)")
            return true
        }
    }
    
    static func deactivateCode(_ code: String) {
        codesQueue.async {
            activeCodes[code]?.isActive = false
            print("🔒 Code deactivated: \(code)")
        }
    }
    
    static func removeCode(_ code: String) {
        codesQueue.async {
            activeCodes.removeValue(forKey: code)
            print("🗑️ Code removed: \(code)")
        }
    }
    
    // MARK: - Code Information
    static func getCodeInfo(_ code: String) -> GameCodeInfo? {
        return codesQueue.sync {
            return activeCodes[code]
        }
    }
    
    static func getActiveCodesCount() -> Int {
        return codesQueue.sync {
            return activeCodes.values.filter { $0.isActive && !$0.isExpired }.count
        }
    }
    
    static func getAllActiveCodes() -> [String] {
        return codesQueue.sync {
            return activeCodes.compactMap { key, value in
                value.isActive && !value.isExpired ? key : nil
            }
        }
    }
    
    // MARK: - Code Analytics
    static func getCodeStatistics() -> CodeStatistics {
        return codesQueue.sync {
            let allCodes = Array(activeCodes.values)
            let activeCodes = allCodes.filter { $0.isActive && !$0.isExpired }
            let expiredCodes = allCodes.filter { $0.isExpired }
            
            return CodeStatistics(
                totalCodesGenerated: allCodes.count,
                activeCodesCount: activeCodes.count,
                expiredCodesCount: expiredCodes.count,
                averageCodeAge: calculateAverageAge(allCodes)
            )
        }
    }
    
    private static func calculateAverageAge(_ codes: [GameCodeInfo]) -> TimeInterval {
        guard !codes.isEmpty else { return 0 }
        
        let now = Date()
        let totalAge = codes.reduce(0.0) { sum, codeInfo in
            return sum + now.timeIntervalSince(codeInfo.createdAt)
        }
        
        return totalAge / Double(codes.count)
    }
    
    // MARK: - Cleanup
    static func cleanupExpiredCodes() {
        codesQueue.async {
            let beforeCount = activeCodes.count
            activeCodes = activeCodes.filter { _, codeInfo in
                !codeInfo.isExpired
            }
            let afterCount = activeCodes.count
            
            if beforeCount != afterCount {
                print("🧹 Cleaned up \(beforeCount - afterCount) expired codes")
            }
        }
    }
    
    static func cleanupAllCodes() {
        codesQueue.async {
            let count = activeCodes.count
            activeCodes.removeAll()
            print("🧹 Cleaned up all \(count) codes")
        }
    }
    
    // MARK: - Code Formatting
    static func formatCode(_ code: String) -> String {
        let cleanCode = code.uppercased().replacingOccurrences(of: " ", with: "")
        
        // Add spaces for better readability (ABC 123)
        if cleanCode.count == codeLength {
            let midIndex = cleanCode.index(cleanCode.startIndex, offsetBy: 3)
            let firstHalf = String(cleanCode[..<midIndex])
            let secondHalf = String(cleanCode[midIndex...])
            return "\(firstHalf) \(secondHalf)"
        }
        
        return cleanCode
    }
    
    static func cleanCode(_ code: String) -> String {
        return code.uppercased().replacingOccurrences(of: " ", with: "")
    }
    
    // MARK: - Code Similarity Check
    static func findSimilarCodes(_ targetCode: String) -> [String] {
        let cleanTarget = cleanCode(targetCode)
        
        return codesQueue.sync {
            return activeCodes.keys.filter { existingCode in
                let similarity = calculateSimilarity(cleanTarget, existingCode)
                return similarity >= 0.8 && existingCode != cleanTarget
            }
        }
    }
    
    private static func calculateSimilarity(_ code1: String, _ code2: String) -> Double {
        guard code1.count == code2.count else { return 0.0 }
        
        let matches = zip(code1, code2).reduce(0) { count, pair in
            return count + (pair.0 == pair.1 ? 1 : 0)
        }
        
        return Double(matches) / Double(code1.count)
    }
    
    // MARK: - Code Suggestions
    static func suggestCorrections(for invalidCode: String) -> [String] {
        let cleanInvalid = cleanCode(invalidCode)
        var suggestions: [String] = []
        
        // Try common character replacements
        let replacements: [Character: Character] = [
            "0": "O", "1": "I", "5": "S", "8": "B"
        ]
        
        for (wrong, correct) in replacements {
            let corrected = cleanInvalid.replacingOccurrences(of: String(wrong), with: String(correct))
            if validateCode(corrected) && suggestions.count < 3 {
                suggestions.append(formatCode(corrected))
            }
        }
        
        return suggestions
    }
    
    // MARK: - Security Features
    static func isCodeSecure(_ code: String) -> Bool {
        let cleanCode = cleanCode(code)
        
        // Check for patterns that might be easily guessed
        let patterns = [
            "AAAAAA", "ABCDEF", "123456", "QWERTY"
        ]
        
        for pattern in patterns {
            if cleanCode.contains(pattern) {
                return false
            }
        }
        
        // Check for repeated characters
        let uniqueChars = Set(cleanCode)
        if uniqueChars.count < 3 {
            return false
        }
        
        return true
    }
    
    static func generateSecureCode() -> String {
        var code: String
        var attempts = 0
        let maxAttempts = 100
        
        repeat {
            code = generateRandomCode()
            attempts += 1
        } while (!isCodeSecure(code) || isCodeInUse(code)) && attempts < maxAttempts
        
        if attempts >= maxAttempts {
            print("⚠️ Warning: Could not generate secure code after \(maxAttempts) attempts")
        }
        
        registerCode(code)
        return code
    }
}

// MARK: - Supporting Data Types
struct GameCodeInfo {
    let code: String
    let createdAt: Date
    var isActive: Bool
    
    var isExpired: Bool {
        let now = Date()
        return now.timeIntervalSince(createdAt) > GameCodeManager.codeExpirationTime
    }
    
    var timeRemaining: TimeInterval {
        let elapsed = Date().timeIntervalSince(createdAt)
        return max(0, GameCodeManager.codeExpirationTime - elapsed)
    }
    
    var age: TimeInterval {
        return Date().timeIntervalSince(createdAt)
    }
}

struct CodeStatistics {
    let totalCodesGenerated: Int
    let activeCodesCount: Int
    let expiredCodesCount: Int
    let averageCodeAge: TimeInterval
    
    var description: String {
        return """
        Code Statistics:
        - Total Generated: \(totalCodesGenerated)
        - Currently Active: \(activeCodesCount)
        - Expired: \(expiredCodesCount)
        - Average Age: \(Int(averageCodeAge))s
        """
    }
}

// MARK: - Extensions
extension GameCodeManager {
    // Convenience methods for common operations
    static func quickValidateAndFormat(_ input: String) -> (isValid: Bool, formatted: String, suggestions: [String]) {
        let cleanInput = cleanCode(input)
        let isValid = validateCode(cleanInput)
        let formatted = formatCode(cleanInput)
        let suggestions = isValid ? [] : suggestCorrections(for: cleanInput)
        
        return (isValid, formatted, suggestions)
    }
    
    static func isCodeAvailable(_ code: String) -> Bool {
        return validateCode(code) && !isCodeInUse(code)
    }
}

// MARK: - Debug Extensions
extension GameCodeManager {
    static func debugPrintActiveCodes() {
        codesQueue.async {
            print("🔍 Active Game Codes:")
            for (code, info) in activeCodes {
                let status = info.isActive ? "✅" : "❌"
                let age = Int(info.age)
                let remaining = Int(info.timeRemaining)
                print("  \(status) \(code) - Age: \(age)s, Remaining: \(remaining)s")
            }
        }
    }
    
    static func getDebugInfo() -> String {
        let stats = getCodeStatistics()
        return """
        GameCodeManager Debug Info:
        \(stats.description)
        - Code Length: \(codeLength)
        - Valid Characters: \(validCharacters.count)
        - Expiration Time: \(Int(codeExpirationTime/60)) minutes
        """
    }
}
