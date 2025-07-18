import SwiftUI

/// BabySoundsUI - Reusable SwiftUI components for BabySounds
///
/// This module contains UI components that can be used
/// in different parts of the application or even in other projects.
///
/// All components follow Kids Category design guidelines and accessibility standards.

// MARK: - Design System

/// Basic design system colors
public extension Color {
    static let babyBlue = Color(red: 0.85, green: 0.95, blue: 1.0)
    static let softPink = Color(red: 1.0, green: 0.9, blue: 0.95)
    static let gentleYellow = Color(red: 1.0, green: 0.98, blue: 0.8)
    static let softGray = Color(red: 0.95, green: 0.95, blue: 0.97)
}

/// Basic sizes for child interface
public struct BabyDesign {
    public static let minimumTouchTarget: CGFloat = 64 // WCAG AA requirement
    public static let cornerRadius: CGFloat = 16
    public static let padding: CGFloat = 16
    public static let smallPadding: CGFloat = 8
    public static let largePadding: CGFloat = 24
}

// MARK: - Public API

/// Re-export main components
public typealias BabyButton = Components.BabyButton
public typealias SoundCard = Components.SoundCard

/// Placeholder for future UI components
public enum Components {}

// MARK: - Module Info

public struct BabySoundsUI {
    public static let version = "1.0.0"
} 