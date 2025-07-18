import Foundation
import AVFoundation

/// BabySoundsCore - Основная логика и сервисы BabySounds
/// 
/// Этот модуль содержит базовую логику приложения без UI зависимостей:
/// - Аудио движок и управление звуками
/// - Модели данных
/// - Сервисы для работы с данными
/// - Утилиты и расширения
public struct BabySoundsCore {
    public static let version = "1.0.0"
}

// MARK: - Public API

/// Основные константы приложения
public enum AppConstants {
    public static let maxConcurrentSounds = 4
    public static let defaultFadeDuration: TimeInterval = 1.0
    public static let safeVolumeLimit: Float = 0.8
}

/// Результат выполнения аудио операций
public enum AudioResult {
    case success
    case failure(AudioError)
}

/// Ошибки аудио системы
public enum AudioError: Error, LocalizedError {
    case engineNotStarted
    case fileNotFound(String)
    case playbackFailed
    case volumeTooHigh
    
    public var errorDescription: String? {
        switch self {
        case .engineNotStarted:
            return "Audio engine is not started"
        case .fileNotFound(let filename):
            return "Audio file not found: \(filename)"
        case .playbackFailed:
            return "Failed to start audio playback"
        case .volumeTooHigh:
            return "Volume exceeds safe limits for children"
        }
    }
}

/// Базовый протокол для аудио движка
public protocol AudioEngineProtocol {
    func startEngine() async throws
    func stopEngine()
    func playSound(_ sound: SoundType) async -> AudioResult
    func stopSound(_ sound: SoundType)
    func setVolume(_ volume: Float, for sound: SoundType)
}

/// Типы звуков в приложении
public enum SoundType: String, CaseIterable, Identifiable {
    case whiteNoise = "white_noise"
    case pinkNoise = "pink_noise"
    case brownNoise = "brown_noise"
    case rainForest = "forest"
    case oceanWaves = "ocean_waves"
    case heartbeat = "heartbeat"
    case wombSounds = "womb_sounds"
    case airConditioner = "air_conditioner"
    case fan = "fan"
    case rain = "rain"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .whiteNoise: return "White Noise"
        case .pinkNoise: return "Pink Noise"
        case .brownNoise: return "Brown Noise"
        case .rainForest: return "Rain Forest"
        case .oceanWaves: return "Ocean Waves"
        case .heartbeat: return "Heartbeat"
        case .wombSounds: return "Womb Sounds"
        case .airConditioner: return "Air Conditioner"
        case .fan: return "Fan"
        case .rain: return "Rain"
        }
    }
    
    public var filename: String {
        return "\(rawValue).mp3"
    }
} 