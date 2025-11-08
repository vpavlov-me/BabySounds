import Foundation
import SwiftUI

// MARK: - Sound Category

enum SoundCategory: String, CaseIterable, Codable {
    case all = "all"
    case white = "white"
    case pink = "pink"
    case brown = "brown"
    case nature = "nature"
    case womb = "womb"
    case fan = "fan"
    case animal = "animal"
    case transport = "transport"
    case music = "music"
    case lullaby = "lullaby"
    case household = "household"
    case vehicle = "vehicle"
    case custom = "custom"
    
    var localizedName: LocalizedStringKey {
        switch self {
        case .all: return "All Sounds"
        case .white: return "White Noise"
        case .pink: return "Pink Noise"
        case .brown: return "Brown Noise"
        case .nature: return "Nature"
        case .womb: return "Womb Sounds"
        case .fan: return "Fan & Air"
        case .animal: return "Animals"
        case .transport: return "Transport"
        case .music: return "Music"
        case .lullaby: return "Lullabies"
        case .household: return "Household"
        case .vehicle: return "Vehicles"
        case .custom: return "Custom"
        }
    }
    
    var emoji: String {
        switch self {
        case .all: return "🎵"
        case .white: return "🌬️"
        case .pink: return "🌸"
        case .brown: return "🤎"
        case .nature: return "🌿"
        case .womb: return "❤️"
        case .fan: return "💨"
        case .animal: return "🐾"
        case .transport: return "🚗"
        case .music: return "🎵"
        case .lullaby: return "🎼"
        case .household: return "🏠"
        case .vehicle: return "🚙"
        case .custom: return "⭐"
        }
    }
}

// MARK: - Sound Model

struct Sound: Identifiable, Codable, Hashable {
    let id: UUID
    let titleKey: LocalizedStringKey
    let category: SoundCategory
    let fileName: String
    let fileExt: String
    let loop: Bool
    let premium: Bool
    let previewGainDb: Float?
    let defaultGainDb: Float
    let color: CodableColor
    let emoji: String?
    
    init(
        id: UUID = UUID(),
        titleKey: LocalizedStringKey,
        category: SoundCategory,
        fileName: String,
        fileExt: String = "mp3",
        loop: Bool = true,
        premium: Bool = false,
        previewGainDb: Float? = nil,
        defaultGainDb: Float = 0,
        color: Color,
        emoji: String? = nil
    ) {
        self.id = id
        self.titleKey = titleKey
        self.category = category
        self.fileName = fileName
        self.fileExt = fileExt
        self.loop = loop
        self.premium = premium
        self.previewGainDb = previewGainDb
        self.defaultGainDb = defaultGainDb
        self.color = CodableColor(color)
        self.emoji = emoji
    }
    
    var filePath: String {
        "Resources/Sounds/\(category.rawValue)/\(fileName).\(fileExt)"
    }
    
    var displayEmoji: String {
        emoji ?? category.emoji
    }

    /// Check if sound is premium content
    var isPremium: Bool {
        return premium
    }

    /// Sound name for display (from titleKey)
    var name: String {
        return String(describing: titleKey)
    }

    var gradientColors: [Color] {
        switch category {
        case .all:
            return [.pink.opacity(0.8), .purple.opacity(0.6)]
        case .nature:
            return [.green.opacity(0.8), .blue.opacity(0.6)]
        case .white:
            return [.gray.opacity(0.8), .white]
        case .pink:
            return [.pink.opacity(0.8), .purple.opacity(0.6)]
        case .brown:
            return [.brown.opacity(0.8), .orange.opacity(0.6)]
        case .womb:
            return [.red.opacity(0.6), .pink.opacity(0.8)]
        case .fan:
            return [.blue.opacity(0.6), .cyan.opacity(0.8)]
        case .animal:
            return [.orange.opacity(0.8), .yellow.opacity(0.6)]
        case .transport:
            return [.blue.opacity(0.8), .gray.opacity(0.6)]
        case .music:
            return [.purple.opacity(0.8), .pink.opacity(0.6)]
        case .lullaby:
            return [.purple.opacity(0.6), .pink.opacity(0.8)]
        case .household:
            return [.orange.opacity(0.7), .brown.opacity(0.5)]
        case .vehicle:
            return [.blue.opacity(0.8), .gray.opacity(0.6)]
        case .custom:
            return [color.color, color.color.opacity(0.6)]
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, titleKey, category, fileName, fileExt
        case loop, premium, previewGainDb, defaultGainDb
        case color, emoji
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        
        let titleString = try container.decode(String.self, forKey: .titleKey)
        titleKey = LocalizedStringKey(titleString)
        
        category = try container.decode(SoundCategory.self, forKey: .category)
        fileName = try container.decode(String.self, forKey: .fileName)
        fileExt = try container.decode(String.self, forKey: .fileExt)
        loop = try container.decode(Bool.self, forKey: .loop)
        premium = try container.decode(Bool.self, forKey: .premium)
        previewGainDb = try container.decodeIfPresent(Float.self, forKey: .previewGainDb)
        defaultGainDb = try container.decode(Float.self, forKey: .defaultGainDb)
        color = try container.decode(CodableColor.self, forKey: .color)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(String(describing: titleKey), forKey: .titleKey)
        try container.encode(category, forKey: .category)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(fileExt, forKey: .fileExt)
        try container.encode(loop, forKey: .loop)
        try container.encode(premium, forKey: .premium)
        try container.encodeIfPresent(previewGainDb, forKey: .previewGainDb)
        try container.encode(defaultGainDb, forKey: .defaultGainDb)
        try container.encode(color, forKey: .color)
        try container.encodeIfPresent(emoji, forKey: .emoji)
    }
}

// MARK: - Sound Pack

struct SoundPack: Identifiable, Codable {
    let id: UUID
    let titleKey: LocalizedStringKey
    let sounds: [Sound]
    let premium: Bool
    let ageMin: Int?
    let ageMax: Int?
    
