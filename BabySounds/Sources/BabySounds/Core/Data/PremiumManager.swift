import Foundation

#if canImport(SwiftUI)
import SwiftUI
public typealias PremiumObservableObject = ObservableObject
#else
public protocol PremiumObservableObject: AnyObject {}
#endif

public final class PremiumManager: PremiumObservableObject {
    public static let shared = PremiumManager()

    public enum PremiumFeature: String, CaseIterable {
        case premiumSounds, multiTrackMixing, extendedTimer, sleepSchedules, offlinePacks, advancedControls,
             unlimitedFavorites, darkNightMode

        public var localizedName: String { rawValue }
        public var description: String { "Feature: \(rawValue)" }
        public var icon: String { "star" }
    }

    public enum PremiumGateAction {
        case showPaywall
        case showMessage(String)
        case allow
    }

    public enum Limits {
        public static let maxFavoritesForFree = 5
        public static let maxTimerMinutesForFree = 30
        public static let maxSimultaneousTracksForFree = 1
        public static let maxGainAdjustmentForFree: Float = 0
        public static let maxPanAdjustmentForFree: Float = 0
    }

    #if canImport(SwiftUI)
    @Published public var pendingGateAction: PremiumGateAction?
    #else
    public var pendingGateAction: PremiumGateAction?
    #endif

    private init() {}

    private var isPremium: Bool { false }

    public func hasAccess(to _: PremiumFeature) -> Bool { isPremium }

    public func gateFeature(_ feature: PremiumFeature) -> PremiumGateAction {
        guard !hasAccess(to: feature) else { return .allow }
        switch feature {
        case .extendedTimer, .advancedControls, .unlimitedFavorites:
            return .showMessage("Premium required")
        default:
            return .showPaywall
        }
    }

    public func canPlayPremiumSound() -> Bool { hasAccess(to: .premiumSounds) }
    public func canAddFavorite(currentCount: Int) -> Bool { isPremium || currentCount < Limits.maxFavoritesForFree }
    public func canUseTimerMinutes(_ minutes: Int) -> Bool { isPremium || minutes <= Limits.maxTimerMinutesForFree }
    public func canPlaySimultaneousTracks(_ count: Int) -> Bool { isPremium || count <= Limits.maxSimultaneousTracksForFree }
    public func allowedGainAdjustment(_ requested: Float) -> Float { isPremium ? requested : Limits.maxGainAdjustmentForFree }
    public func allowedPanAdjustment(_ requested: Float) -> Float { isPremium ? requested : Limits.maxPanAdjustmentForFree }
}
