import UIKit

// MARK: - Haptic Manager

/// Provides haptic feedback across the app
@MainActor
final class HapticManager {
    // MARK: - Singleton

    static let shared = HapticManager()

    // MARK: - Private Properties

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    // MARK: - Initialization

    private init() {
        // Prepare generators
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selection.prepare()
        notification.prepare()
    }

    // MARK: - Public API

    /// Trigger impact haptic feedback
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            impactLight.impactOccurred()
            impactLight.prepare()

        case .medium:
            impactMedium.impactOccurred()
            impactMedium.prepare()

        case .heavy:
            impactHeavy.impactOccurred()
            impactHeavy.prepare()

        case .soft:
            impactLight.impactOccurred(intensity: 0.5)
            impactLight.prepare()

        case .rigid:
            impactHeavy.impactOccurred(intensity: 1.0)
            impactHeavy.prepare()

        @unknown default:
            impactMedium.impactOccurred()
            impactMedium.prepare()
        }
    }

    /// Trigger selection haptic feedback
    func selection() {
        self.selection.selectionChanged()
        self.selection.prepare()
    }

    /// Trigger notification haptic feedback
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.notificationOccurred(type)
        notification.prepare()
    }
}
