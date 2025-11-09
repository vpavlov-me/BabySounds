import Foundation
import SwiftUI

// MARK: - PremiumManager

/// Centralizes premium feature management and access control
@MainActor
public final class PremiumManager: ObservableObject {
    // MARK: - Singleton

    public static let shared = PremiumManager()

    // MARK: - Dependencies

    private let subscriptionService = SubscriptionServiceSK2.shared

    // MARK: - Types

    public enum PremiumFeature: String, CaseIterable {
        case premiumSounds = "premium_sounds"
        case multiTrackMixing = "multi_track_mixing"
        case extendedTimer = "extended_timer"
        case sleepSchedules = "sleep_schedules"
        case offlinePacks = "offline_packs"
        case advancedControls = "advanced_controls"
        case unlimitedFavorites = "unlimited_favorites"
        case darkNightMode = "dark_night_mode"

        public var localizedName: String {
            switch self {
            case .premiumSounds:
                return NSLocalizedString("Premium.Feature.Sounds", value: "Premium Sounds", comment: "")

            case .multiTrackMixing:
                return NSLocalizedString("Premium.Feature.Mixing", value: "Multi-Track Mixing", comment: "")

            case .extendedTimer:
                return NSLocalizedString("Premium.Feature.Timer", value: "Extended Timer", comment: "")

            case .sleepSchedules:
                return NSLocalizedString("Premium.Feature.Schedules", value: "Sleep Schedules", comment: "")

            case .offlinePacks:
                return NSLocalizedString("Premium.Feature.Offline", value: "Offline Packs", comment: "")

            case .advancedControls:
                return NSLocalizedString("Premium.Feature.Controls", value: "Advanced Controls", comment: "")

            case .unlimitedFavorites:
                return NSLocalizedString("Premium.Feature.Favorites", value: "Unlimited Favorites", comment: "")

            case .darkNightMode:
                return NSLocalizedString("Premium.Feature.DarkMode", value: "Dark Night Mode", comment: "")
            }
        }

        public var description: String {
            switch self {
            case .premiumSounds:
                return NSLocalizedString(
                    "Premium.Feature.SoundsDesc",
                    value: "Access 50+ exclusive premium sounds",
                    comment: ""
                )

            case .multiTrackMixing:
                return NSLocalizedString(
                    "Premium.Feature.MixingDesc",
                    value: "Play up to 4 sounds simultaneously",
                    comment: ""
                )

            case .extendedTimer:
                return NSLocalizedString("Premium.Feature.TimerDesc", value: "Sleep timer up to 12 hours", comment: "")

            case .sleepSchedules:
                return NSLocalizedString(
                    "Premium.Feature.SchedulesDesc",
                    value: "Automated bedtime routines",
                    comment: ""
                )

            case .offlinePacks:
                return NSLocalizedString(
                    "Premium.Feature.OfflineDesc",
                    value: "Download for offline listening",
                    comment: ""
                )

            case .advancedControls:
                return NSLocalizedString(
                    "Premium.Feature.ControlsDesc",
                    value: "Gain, pan, and fade controls",
                    comment: ""
                )

            case .unlimitedFavorites:
                return NSLocalizedString(
                    "Premium.Feature.FavoritesDesc",
                    value: "Save unlimited favorite sounds",
                    comment: ""
                )

            case .darkNightMode:
                return NSLocalizedString(
                    "Premium.Feature.DarkModeDesc",
                    value: "Red-tinted UI for nighttime use",
                    comment: ""
                )
            }
        }

        public var icon: String {
            switch self {
            case .premiumSounds:
                return "music.note.list"

            case .multiTrackMixing:
                return "slider.horizontal.3"

            case .extendedTimer:
                return "timer"

            case .sleepSchedules:
                return "calendar"

            case .offlinePacks:
                return "arrow.down.circle"

            case .advancedControls:
                return "dial.max"

            case .unlimitedFavorites:
                return "heart.circle"

            case .darkNightMode:
                return "moon.fill"
            }
        }
    }

    public enum PremiumGateAction {
        case showPaywall
        case showMessage(String)
        case allow
    }

    // MARK: - Constants

    public enum Limits {
        public static let maxFavoritesForFree = 5
        public static let maxTimerMinutesForFree = 30
        public static let maxSimultaneousTracksForFree = 1
        public static let maxGainAdjustmentForFree: Float = 0.0 // No gain adjustment
        public static let maxPanAdjustmentForFree: Float = 0.0 // No pan adjustment
    }

    // MARK: - Published Properties

    @Published public private(set) var gateActionTrigger = UUID()
    @Published public var pendingGateAction: PremiumGateAction?

    // MARK: - Initialization

    private init() {
        // Private init for singleton pattern
    }

    // MARK: - Feature Access Control

    /// Check if a feature is available for current subscription status
    public func hasAccess(to _: PremiumFeature) -> Bool {
        subscriptionService.hasActiveSubscription
    }

