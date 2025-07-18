import Foundation
import AVFoundation
import UIKit

// MARK: - Safe Volume Manager

/// Manages safe volume levels and child safety features for audio playback
@MainActor
public class SafeVolumeManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = SafeVolumeManager()
    
    // MARK: - Constants
    
    public struct SafetyLimits {
        /// Maximum safe volume for children (WHO guidelines: 85dB for extended exposure)
        public static let maxChildSafeVolume: Float = 0.7
        
        /// Default starting volume for children
        public static let defaultChildVolume: Float = 0.4
        
        /// Maximum volume for adults/parents
        public static let maxAdultVolume: Float = 1.0
        
        /// Volume warning threshold
        public static let warningThreshold: Float = 0.6
        
        /// Time intervals for volume warnings (seconds)
        public static let warningInterval: TimeInterval = 1800 // 30 minutes
        
        /// Maximum continuous listening time (seconds)
        public static let maxListeningTime: TimeInterval = 3600 // 1 hour
        
        /// Break reminder interval (seconds)
        public static let breakReminderInterval: TimeInterval = 2700 // 45 minutes
    }
    
    // MARK: - Published Properties
    
    /// Current safe volume multiplier (0.0 - 1.0)
    @Published public var safeVolumeMultiplier: Float
    
    /// Whether safe volume is enabled
    @Published public var isSafeVolumeEnabled: Bool
    
    /// Whether parental override is active
    @Published public var isParentalOverrideActive: Bool
    
    /// Current volume warning level
    @Published public var volumeWarningLevel: VolumeWarningLevel
    
    /// Listening session duration
    @Published public var currentListeningDuration: TimeInterval
    
    /// Whether break reminder is needed
    @Published public var needsBreakReminder: Bool
    
    // MARK: - Private Properties
    
    private var listeningSessionTimer: Timer?
    private var volumeWarningTimer: Timer?
    private var lastVolumeWarningTime: Date?
    private var sessionStartTime: Date?
    
    // UserDefaults keys
    private let safeVolumeEnabledKey = "SafeVolumeEnabled"
    private let safeVolumeMultiplierKey = "SafeVolumeMultiplier"
    private let parentalOverrideKey = "ParentalOverrideActive"
    private let lastWarningTimeKey = "LastVolumeWarningTime"
    private let totalListeningTimeKey = "TotalListeningTime"
    
    // MARK: - Types
    
    public enum VolumeWarningLevel {
        case safe
        case caution
        case warning
        case danger
        
        public var color: UIColor {
            switch self {
            case .safe: return .systemGreen
            case .caution: return .systemYellow
            case .warning: return .systemOrange
            case .danger: return .systemRed
            }
        }
        
        public var message: String {
            switch self {
            case .safe:
                return NSLocalizedString("volume_warning_safe", comment: "Safe volume level")
            case .caution:
                return NSLocalizedString("volume_warning_caution", comment: "Caution volume level")
            case .warning:
                return NSLocalizedString("volume_warning_warning", comment: "Warning volume level")
            case .danger:
                return NSLocalizedString("volume_warning_danger", comment: "Danger volume level")
            }
        }
    }
    
    public enum SafetyEvent {
        case volumeWarning(Float)
        case listeningTimeWarning(TimeInterval)
        case breakRecommended
        case parentalOverrideActivated
        case parentalOverrideDeactivated
        case safeVolumeEnabled
        case safeVolumeDisabled
        
        public var analyticsEventName: String {
            switch self {
            case .volumeWarning: return "volume_warning_shown"
            case .listeningTimeWarning: return "listening_time_warning"
            case .breakRecommended: return "break_recommended"
            case .parentalOverrideActivated: return "parental_override_on"
            case .parentalOverrideDeactivated: return "parental_override_off"
            case .safeVolumeEnabled: return "safe_volume_enabled"
            case .safeVolumeDisabled: return "safe_volume_disabled"
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load saved settings
        self.isSafeVolumeEnabled = UserDefaults.standard.object(forKey: safeVolumeEnabledKey) as? Bool ?? true
        self.safeVolumeMultiplier = UserDefaults.standard.object(forKey: safeVolumeMultiplierKey) as? Float ?? SafetyLimits.defaultChildVolume
        self.isParentalOverrideActive = UserDefaults.standard.bool(forKey: parentalOverrideKey)
        
        // Initialize state
        self.volumeWarningLevel = .safe
        self.currentListeningDuration = 0
        self.needsBreakReminder = false
        
        // Load last warning time
        if let lastWarningData = UserDefaults.standard.object(forKey: lastWarningTimeKey) as? Data,
           let lastWarningTime = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(lastWarningData) as? Date {
            self.lastVolumeWarningTime = lastWarningTime
        }
        
        // Start monitoring if needed
        startMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Apply safe volume to given volume level
    public func applySafeVolume(to volume: Float) -> Float {
        guard isSafeVolumeEnabled && !isParentalOverrideActive else {
            return min(volume, SafetyLimits.maxAdultVolume)
        }
        
        let clampedVolume = min(volume, safeVolumeMultiplier)
        updateVolumeWarningLevel(for: clampedVolume)
        
        return clampedVolume
    }
    
    /// Set safe volume multiplier with validation
    public func setSafeVolumeMultiplier(_ multiplier: Float) {
        let clampedMultiplier = max(0.1, min(multiplier, SafetyLimits.maxChildSafeVolume))
        
        if clampedMultiplier != safeVolumeMultiplier {
            safeVolumeMultiplier = clampedMultiplier
            UserDefaults.standard.set(clampedMultiplier, forKey: safeVolumeMultiplierKey)
            
            updateVolumeWarningLevel(for: clampedMultiplier)
            
            print("[SafeVolumeManager] Safe volume multiplier set to: \(clampedMultiplier)")
        }
    }
    
    /// Enable or disable safe volume
    public func setSafeVolumeEnabled(_ enabled: Bool) {
        if enabled != isSafeVolumeEnabled {
            isSafeVolumeEnabled = enabled
            UserDefaults.standard.set(enabled, forKey: safeVolumeEnabledKey)
            
            let event: SafetyEvent = enabled ? .safeVolumeEnabled : .safeVolumeDisabled
            trackSafetyEvent(event)
            
            print("[SafeVolumeManager] Safe volume \(enabled ? "enabled" : "disabled")")
        }
    }
    
    /// Activate parental override (requires parent gate)
    public func activateParentalOverride() {
        if !isParentalOverrideActive {
            isParentalOverrideActive = true
            UserDefaults.standard.set(true, forKey: parentalOverrideKey)
            
            trackSafetyEvent(.parentalOverrideActivated)
            
            // Auto-deactivate after 30 minutes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1800) { [weak self] in
                self?.deactivateParentalOverride()
            }
            
            print("[SafeVolumeManager] Parental override activated")
        }
    }
    
    /// Deactivate parental override
    public func deactivateParentalOverride() {
        if isParentalOverrideActive {
            isParentalOverrideActive = false
            UserDefaults.standard.set(false, forKey: parentalOverrideKey)
            
            trackSafetyEvent(.parentalOverrideDeactivated)
            
            print("[SafeVolumeManager] Parental override deactivated")
        }
    }
    
    /// Start a new listening session
    public func startListeningSession() {
        sessionStartTime = Date()
        currentListeningDuration = 0
        needsBreakReminder = false
        
        startSessionTimer()
        
        print("[SafeVolumeManager] Listening session started")
    }
    
    /// End the current listening session
    public func endListeningSession() {
        stopSessionTimer()
        
        if let startTime = sessionStartTime {
            let totalDuration = Date().timeIntervalSince(startTime)
            updateTotalListeningTime(totalDuration)
            
            print("[SafeVolumeManager] Listening session ended, duration: \(totalDuration) seconds")
        }
        
        sessionStartTime = nil
        currentListeningDuration = 0
        needsBreakReminder = false
    }
    
    /// Check if volume level is safe for children
    public func isVolumeSafe(_ volume: Float) -> Bool {
        guard isSafeVolumeEnabled else { return true }
        return volume <= SafetyLimits.maxChildSafeVolume
    }
    
    /// Get safety recommendation for current settings
    public func getSafetyRecommendation() -> String {
        if !isSafeVolumeEnabled {
            return NSLocalizedString("safety_recommendation_enable", comment: "Enable safe volume")
        }
        
        if safeVolumeMultiplier > SafetyLimits.warningThreshold {
            return NSLocalizedString("safety_recommendation_lower_volume", comment: "Lower volume recommendation")
        }
        
        if currentListeningDuration > SafetyLimits.breakReminderInterval {
            return NSLocalizedString("safety_recommendation_take_break", comment: "Take a break recommendation")
        }
        
        return NSLocalizedString("safety_recommendation_good", comment: "Good safety settings")
    }
    
    /// Reset all safety settings to defaults
    public func resetToChildSafeDefaults() {
        setSafeVolumeEnabled(true)
        setSafeVolumeMultiplier(SafetyLimits.defaultChildVolume)
        deactivateParentalOverride()
        
        print("[SafeVolumeManager] Reset to child-safe defaults")
    }
    
    // MARK: - Private Methods
    
    private func startMonitoring() {
        // Set up volume monitoring
        startVolumeWarningTimer()
        
        // Listen for audio session changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionRouteChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionInterrupted),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    private func updateVolumeWarningLevel(for volume: Float) {
        let previousLevel = volumeWarningLevel
        
        if volume <= 0.3 {
            volumeWarningLevel = .safe
        } else if volume <= 0.5 {
            volumeWarningLevel = .caution
        } else if volume <= 0.7 {
            volumeWarningLevel = .warning
        } else {
            volumeWarningLevel = .danger
        }
        
        // Show warning if level increased significantly
        if volumeWarningLevel.rawValue > previousLevel.rawValue && volume > SafetyLimits.warningThreshold {
            showVolumeWarning(volume)
        }
    }
    
    private func showVolumeWarning(_ volume: Float) {
        let now = Date()
        
        // Check if enough time has passed since last warning
        if let lastWarning = lastVolumeWarningTime,
           now.timeIntervalSince(lastWarning) < SafetyLimits.warningInterval {
            return
        }
        
        lastVolumeWarningTime = now
        saveLastWarningTime(now)
        
        trackSafetyEvent(.volumeWarning(volume))
        
        // Post notification for UI to handle
        NotificationCenter.default.post(
            name: .volumeWarningTriggered,
            object: nil,
            userInfo: ["volume": volume, "level": volumeWarningLevel]
        )
        
        print("[SafeVolumeManager] Volume warning triggered for level: \(volume)")
    }
    
    private func startSessionTimer() {
        stopSessionTimer()
        
        listeningSessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateListeningDuration()
        }
    }
    
    private func stopSessionTimer() {
        listeningSessionTimer?.invalidate()
        listeningSessionTimer = nil
    }
    
    private func updateListeningDuration() {
        guard let startTime = sessionStartTime else { return }
        
        currentListeningDuration = Date().timeIntervalSince(startTime)
        
        // Check for break reminder
        if currentListeningDuration >= SafetyLimits.breakReminderInterval && !needsBreakReminder {
            needsBreakReminder = true
            trackSafetyEvent(.breakRecommended)
            
            NotificationCenter.default.post(
                name: .breakRecommendationTriggered,
                object: nil,
                userInfo: ["duration": currentListeningDuration]
            )
        }
        
        // Check for maximum listening time
        if currentListeningDuration >= SafetyLimits.maxListeningTime {
            trackSafetyEvent(.listeningTimeWarning(currentListeningDuration))
            
            NotificationCenter.default.post(
                name: .maxListeningTimeReached,
                object: nil,
                userInfo: ["duration": currentListeningDuration]
            )
        }
    }
    
    private func startVolumeWarningTimer() {
        volumeWarningTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.checkVolumeLevel()
        }
    }
    
    private func checkVolumeLevel() {
        // This would integrate with AudioEngineManager to check current playback volume
        // For now, we rely on the applySafeVolume method being called
    }
    
    private func updateTotalListeningTime(_ duration: TimeInterval) {
        let currentTotal = UserDefaults.standard.double(forKey: totalListeningTimeKey)
        let newTotal = currentTotal + duration
        UserDefaults.standard.set(newTotal, forKey: totalListeningTimeKey)
    }
    
    private func saveLastWarningTime(_ time: Date) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: time, requiringSecureCoding: false) {
            UserDefaults.standard.set(data, forKey: lastWarningTimeKey)
        }
    }
    
    private func trackSafetyEvent(_ event: SafetyEvent) {
        // Minimal analytics for child safety compliance
        print("[SafeVolumeManager] Safety event: \(event.analyticsEventName)")
        
        // Here you would integrate with your analytics service
        // keeping in mind COPPA compliance for children's apps
    }
    
    // MARK: - Audio Session Notifications
    
    @objc private func audioSessionRouteChanged(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Headphones were unplugged - pause for child safety
            NotificationCenter.default.post(name: .audioRouteChangedForSafety, object: nil)
            print("[SafeVolumeManager] Audio route changed - pausing for safety")
            
        default:
            break
        }
    }
    
    @objc private func audioSessionInterrupted(notification: Notification) {
        // Handle audio interruptions for safety
        endListeningSession()
    }
    
    deinit {
        stopSessionTimer()
        volumeWarningTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Extensions

extension SafeVolumeManager.VolumeWarningLevel: RawRepresentable {
    public var rawValue: Int {
        switch self {
        case .safe: return 0
        case .caution: return 1
        case .warning: return 2
        case .danger: return 3
        }
    }
    
    public init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .safe
        case 1: self = .caution
        case 2: self = .warning
        case 3: self = .danger
        default: return nil
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let volumeWarningTriggered = Notification.Name("VolumeWarningTriggered")
    static let breakRecommendationTriggered = Notification.Name("BreakRecommendationTriggered")
    static let maxListeningTimeReached = Notification.Name("MaxListeningTimeReached")
    static let audioRouteChangedForSafety = Notification.Name("AudioRouteChangedForSafety")
} 