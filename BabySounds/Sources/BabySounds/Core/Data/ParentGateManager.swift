import Foundation
import SwiftUI

// MARK: - ParentGateManager

/// Manages parent gate challenges, contexts, and security features
public enum ParentGateManager {
    // MARK: - Constants

    public static let maxAttempts = 3
    public static let lockoutDuration: TimeInterval = 60 // 1 minute
    public static let challengeTimeout: TimeInterval = 30 // 30 seconds

    // MARK: - Challenge Generation

    /// Generate a challenge based on context
    public static func generateChallenge(for context: ParentGateContext) -> ParentGateChallenge {
        switch context {
        case .notifications, .settings:
            // More challenging for critical settings
            return generateAdvancedChallenge()

        case .paywall, .restore:
            // Standard math for purchasing decisions
            return generateMathChallenge()

        case .externalLink:
            // Reading comprehension for safety
            return generateReadingChallenge()

        case .deleteData:
            // Text input for critical actions
            return generateTextInputChallenge()
        }
    }

    // MARK: - Challenge Types

    private static func generateMathChallenge() -> ParentGateChallenge {
        let operation = Bool.random() ? "addition" : "subtraction"

        if operation == "addition" {
            let a = Int.random(in: 3 ... 9)
            let b = Int.random(in: 2 ... 7)
            let correct = a + b
            let options = generateMathOptions(correct: correct, range: 5 ... 20)

            return ParentGateChallenge(
                type: .mathAddition(a: a, b: b, options: options)
            )
        } else {
            let a = Int.random(in: 8 ... 15)
            let b = Int.random(in: 2 ... 7)
            let correct = a - b
            let options = generateMathOptions(correct: correct, range: 1 ... 15)

            return ParentGateChallenge(
                type: .mathSubtraction(a: a, b: b, options: options)
            )
        }
    }

    private static func generateAdvancedChallenge() -> ParentGateChallenge {
        let challengeTypes = ["math", "time", "reading"]
        let selectedType = challengeTypes.randomElement()!

        switch selectedType {
        case "math":
            return generateMathChallenge()

        case "time":
            return generateTimeChallenge()

        case "reading":
            return generateReadingChallenge()

        default:
            return generateMathChallenge()
        }
    }

    private static func generateTimeChallenge() -> ParentGateChallenge {
        let hour = Int.random(in: 1 ... 12)
        let minute = [0, 15, 30, 45].randomElement()!

        let correctTime = String(format: "%d:%02d", hour, minute)

        // Generate wrong options
        var options = [correctTime]
        while options.count < 4 {
            let wrongHour = Int.random(in: 1 ... 12)
            let wrongMinute = [0, 15, 30, 45].randomElement()!
            let wrongTime = String(format: "%d:%02d", wrongHour, wrongMinute)

            if !options.contains(wrongTime) {
                options.append(wrongTime)
            }
        }

        return ParentGateChallenge(
            type: .timeChallenge(hour: hour, minute: minute, options: options.shuffled())
        )
    }

    private static func generateReadingChallenge() -> ParentGateChallenge {
        let words = ["APPLE", "HOUSE", "SMILE", "WATER", "HAPPY", "PEACE", "BRIGHT", "FRIEND"]
        let selectedWord = words.randomElement()!

        // Generate similar-looking wrong options
        var options = [selectedWord]
        let similarWords = generateSimilarWords(to: selectedWord, from: words)

        for word in similarWords.prefix(3) {
            if !options.contains(word) {
                options.append(word)
            }
        }

        // Fill with random words if needed
        while options.count < 4 {
            let randomWord = words.randomElement()!
            if !options.contains(randomWord) {
                options.append(randomWord)
            }
        }

        return ParentGateChallenge(
            type: .readingChallenge(word: selectedWord, options: options.shuffled())
        )
    }

    private static func generateTextInputChallenge() -> ParentGateChallenge {
        let questions = [
            ("What color is grass?", "green"),
            ("How many days in a week?", "7"),
            ("What do bees make?", "honey"),
            ("What color is the sun?", "yellow"),
            ("What animal says 'meow'?", "cat"),
            ("What do we use to see?", "eyes"),
            ("What comes after Monday?", "tuesday"),
            ("What color is snow?", "white"),
        ]

        let (question, answer) = questions.randomElement()!

        return ParentGateChallenge(
            type: .textInput(question: question, expectedAnswer: answer)
        )
    }

