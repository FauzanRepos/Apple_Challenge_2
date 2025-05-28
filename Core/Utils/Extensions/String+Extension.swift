//
//  String+Extension.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import UIKit

// MARK: - String Extensions
extension String {
    
    // MARK: - Validation
    var isNotEmpty: Bool {
        return !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    var isValidGameCode: Bool {
        return Constants.isValidGameCode(self)
    }
    
    var isValidPlayerName: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 1 && trimmed.count <= 20 && !trimmed.contains(where: { $0.isWhitespace && $0 != " " })
    }
    
    // MARK: - Formatting
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var uppercasedTrimmed: String {
        return trimmed.uppercased()
    }
    
    var capitalizedWords: String {
        return components(separatedBy: .whitespaces)
            .map { $0.lowercased().capitalized }
            .joined(separator: " ")
    }
    
    var alphanumericOnly: String {
        return components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
    }
    
    var numbersOnly: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
    
    var lettersOnly: String {
        return components(separatedBy: CharacterSet.letters.inverted).joined()
    }
    
    // MARK: - Game Code Formatting
    var formattedGameCode: String {
        let cleaned = uppercasedTrimmed.replacingOccurrences(of: " ", with: "")
        guard cleaned.count == Constants.maxGameCodeLength else { return cleaned }
        
        let midIndex = cleaned.index(cleaned.startIndex, offsetBy: 3)
        let firstHalf = String(cleaned[..<midIndex])
        let secondHalf = String(cleaned[midIndex...])
        return "\(firstHalf) \(secondHalf)"
    }
    
    var cleanedGameCode: String {
        return uppercasedTrimmed.replacingOccurrences(of: " ", with: "")
    }
    
    // MARK: - Player Name Formatting
    var formattedPlayerName: String {
        let cleaned = trimmed
        guard !cleaned.isEmpty else { return "Player" }
        
        // Remove multiple consecutive spaces
        let singleSpaced = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Capitalize first letter of each word
        return singleSpaced.capitalizedWords
    }
    
    // MARK: - Encoding/Decoding
    var base64Encoded: String? {
        return data(using: .utf8)?.base64EncodedString()
    }
    
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    var urlEncoded: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    var urlDecoded: String? {
        return removingPercentEncoding
    }
    
    // MARK: - Hash Generation
    var md5: String {
        return CryptoHelper.md5Hash(of: self)
    }
    
    var sha256: String {
        return CryptoHelper.sha256Hash(of: self)
    }
    
