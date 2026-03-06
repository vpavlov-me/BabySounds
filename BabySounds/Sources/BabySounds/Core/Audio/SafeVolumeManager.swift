import Foundation

#if canImport(SwiftUI)
import SwiftUI
public typealias SafeVolumeObservableObject = ObservableObject
#else
public protocol SafeVolumeObservableObject: AnyObject {}
#endif

#if canImport(UIKit)
import UIKit
public typealias SafeVolumeColor = UIColor
#else
public struct SafeVolumeColor: Equatable {
    public static let systemGreen = SafeVolumeColor()
    public static let systemYellow = SafeVolumeColor()
    public static let systemOrange = SafeVolumeColor()
    public static let systemRed = SafeVolumeColor()
}
#endif

public final class SafeVolumeManager: SafeVolumeObservableObject {
    public static let shared = SafeVolumeManager()

    public enum SafetyLimits {
        public static let maxChildSafeVolume: Float = 0.75
        public static let defaultChildVolume: Float = 0.4
        public static let maxAdultVolume: Float = 1.0
    }

    public enum VolumeWarningLevel {
        case safe, caution, warning, danger

        public var color: SafeVolumeColor {
            switch self {
            case .safe: return .systemGreen
            case .caution: return .systemYellow
            case .warning: return .systemOrange
            case .danger: return .systemRed
            }
        }
    }

    #if canImport(SwiftUI)
    @Published public private(set) var safeVolumeMultiplier: Float
    @Published public private(set) var isSafeVolumeEnabled: Bool
    @Published public private(set) var currentListeningDuration: TimeInterval
    @Published public private(set) var volumeWarningLevel: VolumeWarningLevel
    #else
    public private(set) var safeVolumeMultiplier: Float
    public private(set) var isSafeVolumeEnabled: Bool
    public private(set) var currentListeningDuration: TimeInterval
    public private(set) var volumeWarningLevel: VolumeWarningLevel
    #endif

    private var sessionStartTime: Date?
    private var isHeadphonesConnected = false

    public var currentVolumeLimit: Float { safeVolumeMultiplier }
    public var currentSessionDuration: TimeInterval {
        guard let start = sessionStartTime else { return currentListeningDuration }
        return max(currentListeningDuration, Date().timeIntervalSince(start))
    }

    private init() {
        safeVolumeMultiplier = SafetyLimits.defaultChildVolume
        isSafeVolumeEnabled = true
        currentListeningDuration = 0
        volumeWarningLevel = .safe
    }

    public func applySafeVolume(to volume: Float) -> Float {
        guard isSafeVolumeEnabled else { return min(volume, SafetyLimits.maxAdultVolume) }

        var limit = safeVolumeMultiplier
        if isHeadphonesConnected {
            limit *= 0.8
        }

        let clamped = min(max(volume, 0), limit)
        updateWarningLevel(for: clamped)
        return clamped
    }

    public func setVolumeLimit(_ limit: Float) {
        safeVolumeMultiplier = min(max(limit, 0.1), SafetyLimits.maxChildSafeVolume)
    }

    public func setEnabled(_ enabled: Bool) {
        isSafeVolumeEnabled = enabled
    }

    public func setHeadphonesConnected(_ connected: Bool) {
        isHeadphonesConnected = connected
    }

    public func startListeningSession() {
        sessionStartTime = Date()
        currentListeningDuration = 0
    }

    public func endListeningSession() {
        sessionStartTime = nil
        currentListeningDuration = 0
    }

    public func convertFromDb(_ db: Float) -> Float {
        guard db > -80 else { return 0 }
        return pow(10, db / 20)
    }

    public func convertToDb(_ linear: Float) -> Float {
        guard linear > 0 else { return -80 }
        return 20 * log10(linear)
    }

    private func updateWarningLevel(for volume: Float) {
        if volume <= 0.3 {
            volumeWarningLevel = .safe
        } else if volume <= 0.5 {
            volumeWarningLevel = .caution
        } else if volume <= SafetyLimits.maxChildSafeVolume {
            volumeWarningLevel = .warning
        } else {
            volumeWarningLevel = .danger
        }
    }
}