    /// Gate access to a premium feature and return appropriate action
    public func gateFeature(_ feature: PremiumFeature) -> PremiumGateAction {
        guard !hasAccess(to: feature) else {
            return .allow
        }

        switch feature {
        case .premiumSounds:
            return .showPaywall

        case .multiTrackMixing:
            return .showPaywall

        case .extendedTimer:
            return .showMessage(NSLocalizedString(
                "Premium.Gate.Timer",
                value: "Extended sleep timer (over 30 minutes) requires Premium",
                comment: ""
            ))

        case .sleepSchedules:
            return .showPaywall

        case .offlinePacks:
            return .showPaywall

        case .advancedControls:
            return .showMessage(NSLocalizedString(
                "Premium.Gate.Controls",
                value: "Advanced audio controls require Premium",
                comment: ""
            ))

        case .unlimitedFavorites:
            return .showMessage(NSLocalizedString(
                "Premium.Gate.Favorites",
                value: "Free users can save up to 5 favorites. Upgrade to Premium for unlimited favorites.",
                comment: ""
            ))

        case .darkNightMode:
            return .showPaywall
        }
    }

    /// Gate access and trigger appropriate UI action
    public func requestAccess(to feature: PremiumFeature) {
        let action = gateFeature(feature)

        if case .allow = action {
            return // Feature is available, proceed
        }

        // Trigger UI action for premium gate
        DispatchQueue.main.async {
            self.pendingGateAction = action
            self.gateActionTrigger = UUID() // Trigger SwiftUI update
        }
    }

    // MARK: - Specific Feature Checks

    /// Check if user can play a premium sound
    public func canPlayPremiumSound() -> Bool {
        hasAccess(to: .premiumSounds)
    }

    /// Check if user can add more favorites
    public func canAddFavorite(currentCount: Int) -> Bool {
        if hasAccess(to: .unlimitedFavorites) {
            return true
        }
        return currentCount < Limits.maxFavoritesForFree
    }

    /// Check if user can set timer for specified minutes
    public func canSetTimer(minutes: Int) -> Bool {
        if hasAccess(to: .extendedTimer) {
            return true
        }
        return minutes <= Limits.maxTimerMinutesForFree
    }

    /// Check if user can play multiple tracks simultaneously
    public func canPlayMultipleTracks(currentCount: Int) -> Bool {
        if hasAccess(to: .multiTrackMixing) {
            return true
        }
        return currentCount < Limits.maxSimultaneousTracksForFree
    }

    /// Check if user can use advanced audio controls
    public func canUseAdvancedControls() -> Bool {
        hasAccess(to: .advancedControls)
    }

    // MARK: - UI State Helpers

    /// Get opacity for premium-locked content
    public func premiumContentOpacity(for feature: PremiumFeature) -> Double {
        hasAccess(to: feature) ? 1.0 : 0.6
    }

    /// Check if content should be disabled
    public func isPremiumContentDisabled(for feature: PremiumFeature) -> Bool {
        !hasAccess(to: feature)
    }

    /// Get appropriate UI feedback for premium gate
    public func premiumGateLabel(for feature: PremiumFeature) -> String? {
        guard !hasAccess(to: feature) else { return nil }

        switch feature {
        case .premiumSounds:
            return NSLocalizedString("Premium.Gate.UnlockToPlay", value: "🔒 Unlock Premium to Play", comment: "")

        case .multiTrackMixing:
            return NSLocalizedString("Premium.Gate.UnlockMixing", value: "🔒 Premium: Multi-Track Mixing", comment: "")

        case .extendedTimer:
            return NSLocalizedString("Premium.Gate.UnlockTimer", value: "🔒 Premium: Extended Timer", comment: "")

        case .unlimitedFavorites:
            return NSLocalizedString(
                "Premium.Gate.UnlockFavorites",
                value: "🔒 Premium: Unlimited Favorites",
                comment: ""
            )

        default:
            return NSLocalizedString("Premium.Gate.UnlockFeature", value: "🔒 Premium Feature", comment: "")
        }
    }

    // MARK: - Analytics Helpers

    /// Track premium gate interaction for analytics
    public func trackPremiumGate(feature: PremiumFeature, action: String) {
        #if DEBUG
            print("PremiumManager: Feature '\(feature.rawValue)' gated with action '\(action)'")
        #endif

        // TODO: Send to analytics service
        // Analytics.track("premium_gate", properties: [
        //     "feature": feature.rawValue,
        //     "action": action,
        //     "subscription_status": subscriptionService.status
        // ])
    }

    // MARK: - Clear Pending Actions

    public func clearPendingAction() {
        pendingGateAction = nil
    }
}

// MARK: - PremiumGateResult

public struct PremiumGateResult {
    public let allowed: Bool
    public let action: PremiumManager.PremiumGateAction
    public let feature: PremiumManager.PremiumFeature

    public var shouldShowPaywall: Bool {
        if case .showPaywall = action {
            return true
        }
        return false
    }

    public var message: String? {
        if case let .showMessage(msg) = action {
            return msg
        }
        return nil
    }
}