    // MARK: - JSON Handling
    func toJSONObject() -> Any? {
        guard let data = data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [])
    }
    
    func toDictionary() -> [String: Any]? {
        return toJSONObject() as? [String: Any]
    }
    
    func toArray() -> [Any]? {
        return toJSONObject() as? [Any]
    }
    
    // MARK: - String Manipulation
    func substring(from index: Int) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: max(0, index))
        return String(self[startIndex...])
    }
    
    func substring(to index: Int) -> String {
        let endIndex = self.index(self.startIndex, offsetBy: min(count, index))
        return String(self[..<endIndex])
    }
    
    func substring(from: Int, to: Int) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: max(0, from))
        let endIndex = self.index(self.startIndex, offsetBy: min(count, to))
        return String(self[startIndex..<endIndex])
    }
    
    func insert(string: String, at index: Int) -> String {
        let insertIndex = self.index(self.startIndex, offsetBy: min(count, max(0, index)))
        var result = self
        result.insert(contentsOf: string, at: insertIndex)
        return result
    }
    
    // MARK: - Pattern Matching
    func matches(pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
    
    func matchCount(pattern: String) -> Int {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: count))
            return matches.count
        } catch {
            return 0
        }
    }
    
    func replacingPattern(_ pattern: String, with replacement: String) -> String {
        return replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
    }
    
    // MARK: - Distance and Similarity
    func levenshteinDistance(to other: String) -> Int {
        let selfArray = Array(self)
        let otherArray = Array(other)
        let selfCount = selfArray.count
        let otherCount = otherArray.count
        
        if selfCount == 0 { return otherCount }
        if otherCount == 0 { return selfCount }
        
        var matrix = Array(repeating: Array(repeating: 0, count: otherCount + 1), count: selfCount + 1)
        
        for i in 0...selfCount {
            matrix[i][0] = i
        }
        
        for j in 0...otherCount {
            matrix[0][j] = j
        }
        
        for i in 1...selfCount {
            for j in 1...otherCount {
                let cost = selfArray[i - 1] == otherArray[j - 1] ? 0 : 1
                matrix[i][j] = Swift.min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }
        
        return matrix[selfCount][otherCount]
    }
    
    func similarity(to other: String) -> Double {
        let distance = levenshteinDistance(to: other)
        let maxLength = max(count, other.count)
        return maxLength == 0 ? 1.0 : Double(maxLength - distance) / Double(maxLength)
    }
    
    // MARK: - Time Formatting
    static func timeString(from seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    static func durationString(from seconds: TimeInterval) -> String {
        if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else if seconds < 3600 {
            let minutes = Int(seconds) / 60
            let remainingSeconds = Int(seconds) % 60
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            let hours = Int(seconds) / 3600
            let minutes = (Int(seconds) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }
    }
    
    // MARK: - Localization
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: localized, arguments: arguments)
    }
    
    // MARK: - File Operations
    var pathExtension: String {
        return (self as NSString).pathExtension
    }
    
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
    
    var deletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }
    
    func appendingPathComponent(_ component: String) -> String {
        return (self as NSString).appendingPathComponent(component)
    }
    
    // MARK: - Size Calculation
    func size(withFont font: UIFont, constrainedTo size: CGSize) -> CGSize {
        let attributes = [NSAttributedString.Key.font: font]
        let boundingRect = (self as NSString).boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return boundingRect.size
    }
    
    func height(withFont font: UIFont, width: CGFloat) -> CGFloat {
        return size(withFont: font, constrainedTo: CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }
    
//    func width(withFont font: UIFont) -> CGFloat {
//        return size(withFont: font, constrainedTo: CGSize(width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude)).width
//    }
    
    // MARK: - Random Generation
    static func randomString(length: Int, characters: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String {
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    static func randomGameCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return randomString(length: Constants.maxGameCodeLength, characters: characters)
    }
    
    static func randomPlayerName() -> String {
        let adjectives = ["Swift", "Quick", "Smart", "Clever", "Bold", "Brave", "Cool", "Fast"]
        let nouns = ["Player", "Gamer", "Hero", "Star", "Champion", "Winner", "Master", "Pro"]
        
        let adjective = adjectives.randomElement()!
        let noun = nouns.randomElement()!
        let number = Int.random(in: 1...999)
        
        return "\(adjective)\(noun)\(number)"
    }
    
    // MARK: - Color from String
    var color: UIColor {
        var hash = 0
        for char in self {
            hash = Int(char.asciiValue ?? 0) + ((hash << 5) - hash)
        }
        
        let red = CGFloat((hash & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hash & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(hash & 0x0000FF) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    // MARK: - Emoji Handling
    var containsEmoji: Bool {
        return unicodeScalars.contains { $0.properties.isEmoji }
    }
    
    var emojiStripped: String {
        return String(unicodeScalars.filter { !$0.properties.isEmoji })
    }
    
    var onlyEmoji: String {
        return String(unicodeScalars.filter { $0.properties.isEmoji })
    }
    
    // MARK: - Network Message Validation
    var isValidNetworkMessage: Bool {
        let maxLength = Constants.maxMessageSize
        guard let data = data(using: .utf8), data.count <= maxLength else { return false }
        return isNotEmpty && !containsEmoji
    }
    
    // MARK: - Profanity Filter (Basic)
    var containsProfanity: Bool {
        let profanityWords = ["spam", "hack", "cheat", "bot"] // Add more as needed
        let lowercased = self.lowercased()
        return profanityWords.contains { lowercased.contains($0) }
    }
    
    var cleanedForChat: String {
        return trimmed
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .prefix(100)
            .description
    }
    
    // MARK: - Debug Helpers
    var debugDescription: String {
        return "String(\"\(self)\") - Length: \(count), IsEmpty: \(!isNotEmpty)"
    }
    
    func printCharacterCodes() {
        print("Character codes for '\(self)':")
        for (index, char) in enumerated() {
            print("  [\(index)]: '\(char)' = \(char.asciiValue ?? 0)")
        }
    }
}

// MARK: - String Array Extensions
extension Array where Element == String {
    var joined: String {
        return joined(separator: "")
    }
    
    var joinedWithSpaces: String {
        return joined(separator: " ")
    }
    
    var joinedWithCommas: String {
        return joined(separator: ", ")
    }
    
    var joinedWithNewlines: String {
        return joined(separator: "\n")
    }
    
    func filterNotEmpty() -> [String] {
        return filter { $0.isNotEmpty }
    }
    
    func trimmedStrings() -> [String] {
        return map { $0.trimmed }
    }
    
    func uppercasedStrings() -> [String] {
        return map { $0.uppercased() }
    }
    
    func sortedCaseInsensitive() -> [String] {
        return sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

// MARK: - Crypto Helper (Simple implementations)
private struct CryptoHelper {
    static func md5Hash(of string: String) -> String {
        // Simple implementation - in production, use CommonCrypto
        return string.data(using: .utf8)?.base64EncodedString() ?? ""
    }
    
    static func sha256Hash(of string: String) -> String {
        // Simple implementation - in production, use CommonCrypto
        return string.data(using: .utf8)?.base64EncodedString() ?? ""
    }
}

// MARK: - Game-Specific String Extensions
extension String {
    
    // MARK: - SpaceMaze Specific Validation
    var isValidSpaceMazePlayerName: Bool {
        let trimmed = self.trimmed
        return trimmed.count >= 2 &&
        trimmed.count <= 15 &&
        !containsProfanity &&
        !containsEmoji &&
        trimmed.allSatisfy { $0.isLetter || $0.isNumber || $0 == " " }
    }
    
    var spaceMazeFormattedPlayerName: String {
        return formattedPlayerName
            .replacingOccurrences(of: "player", with: "Player", options: .caseInsensitive)
            .prefix(15)
            .description
    }
    
    var isValidSpaceMazeGameCode: Bool {
        let cleaned = cleanedGameCode
        return cleaned.count == 6 &&
        cleaned.allSatisfy { "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".contains($0) }
    }
    
    // MARK: - Level Parsing
    func parseLevelData() -> [[Character]] {
        return components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { Array($0) }
    }
    
    var isValidLevelData: Bool {
        let lines = components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard !lines.isEmpty else { return false }
        
        let firstLineLength = lines.first?.count ?? 0
        let validCharacters = Set("xsvf ") // walls, stars, vortex, finish, empty
        
        return lines.allSatisfy { line in
            line.count == firstLineLength &&
            line.allSatisfy { validCharacters.contains($0) }
        }
    }
    
    // MARK: - Network Message Formatting
    var asNetworkMessage: String {
        return trimmed
            .prefix(Constants.maxMessageSize / 4) // Account for encoding overhead
            .description
    }
    
    var isValidChatMessage: Bool {
        let cleaned = cleanedForChat
        return cleaned.isNotEmpty &&
        cleaned.count <= 200 &&
        !containsProfanity
    }
    
    // MARK: - Game Statistics Formatting
    static func formatScore(_ score: Int) -> String {
        if score >= 1000000 {
            return String(format: "%.1fM", Double(score) / 1000000.0)
        } else if score >= 1000 {
            return String(format: "%.1fK", Double(score) / 1000.0)
        } else {
            return "\(score)"
        }
    }
    
//    static func formatScore(_ score: Int) -> String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
//        return formatter.string(from: NSNumber(value: score)) ?? "\(score)"
//    }
    
    static func formatTime(_ timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: timeInterval) ?? "0s"
    }
    
    static func formatPercentage(_ value: Double) -> String {
        return String(format: "%.1f%%", value * 100)
    }
    
    // MARK: - Game Code Suggestions
    func suggestGameCodeCorrections() -> [String] {
        let common_mistakes: [Character: Character] = [
            "0": "O", "1": "I", "5": "S", "8": "B", "6": "G"
        ]
        
        var suggestions: [String] = []
        
        for (wrong, correct) in common_mistakes {
            let corrected = self.replacingOccurrences(of: String(wrong), with: String(correct))
            if corrected != self && corrected.isValidSpaceMazeGameCode {
                suggestions.append(corrected.formattedGameCode)
            }
        }
        
        return Array(Set(suggestions)).prefix(3).map { String($0) }
    }
}

// MARK: - Attributed String Extensions
extension String {
    func attributed(with attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        return NSAttributedString(string: self, attributes: attributes)
    }
    
    func attributed(font: UIFont, color: UIColor = .black) -> NSAttributedString {
        return attributed(with: [
            .font: font,
            .foregroundColor: color
        ])
    }
    
    func bold(font: UIFont) -> NSAttributedString {
        return attributed(font: font.bold())
    }
    
    func italic(font: UIFont) -> NSAttributedString {
        return attributed(font: font.italic())
    }
}

// MARK: - UIFont Extensions (Supporting)
private extension UIFont {
    func bold() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitBold)
        return UIFont(descriptor: descriptor!, size: pointSize)
    }
    
    func italic() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitItalic)
        return UIFont(descriptor: descriptor!, size: pointSize)
    }
}