    // MARK: - Helper Methods

    private static func generateMathOptions(correct: Int, range: ClosedRange<Int>) -> [Int] {
        var options = [correct]

        while options.count < 3 {
            let wrong = Int.random(in: range)
            if wrong != correct, !options.contains(wrong) {
                options.append(wrong)
            }
        }

        return options.shuffled()
    }

    private static func generateSimilarWords(to target: String, from wordList: [String]) -> [String] {
        wordList.filter { word in
            word != target && (
                word.count == target.count ||
                    word.first == target.first ||
                    word.last == target.last
            )
        }
    }

    // MARK: - Analytics & Tracking

    /// Record successful parent gate completion
    public static func recordSuccess(for context: ParentGateContext) {
        let timestamp = Date()

        #if DEBUG
            print("ParentGate SUCCESS: \(context.rawValue) at \(timestamp)")
        #endif

        // Track analytics
        Task { @MainActor in
            let attempts = UserDefaults.standard.integer(forKey: "parentGate_failedAttempts_\(context.rawValue)") + 1
            AnalyticsService.shared.trackParentGatePassed(
                action: context.rawValue,
                attempts: attempts
            )
        }

        // Update last success time for this context
        UserDefaults.standard.set(timestamp, forKey: "parentGate_lastSuccess_\(context.rawValue)")
    }

    /// Record failed attempt
    public static func recordFailedAttempt(for context: ParentGateContext) {
        let timestamp = Date()
        let key = "parentGate_failedAttempts_\(context.rawValue)"
        let currentCount = UserDefaults.standard.integer(forKey: key)

        UserDefaults.standard.set(currentCount + 1, forKey: key)

        #if DEBUG
            print("ParentGate FAILED: \(context.rawValue) - attempt \(currentCount + 1)")

            Task { @MainActor in
                AnalyticsService.shared.trackParentGateFailed(
                    action: context.rawValue,
                    attempts: currentCount + 1
                )
            }
        #endif
    }

    /// Record cancellation
    public static func recordCancellation(for context: ParentGateContext) {
        #if DEBUG
            print("ParentGate CANCELLED: \(context.rawValue)")
        #endif

        // Analytics.track("parent_gate_cancelled", properties: [
    }

    /// Record timeout
    public static func recordTimeout(for context: ParentGateContext) {
        #if DEBUG
            print("ParentGate TIMEOUT: \(context.rawValue)")
        #endif

        // Analytics.track("parent_gate_timeout", properties: [
    }

    // MARK: - Security Features

    /// Check if parent gate was recently passed for this context
    public static func isRecentlyPassed(for context: ParentGateContext, within duration: TimeInterval = 300) -> Bool {
        let key = "parentGate_lastSuccess_\(context.rawValue)"

        guard let lastSuccess = UserDefaults.standard.object(forKey: key) as? Date else {
            return false
        }

        return Date().timeIntervalSince(lastSuccess) < duration
    }

    /// Get failed attempt count for context
    public static func getFailedAttemptCount(for context: ParentGateContext) -> Int {
        let key = "parentGate_failedAttempts_\(context.rawValue)"
        return UserDefaults.standard.integer(forKey: key)
    }

    /// Reset failed attempts for context
    public static func resetFailedAttempts(for context: ParentGateContext) {
        let key = "parentGate_failedAttempts_\(context.rawValue)"
        UserDefaults.standard.removeObject(forKey: key)
    }

    /// Check if context is currently locked out
    public static func isLockedOut(for context: ParentGateContext) -> Bool {
        let key = "parentGate_lockout_\(context.rawValue)"

        guard let lockoutEnd = UserDefaults.standard.object(forKey: key) as? Date else {
            return false
        }

        return Date() < lockoutEnd
    }

    /// Set lockout for context
    public static func setLockout(for context: ParentGateContext, duration: TimeInterval = lockoutDuration) {
        let lockoutEnd = Date().addingTimeInterval(duration)
        let key = "parentGate_lockout_\(context.rawValue)"

        UserDefaults.standard.set(lockoutEnd, forKey: key)

        #if DEBUG
            print("ParentGate LOCKOUT: \(context.rawValue) until \(lockoutEnd)")
        #endif
    }