    init(
        id: UUID = UUID(),
        titleKey: LocalizedStringKey,
        sounds: [Sound],
        premium: Bool = false,
        ageMin: Int? = nil,
        ageMax: Int? = nil
    ) {
        self.id = id
        self.titleKey = titleKey
        self.sounds = sounds
        self.premium = premium
        self.ageMin = ageMin
        self.ageMax = ageMax
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, titleKey, sounds, premium, ageMin, ageMax
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        
        let titleString = try container.decode(String.self, forKey: .titleKey)
        titleKey = LocalizedStringKey(titleString)
        
        sounds = try container.decode([Sound].self, forKey: .sounds)
        premium = try container.decode(Bool.self, forKey: .premium)
        ageMin = try container.decodeIfPresent(Int.self, forKey: .ageMin)
        ageMax = try container.decodeIfPresent(Int.self, forKey: .ageMax)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(String(describing: titleKey), forKey: .titleKey)
        try container.encode(sounds, forKey: .sounds)
        try container.encode(premium, forKey: .premium)
        try container.encodeIfPresent(ageMin, forKey: .ageMin)
        try container.encodeIfPresent(ageMax, forKey: .ageMax)
    }
}

// MARK: - Mix Models (Premium)

enum MixDurationPolicy: Codable {
    case infinite
    case timed(seconds: Int)
}

struct MixTrack: Identifiable, Codable {
    let id: UUID
    let soundId: UUID
    let gain: Float
    let pan: Float // -1.0 (left) to 1.0 (right)
    let mute: Bool
    
    init(
        id: UUID = UUID(),
        soundId: UUID,
        gain: Float = 1.0,
        pan: Float = 0.0,
        mute: Bool = false
    ) {
        self.id = id
        self.soundId = soundId
        self.gain = gain
        self.pan = pan
        self.mute = mute
    }
}

struct Mix: Identifiable, Codable {
    let id: UUID
    let title: String
    let tracks: [MixTrack]
    let durationPolicy: MixDurationPolicy
    
    init(
        id: UUID = UUID(),
        title: String,
        tracks: [MixTrack],
        durationPolicy: MixDurationPolicy = .infinite
    ) {
        self.id = id
        self.title = title
        self.tracks = tracks
        self.durationPolicy = durationPolicy
    }
}

// MARK: - Codable Color Helper

struct CodableColor: Codable, Hashable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    init(_ color: Color) {
        // Note: This is a simplified implementation
        // In a real app, you'd want to properly extract color components
        if color == .white {
            self.red = 1.0; self.green = 1.0; self.blue = 1.0; self.alpha = 1.0
        } else if color == .pink {
            self.red = 1.0; self.green = 0.75; self.blue = 0.8; self.alpha = 1.0
        } else if color == .blue {
            self.red = 0.0; self.green = 0.5; self.blue = 1.0; self.alpha = 1.0
        } else if color == .red {
            self.red = 1.0; self.green = 0.0; self.blue = 0.0; self.alpha = 1.0
        } else {
            self.red = 0.5; self.green = 0.5; self.blue = 0.5; self.alpha = 1.0
        }
    }
    
    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// MARK: - Schedule Models (Future v1.1)

struct SleepSchedule: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let durationMinutes: Int
    let soundId: UUID?
    let mixId: UUID?
    let repeatPattern: UInt8 // Bitmask for days of week
    let enabled: Bool
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        durationMinutes: Int,
        soundId: UUID? = nil,
        mixId: UUID? = nil,
        repeatPattern: UInt8 = 0b1111111, // All days
        enabled: Bool = true
    ) {
        self.id = id
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.soundId = soundId
        self.mixId = mixId
        self.repeatPattern = repeatPattern
        self.enabled = enabled
    }
    
    var repeatDays: [String] {
        var days: [String] = []
        if repeatPattern & 0b0000001 != 0 { days.append("Sunday") }
        if repeatPattern & 0b0000010 != 0 { days.append("Monday") }
        if repeatPattern & 0b0000100 != 0 { days.append("Tuesday") }
        if repeatPattern & 0b0001000 != 0 { days.append("Wednesday") }
        if repeatPattern & 0b0010000 != 0 { days.append("Thursday") }
        if repeatPattern & 0b0100000 != 0 { days.append("Friday") }
        if repeatPattern & 0b1000000 != 0 { days.append("Saturday") }
        return days
    }
} 