//
//  ValidationHelper.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

// MARK: - Import for Core Motion
import CoreMotion
import Foundation
import UIKit

class ValidationHelper {
    
    // MARK: - Game Code Validation
    static func validateGameCode(_ code: String) -> ValidationResult {
        let cleanCode = code.uppercasedTrimmed.replacingOccurrences(of: " ", with: "")
        
        // Check length
        guard cleanCode.count == Constants.maxGameCodeLength else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Game code must be exactly \(Constants.maxGameCodeLength) characters long",
                suggestions: []
            )
        }
        
        // Check valid characters
        let validCharacters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let invalidCharacters = Set(cleanCode).subtracting(Set(validCharacters))
        
        if !invalidCharacters.isEmpty {
            let suggestions = generateGameCodeSuggestions(for: cleanCode)
            return ValidationResult(
                isValid: false,
                errorMessage: "Game code contains invalid characters: \(invalidCharacters.map(String.init).joined(separator: ", "))",
                suggestions: suggestions
            )
        }
        
        // Check for confusing characters
        let confusingCharacters = "IO01"
        let hasConfusingChars = cleanCode.contains { confusingCharacters.contains($0) }
        
        if hasConfusingChars {
            let suggestions = generateGameCodeSuggestions(for: cleanCode)
            return ValidationResult(
                isValid: false,
                errorMessage: "Game code contains confusing characters (I, O, 0, 1)",
                suggestions: suggestions
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    private static func generateGameCodeSuggestions(for code: String) -> [String] {
        let corrections: [Character: Character] = [
            "0": "O", "1": "I", "5": "S", "8": "B", "6": "G", "I": "J", "O": "Q"
        ]
        
        var suggestions: Set<String> = []
        
        for (wrong, correct) in corrections {
            let corrected = code.replacingOccurrences(of: String(wrong), with: String(correct))
            if corrected != code && Constants.isValidGameCode(corrected) {
                suggestions.insert(corrected)
            }
        }
        
        return Array(suggestions.prefix(3))
    }
    
    // MARK: - Player Name Validation
    static func validatePlayerName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmed
        
        // Check if empty
        guard !trimmedName.isEmpty else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Player name cannot be empty",
                suggestions: ["Player", "Gamer", "Hero"]
            )
        }
        
        // Check length
        guard trimmedName.count >= 2 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Player name must be at least 2 characters long",
                suggestions: [trimmedName + "1", trimmedName + "er", "Player"]
            )
        }
        
        guard trimmedName.count <= 20 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Player name must be 20 characters or less",
                suggestions: [String(trimmedName.prefix(20))]
            )
        }
        
        // Check for valid characters
        let validCharacterSet = CharacterSet.alphanumerics.union(.whitespaces)
        guard trimmedName.unicodeScalars.allSatisfy({ validCharacterSet.contains($0) }) else {
            let cleanedName = String(trimmedName.unicodeScalars.filter { validCharacterSet.contains($0) })
            return ValidationResult(
                isValid: false,
                errorMessage: "Player name can only contain letters, numbers, and spaces",
                suggestions: [cleanedName.isEmpty ? "Player" : cleanedName]
            )
        }
        
        // Check for profanity
        if containsProfanity(trimmedName) {
            return ValidationResult(
                isValid: false,
                errorMessage: "Player name contains inappropriate content",
                suggestions: generateCleanNameSuggestions()
            )
        }
        
        // Check for excessive spaces
        let spaceCleaned = trimmedName.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        if spaceCleaned != trimmedName {
            return ValidationResult(
                isValid: false,
                errorMessage: "Player name has excessive spaces",
                suggestions: [spaceCleaned]
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    private static func containsProfanity(_ text: String) -> Bool {
        let profanityList = ["spam", "hack", "cheat", "bot", "test"] // Add more as needed
        let lowercased = text.lowercased()
        return profanityList.contains { lowercased.contains($0) }
    }
    
    private static func generateCleanNameSuggestions() -> [String] {
        let adjectives = ["Cool", "Fast", "Smart", "Bold", "Swift"]
        let nouns = ["Player", "Gamer", "Hero", "Star", "Pro"]
        
        return (0..<3).map { _ in
            let adjective = adjectives.randomElement()!
            let noun = nouns.randomElement()!
            let number = Int.random(in: 10...99)
            return "\(adjective)\(noun)\(number)"
        }
    }
    
    // MARK: - Network Message Validation
    static func validateNetworkMessage(_ message: String) -> ValidationResult {
        let trimmedMessage = message.trimmed
        
        // Check if empty
        guard !trimmedMessage.isEmpty else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Message cannot be empty",
                suggestions: []
            )
        }
        
        // Check length
        guard trimmedMessage.count <= 500 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Message is too long (max 500 characters)",
                suggestions: [String(trimmedMessage.prefix(500))]
            )
        }
        
        // Check for valid characters (no control chars except \n)
        let invalidChars = trimmedMessage.unicodeScalars.filter {($0.value < 32 && $0 != "\n") || $0.value == 127}
        guard invalidChars.isEmpty else {
            let cleanedMessage = String(
                trimmedMessage.unicodeScalars.filter {
                    !($0.value < 32 && $0 != "\n") && $0.value != 127
                }
            )
            return ValidationResult(
                isValid: false,
                errorMessage: "Message contains invalid control characters",
                suggestions: [cleanedMessage]
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    // MARK: - Position Validation
    static func validatePosition(_ position: CGPoint, bounds: CGRect) -> ValidationResult {
        guard position.isValid else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Position contains invalid coordinates (NaN or Infinite)",
                suggestions: []
            )
        }
        
        guard bounds.contains(position) else {
            let clampedPosition = position.clamped(to: bounds)
            return ValidationResult(
                isValid: false,
                errorMessage: "Position is outside valid bounds",
                suggestions: [],
                correctedValue: clampedPosition
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    // MARK: - Velocity Validation
    static func validateVelocity(_ velocity: CGVector, maxSpeed: CGFloat = Constants.playerMaxVelocity) -> ValidationResult {
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        
        guard !velocity.dx.isNaN && !velocity.dy.isNaN &&
                !velocity.dx.isInfinite && !velocity.dy.isInfinite else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Velocity contains invalid values (NaN or Infinite)",
                suggestions: [],
                correctedValue: CGVector.zero
            )
        }
        
        guard speed <= maxSpeed else {
            let normalizedVelocity = CGVector(
                dx: velocity.dx / speed * maxSpeed,
                dy: velocity.dy / speed * maxSpeed
            )
            return ValidationResult(
                isValid: false,
                errorMessage: "Velocity exceeds maximum speed limit",
                suggestions: [],
                correctedValue: normalizedVelocity
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    // MARK: - Level Data Validation
    static func validateLevelData(_ levelData: String) -> ValidationResult {
        let lines = levelData.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Level data is empty",
                suggestions: []
            )
        }
        
        // Check minimum size
        guard lines.count >= 5 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Level must be at least 5 rows high",
                suggestions: []
            )
        }
        
        let firstLineLength = lines.first?.count ?? 0
        guard firstLineLength >= 5 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Level must be at least 5 columns wide",
                suggestions: []
            )
        }
        
        // Check consistent width
        for (index, line) in lines.enumerated() {
            guard line.count == firstLineLength else {
                return ValidationResult(
                    isValid: false,
                    errorMessage: "Row \(index + 1) has inconsistent width",
                    suggestions: []
                )
            }
        }
        
        // Check valid characters
        let validCharacters = Set("xsvf o") // walls, stars, vortex, finish, oil, grass, empty
        var hasFinish = false
        /* var hasPlayer = false */
        
        for (rowIndex, line) in lines.enumerated() {
            for (colIndex, char) in line.enumerated() {
                guard validCharacters.contains(char) else {
                    return ValidationResult(
                        isValid: false,
                        errorMessage: "Invalid character '\(char)' at row \(rowIndex + 1), column \(colIndex + 1)",
                        suggestions: []
                    )
                }
                
                if char == "f" { hasFinish = true }
                /* if char == " " { hasPlayer = true } */
            }
        }
        
        // Check required elements
        guard hasFinish else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Level must have at least one finish point (f)",
                suggestions: []
            )
        }
        
        // Check border walls
        let topRow = lines.first!
        let bottomRow = lines.last!
        
        let hasTopWall = topRow.allSatisfy { $0 == "x" }
        let hasBottomWall = bottomRow.allSatisfy { $0 == "x" }
        let hasLeftWall = lines.allSatisfy { $0.first == "x" }
        let hasRightWall = lines.allSatisfy { $0.last == "x" }
        
        if !hasTopWall || !hasBottomWall || !hasLeftWall || !hasRightWall {
            return ValidationResult(
                isValid: false,
                errorMessage: "Level must be completely surrounded by walls (x)",
                suggestions: []
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    // MARK: - Connection Validation
    static func validateConnectionState(_ playerCount: Int) -> ValidationResult {
        guard playerCount >= Constants.minPlayersToStart else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Need at least \(Constants.minPlayersToStart) players to start",
                suggestions: []
            )
        }
        
        guard playerCount <= Constants.maxPlayersPerRoom else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Too many players (max \(Constants.maxPlayersPerRoom))",
                suggestions: []
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    // MARK: - JSON Validation
    static func validateJSONData(_ jsonData: Data) -> ValidationResult {
        do {
            _ = try JSONSerialization.jsonObject(with: jsonData, options: [])
            return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
        } catch {
            return ValidationResult(
                isValid: false,
                errorMessage: "Invalid JSON format: \(error.localizedDescription)",
                suggestions: []
            )
        }
    }
    
    static func validateJSONString(_ jsonString: String) -> ValidationResult {
        guard let jsonData = jsonString.data(using: .utf8) else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Cannot convert string to UTF-8 data",
                suggestions: []
            )
        }
        
        return validateJSONData(jsonData)
    }
    
    // MARK: - Input Sanitization
    static func sanitizePlayerName(_ name: String) -> String {
        let trimmed = name.trimmed
        
        // Remove invalid characters
        let validCharacterSet = CharacterSet.alphanumerics.union(.whitespaces)
        let sanitized = String(trimmed.unicodeScalars.filter { validCharacterSet.contains($0) })
        
        // Remove excessive spaces
        let spaceCleaned = sanitized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Truncate if too long
        let truncated = String(spaceCleaned.prefix(20))
        
        // Ensure minimum length
        return truncated.isEmpty ? "Player" : truncated
    }
    
    static func sanitizeGameCode(_ code: String) -> String {
        let cleaned = code.uppercasedTrimmed.replacingOccurrences(of: " ", with: "")
        let validCharacters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let sanitized = String(cleaned.filter { validCharacters.contains($0) })
        return String(sanitized.prefix(Constants.maxGameCodeLength))
    }
    
    static func sanitizeChatMessage(_ message: String) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // ✅ Remove all control characters except newline (\n)
        let controlCleaned = String(
            trimmed.unicodeScalars.filter { scalar in
                // ASCII control characters range is 0...31, and 127 (DEL)
                // Keep newline (\n = 10), remove everything else in control range
                (scalar.value >= 32 && scalar.value != 127) || scalar == "\n"
            }
        )
        
        // Truncate if too long
        let truncated = String(controlCleaned.prefix(200))
        return truncated
    }
    
    // MARK: - Range Validation
    static func validateIntegerRange(_ value: Int, min: Int, max: Int, fieldName: String) -> ValidationResult {
        guard value >= min else {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) must be at least \(min)",
                suggestions: [],
                correctedValue: min
            )
        }
        
        guard value <= max else {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) must be at most \(max)",
                suggestions: [],
                correctedValue: max
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    static func validateFloatRange(_ value: CGFloat, min: CGFloat, max: CGFloat, fieldName: String) -> ValidationResult {
        guard !value.isNaN && !value.isInfinite else {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) contains invalid value (NaN or Infinite)",
                suggestions: [],
                correctedValue: (min + max) / 2
            )
        }
        
        guard value >= min else {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) must be at least \(min)",
                suggestions: [],
                correctedValue: min
            )
        }
        
        guard value <= max else {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) must be at most \(max)",
                suggestions: [],
                correctedValue: max
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    // MARK: - Time Validation
    static func validateTimestamp(_ timestamp: TimeInterval) -> ValidationResult {
        let now = Date().timeIntervalSince1970
        let maxAge: TimeInterval = 300 // 5 minutes
        let maxFuture: TimeInterval = 60 // 1 minute
        
        guard timestamp > now - maxAge else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Timestamp is too old (more than 5 minutes ago)",
                suggestions: [],
                correctedValue: now
            )
        }
        
        guard timestamp < now + maxFuture else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Timestamp is too far in the future",
                suggestions: [],
                correctedValue: now
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    // MARK: - File Validation
    static func validateImageFile(_ imageData: Data) -> ValidationResult {
        // Check minimum size
        guard imageData.count >= 100 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Image file is too small",
                suggestions: []
            )
        }
        
        // Check maximum size (10MB)
        guard imageData.count <= 10 * 1024 * 1024 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Image file is too large (max 10MB)",
                suggestions: []
            )
        }
        
        // Check if it's a valid image format
        guard UIImage(data: imageData) != nil else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Invalid image format",
                suggestions: []
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    // MARK: - Color Validation
    static func validateColor(_ color: UIColor) -> ValidationResult {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Unable to extract color components",
                suggestions: []
            )
        }
        
        let components = [red, green, blue, alpha]
        guard components.allSatisfy({ $0 >= 0 && $0 <= 1 && !$0.isNaN && !$0.isInfinite }) else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Color components contain invalid values",
                suggestions: []
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    // MARK: - Device Validation
    static func validateDeviceCapabilities() -> ValidationResult {
        let device = UIDevice.current
        
        // Check if device supports accelerometer
        let motionManager = CMMotionManager()
        guard motionManager.isAccelerometerAvailable else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Device does not support accelerometer",
                suggestions: []
            )
        }
        
        // Check iOS version
        let minimumVersion = "13.0"
        if device.systemVersion.compare(minimumVersion, options: .numeric) == .orderedAscending {
            return ValidationResult(
                isValid: false,
                errorMessage: "iOS \(minimumVersion) or later is required",
                suggestions: []
            )
        }
        
        // Check memory (rough estimate)
        let processInfo = ProcessInfo.processInfo
        if processInfo.physicalMemory < 1 * 1024 * 1024 * 1024 { // Less than 1GB
            return ValidationResult(
                isValid: false,
                errorMessage: "Device may not have sufficient memory",
                suggestions: []
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    // MARK: - Batch Validation
    static func validateMultiple<T>(_ items: [T], validator: (T) -> ValidationResult) -> BatchValidationResult {
        var errors: [ValidationError] = []
        var validCount = 0
        
        for (index, item) in items.enumerated() {
            let result = validator(item)
            if result.isValid {
                validCount += 1
            } else {
                errors.append(ValidationError(
                    index: index,
                    item: item,
                    message: result.errorMessage ?? "Unknown error",
                    suggestions: result.suggestions
                ))
            }
        }
        
        return BatchValidationResult(
            totalItems: items.count,
            validItems: validCount,
            errors: errors,
            isValid: errors.isEmpty
        )
    }
    
    // MARK: - Custom Validation Rules
    static func validateWithCustomRules<T>(_ value: T, rules: [ValidationRule<T>]) -> ValidationResult {
        for rule in rules {
            let result = rule.validate(value)
            if !result.isValid {
                return result
            }
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    // MARK: - Common Validation Patterns
    static func validateEmail(_ email: String) -> ValidationResult {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Invalid email format",
                suggestions: []
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    static func validateURL(_ urlString: String) -> ValidationResult {
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Invalid URL format",
                suggestions: []
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
    
    // MARK: - Debug Validation
    static func validateDebugInfo(_ info: [String: Any]) -> ValidationResult {
        let requiredKeys = ["version", "platform", "timestamp"]
        let missingKeys = requiredKeys.filter { info[$0] == nil }
        
        guard missingKeys.isEmpty else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Missing required debug info keys: \(missingKeys.joined(separator: ", "))",
                suggestions: []
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil, suggestions: [])
    }
}

// MARK: - Supporting Data Types
struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
    let suggestions: [String]
    let correctedValue: Any?
    
    init(isValid: Bool, errorMessage: String?, suggestions: [String], correctedValue: Any? = nil) {
        self.isValid = isValid
        self.errorMessage = errorMessage
        self.suggestions = suggestions
        self.correctedValue = correctedValue
    }
}

struct ValidationError {
    let index: Int
    let item: Any
    let message: String
    let suggestions: [String]
}

struct BatchValidationResult {
    let totalItems: Int
    let validItems: Int
    let errors: [ValidationError]
    let isValid: Bool
    
    var errorCount: Int {
        return errors.count
    }
    
    var successRate: Double {
        return totalItems > 0 ? Double(validItems) / Double(totalItems) : 0.0
    }
}

struct ValidationRule<T> {
    let name: String
    let validate: (T) -> ValidationResult
    
    init(name: String, validate: @escaping (T) -> ValidationResult) {
        self.name = name
        self.validate = validate
    }
}

// MARK: - Predefined Validation Rules
extension ValidationRule where T == String {
    static var notEmpty: ValidationRule<String> {
        return ValidationRule(name: "NotEmpty") { value in
            return ValidationResult(
                isValid: !value.trimmed.isEmpty,
                errorMessage: value.trimmed.isEmpty ? "Value cannot be empty" : nil,
                suggestions: []
            )
        }
    }
    
    static func minLength(_ minLength: Int) -> ValidationRule<String> {
        return ValidationRule(name: "MinLength") { value in
            return ValidationResult(
                isValid: value.count >= minLength,
                errorMessage: value.count < minLength ? "Must be at least \(minLength) characters" : nil,
                suggestions: []
            )
        }
    }
    
    static func maxLength(_ maxLength: Int) -> ValidationRule<String> {
        return ValidationRule(name: "MaxLength") { value in
            return ValidationResult(
                isValid: value.count <= maxLength,
                errorMessage: value.count > maxLength ? "Must be at most \(maxLength) characters" : nil,
                suggestions: value.count > maxLength ? [String(value.prefix(maxLength))] : []
            )
        }
    }
}

extension ValidationRule where T == Int {
    static func range(_ min: Int, _ max: Int) -> ValidationRule<Int> {
        return ValidationRule(name: "Range") { value in
            let isValid = value >= min && value <= max
            var errorMessage: String?
            var correctedValue: Any?
            
            if value < min {
                errorMessage = "Value must be at least \(min)"
                correctedValue = min
            } else if value > max {
                errorMessage = "Value must be at most \(max)"
                correctedValue = max
            }
            
            return ValidationResult(
                isValid: isValid,
                errorMessage: errorMessage,
                suggestions: [],
                correctedValue: correctedValue
            )
        }
    }
}

// MARK: - Common Validation Presets
extension ValidationHelper {
    static let gameCodeRules: [ValidationRule<String>] = [
        .notEmpty,
        .minLength(Constants.maxGameCodeLength),
        .maxLength(Constants.maxGameCodeLength)
    ]
    
    static let playerNameRules: [ValidationRule<String>] = [
        .notEmpty,
        .minLength(2),
        .maxLength(20)
    ]
    
    static let playerCountRange = ValidationRule<Int>.range(
        Constants.minPlayersToStart,
        Constants.maxPlayersPerRoom
    )
}