    /// Clear lockout for context
    public static func clearLockout(for context: ParentGateContext) {
        let key = "parentGate_lockout_\(context.rawValue)"
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - ParentGateContext

/// Defines different contexts where parent gate is required
public enum ParentGateContext: String, CaseIterable {
    case settings
    case paywall
    case restore
    case notifications
    case externalLink = "external_link"
    case deleteData = "delete_data"

    public var title: String {
        switch self {
        case .settings:
            return NSLocalizedString("ParentGate.Settings.Title", value: "Parent Verification", comment: "")

        case .paywall:
            return NSLocalizedString("ParentGate.Paywall.Title", value: "Purchase Authorization", comment: "")

        case .restore:
            return NSLocalizedString("ParentGate.Restore.Title", value: "Restore Verification", comment: "")

        case .notifications:
            return NSLocalizedString("ParentGate.Notifications.Title", value: "Notification Permissions", comment: "")

        case .externalLink:
            return NSLocalizedString("ParentGate.ExternalLink.Title", value: "External Link Warning", comment: "")

        case .deleteData:
            return NSLocalizedString("ParentGate.DeleteData.Title", value: "Data Deletion Confirmation", comment: "")
        }
    }

    public var description: String {
        switch self {
        case .settings:
            return NSLocalizedString(
                "ParentGate.Settings.Description",
                value: "To access settings, please complete this verification:",
                comment: ""
            )

        case .paywall:
            return NSLocalizedString(
                "ParentGate.Paywall.Description",
                value: "To proceed with purchase, please solve this problem:",
                comment: ""
            )

        case .restore:
            return NSLocalizedString(
                "ParentGate.Restore.Description",
                value: "To restore purchases, please verify:",
                comment: ""
            )

        case .notifications:
            return NSLocalizedString(
                "ParentGate.Notifications.Description",
                value: "To enable notifications, please complete:",
                comment: ""
            )

        case .externalLink:
            return NSLocalizedString(
                "ParentGate.ExternalLink.Description",
                value: "Before leaving the app, please verify:",
                comment: ""
            )

        case .deleteData:
            return NSLocalizedString(
                "ParentGate.DeleteData.Description",
                value: "To delete data permanently, please confirm:",
                comment: ""
            )
        }
    }

    public var icon: String {
        switch self {
        case .settings:
            return "gearshape.fill"

        case .paywall:
            return "creditcard.fill"

        case .restore:
            return "arrow.clockwise.circle.fill"

        case .notifications:
            return "bell.fill"

        case .externalLink:
            return "safari.fill"

        case .deleteData:
            return "trash.fill"
        }
    }

    public var color: Color {
        switch self {
        case .settings:
            return .blue

        case .paywall:
            return .green

        case .restore:
            return .orange

        case .notifications:
            return .purple

        case .externalLink:
            return .red

        case .deleteData:
            return .red
        }
    }
}

// MARK: - ParentGateChallenge

/// Represents a specific parent gate challenge
public struct ParentGateChallenge {
    public let type: ChallengeType
    public let id = UUID()

    public enum ChallengeType {
        case mathAddition(a: Int, b: Int, options: [Int])
        case mathSubtraction(a: Int, b: Int, options: [Int])
        case readingChallenge(word: String, options: [String])
        case timeChallenge(hour: Int, minute: Int, options: [String])
        case textInput(question: String, expectedAnswer: String)
    }

    /// Check if the provided answer is correct
    public func isCorrectAnswer(_ answer: String) -> Bool {
        switch type {
        case let .mathAddition(a, b, _):
            return answer == String(a + b)

        case let .mathSubtraction(a, b, _):
            return answer == String(a - b)

        case let .readingChallenge(word, _):
            return answer.lowercased() == word.lowercased()

        case let .timeChallenge(hour, minute, _):
            let expectedTime = String(format: "%d:%02d", hour, minute)
            return answer == expectedTime

        case let .textInput(_, expectedAnswer):
            return answer.lowercased() == expectedAnswer.lowercased()
        }
    }
}
