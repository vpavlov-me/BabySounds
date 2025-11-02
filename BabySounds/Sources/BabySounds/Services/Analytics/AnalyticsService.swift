import Foundation
import OSLog

// MARK: - Analytics Event

/// Privacy-compliant analytics event
public struct AnalyticsEvent {
    let name: String
    let category: EventCategory
    let properties: [String: String]
    let timestamp: Date

    enum EventCategory: String {
        case app = "app"
        case audio = "audio"
        case premium = "premium"
        case safety = "safety"
        case schedule = "schedule"
        case error = "error"
    }

    init(name: String, category: EventCategory, properties: [String: String] = [:]) {
        self.name = name
        self.category = category
        self.properties = properties
        self.timestamp = Date()
    }
}

// MARK: - Analytics Service

/// Privacy-first analytics service
/// No PII collected, COPPA compliant, uses local logging only for v1.0
@MainActor
public class AnalyticsService: ObservableObject {
    public static let shared = AnalyticsService()

    private let logger = Logger(subsystem: "com.babysounds.analytics", category: "events")
    private var isEnabled = true

    // MARK: - Configuration

    /// Enable/disable analytics (respects user privacy settings)
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        logger.info("Analytics \(enabled ? "enabled" : "disabled")")
    }

    // MARK: - Event Tracking

    /// Track an analytics event
    public func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }

        // Log to OSLog (viewable in Console.app)
        logger.info("[\(event.category.rawValue)] \(event.name) \(self.formatProperties(event.properties))")

        // Future: Send to TelemetryDeck or Firebase
        // For v1.0, we only log locally (privacy-first approach)
    }

    /// Track event with string name
    public func track(_ name: String, category: AnalyticsEvent.EventCategory, properties: [String: String] = [:]) {
        let event = AnalyticsEvent(name: name, category: category, properties: properties)
        track(event)
    }

    // MARK: - App Lifecycle Events

    public func trackAppLaunch() {
        track("app_launch", category: .app)
    }

    public func trackAppEnterBackground() {
        track("app_background", category: .app)
    }

    public func trackAppEnterForeground() {
        track("app_foreground", category: .app)
    }

    // MARK: - Audio Events

    public func trackSoundPlayed(soundId: String, isLoop: Bool) {
        track("sound_played", category: .audio, properties: [
            "sound_id": soundId,
            "loop": isLoop ? "true" : "false"
        ])
    }

    public func trackSoundStopped(soundId: String, duration: TimeInterval) {
        track("sound_stopped", category: .audio, properties: [
            "sound_id": soundId,
            "duration_seconds": String(format: "%.0f", duration)
        ])
    }

    public func trackMultiTrackMixing(trackCount: Int) {
        track("multi_track_mixing", category: .audio, properties: [
            "track_count": "\(trackCount)"
        ])
    }

    // MARK: - Premium Events

    public func trackPremiumFeatureAttempted(feature: String, userType: String) {
        track("premium_feature_attempted", category: .premium, properties: [
            "feature": feature,
            "user_type": userType // "free" or "premium"
        ])
    }

    public func trackPaywallShown(feature: String) {
        track("paywall_shown", category: .premium, properties: [
            "feature": feature
        ])
    }

    public func trackPurchaseInitiated(productId: String) {
        track("purchase_initiated", category: .premium, properties: [
            "product_id": productId
        ])
    }

    public func trackPurchaseCompleted(productId: String) {
        track("purchase_completed", category: .premium, properties: [
            "product_id": productId
        ])
    }

    public func trackPurchaseFailed(productId: String, reason: String) {
        track("purchase_failed", category: .premium, properties: [
            "product_id": productId,
            "reason": reason
        ])
    }

    public func trackRestorePurchases(success: Bool) {
        track("restore_purchases", category: .premium, properties: [
            "success": success ? "true" : "false"
        ])
    }

    // MARK: - Safety Events

    public func trackParentGateShown(action: String) {
        track("parent_gate_shown", category: .safety, properties: [
            "action": action
        ])
    }

    public func trackParentGatePassed(action: String, attempts: Int) {
        track("parent_gate_passed", category: .safety, properties: [
            "action": action,
            "attempts": "\(attempts)"
        ])
    }

    public func trackParentGateFailed(action: String, attempts: Int) {
        track("parent_gate_failed", category: .safety, properties: [
            "action": action,
            "attempts": "\(attempts)"
        ])
    }

    public func trackExternalLinkOpened(url: String) {
        // Anonymize URL - only track domain
        let domain = URL(string: url)?.host ?? "unknown"
        track("external_link_opened", category: .safety, properties: [
            "domain": domain
        ])
    }

    public func trackVolumeWarning(level: Float) {
        track("volume_warning", category: .safety, properties: [
            "level": String(format: "%.2f", level)
        ])
    }

    public func trackListeningTimeWarning(minutes: Int) {
        track("listening_time_warning", category: .safety, properties: [
            "minutes": "\(minutes)"
        ])
    }

    // MARK: - Schedule Events

    public func trackScheduleCreated(daysCount: Int, hasSounds: Bool) {
        track("schedule_created", category: .schedule, properties: [
            "days_count": "\(daysCount)",
            "has_sounds": hasSounds ? "true" : "false"
        ])
    }

    public func trackScheduleTriggered(scheduleId: String, soundsCount: Int) {
        // Anonymize schedule ID
        track("schedule_triggered", category: .schedule, properties: [
            "sounds_count": "\(soundsCount)"
        ])
    }

    public func trackNotificationPermissionRequested() {
        track("notification_permission_requested", category: .schedule)
    }

    public func trackNotificationPermissionGranted(granted: Bool) {
        track("notification_permission_granted", category: .schedule, properties: [
            "granted": granted ? "true" : "false"
        ])
    }

    // MARK: - Error Events

    public func trackError(error: Error, context: String) {
        track("error_occurred", category: .error, properties: [
            "context": context,
            "error_type": String(describing: type(of: error))
        ])
    }

    public func trackAudioError(soundId: String, error: String) {
        track("audio_error", category: .error, properties: [
            "sound_id": soundId,
            "error": error
        ])
    }

    // MARK: - Helper Methods

    private func formatProperties(_ properties: [String: String]) -> String {
        guard !properties.isEmpty else { return "" }
        let pairs = properties.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        return "{\(pairs)}"
    }

    // MARK: - Privacy

    /// Get anonymized device info (no PII)
    public var anonymousDeviceInfo: [String: String] {
        [
            "platform": "iOS",
            "os_version": UIDevice.current.systemVersion,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
    }
}

// MARK: - Analytics Extension for Common Patterns

public extension AnalyticsService {

    /// Track feature usage
    func trackFeatureUsed(_ featureName: String) {
        track("feature_used", category: .app, properties: ["feature": featureName])
    }

    /// Track screen view
    func trackScreenView(_ screenName: String) {
        track("screen_view", category: .app, properties: ["screen": screenName])
    }

    /// Track user action
    func trackAction(_ actionName: String, value: String? = nil) {
        var props = ["action": actionName]
        if let value = value {
            props["value"] = value
        }
        track("user_action", category: .app, properties: props)
    }
}
