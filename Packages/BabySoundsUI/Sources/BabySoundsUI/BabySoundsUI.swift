import SwiftUI
import BabySoundsCore

/// BabySoundsUI - Переиспользуемые SwiftUI компоненты для BabySounds
/// 
/// Этот модуль содержит UI компоненты, которые могут быть использованы
/// в разных частях приложения или даже в других проектах.
public struct BabySoundsUI {
    public static let version = "1.0.0"
}

// MARK: - Public API

/// Базовые цвета дизайн-системы
public extension Color {
    static let babyBlue = Color(red: 0.7, green: 0.9, blue: 1.0)
    static let babyPink = Color(red: 1.0, green: 0.8, blue: 0.9)
    static let softGray = Color(red: 0.95, green: 0.95, blue: 0.97)
}

/// Базовые размеры для детского интерфейса
public enum BabyDesign {
    public static let minimumTouchTarget: CGFloat = 64
    public static let cornerRadius: CGFloat = 16
    public static let padding: CGFloat = 16
}

// MARK: - Public Exports

/// Re-export основных компонентов
@_exported import struct SoundCard

/// Placeholder для будущих UI компонентов
public struct BabyButton: View {
    let title: String
    let action: () -> Void
    
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(minHeight: BabyDesign.minimumTouchTarget)
                .frame(maxWidth: .infinity)
                .background(Color.babyBlue)
                .cornerRadius(BabyDesign.cornerRadius)
        }
        .accessibilityLabel(title)
        .accessibilityRole(.button)
    }
} 