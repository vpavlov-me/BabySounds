import Foundation
import SwiftUI

// MARK: - SoundCatalog

/// Manages the catalog of available sounds, sound packs, and user favorites
@MainActor
public final class SoundCatalog: ObservableObject {
    // MARK: - Published Properties

    @Published public private(set) var sounds: [Sound] = []
    @Published public private(set) var soundPacks: [SoundPack] = []
    @Published public var favorites: Set<UUID> = []

    // MARK: - Private Properties

    private var soundsById: [UUID: Sound] = [:]

    // MARK: - Initialization

    public init() {
        loadSounds()
        loadFavorites()
    }

    // MARK: - Public API

    /// Get sounds for a specific category
    public func sounds(for category: SoundCategory) -> [Sound] {
        sounds.filter { $0.category == category }
    }

    /// Get all free sounds
    public var freeSounds: [Sound] {
        sounds.filter { !$0.premium }
    }

    /// Get all premium sounds
    public var premiumSounds: [Sound] {
        sounds.filter { $0.premium }
    }

    /// Get a sound by ID
    public func sound(by id: UUID) -> Sound? {
        soundsById[id]
    }

    /// Toggle favorite status for a sound
    public func toggleFavorite(_ soundId: UUID) {
        if favorites.contains(soundId) {
            favorites.remove(soundId)
        } else {
            // Check free user limitations
            let maxFreeFavorites = 5
            if favorites.count >= maxFreeFavorites {
                // Would need access to subscription service to check premium status
                // For now, allow unlimited favorites in development
                #if DEBUG
                    favorites.insert(soundId)
                #else
                    // In production, this should trigger premium upsell
                    print("SoundCatalog: Free user reached favorites limit")
                    return
                #endif
            } else {
                favorites.insert(soundId)
            }
        }
        saveFavorites()
    }

    /// Check if user can add more favorites (considering premium status)
    public func canAddFavorite(isPremium: Bool) -> Bool {
        let maxFreeFavorites = 5
        return isPremium || favorites.count < maxFreeFavorites
    }

    /// Check if a sound is favorited
    public func isFavorite(_ soundId: UUID) -> Bool {
        favorites.contains(soundId)
    }

    /// Get all favorited sounds
    public var favoriteSounds: [Sound] {
        favorites.compactMap { soundsById[$0] }
    }

    /// Get all sounds (alias for sounds property)
    public var allSounds: [Sound] {
        sounds
    }

    /// Reload sounds from storage
    public func loadSounds() async {
        await MainActor.run {
            loadSounds()
        }
    }

    // MARK: - Private Implementation

    /// Load sounds from bundle JSON
    private func loadSounds() {
        // TODO-DATA: Load sounds from bundle JSON

        Task {
            do {
                try await loadSoundsFromJSON()
                print("SoundCatalog: Successfully loaded sounds from JSON")
            } catch {
                print("SoundCatalog: Failed to load from JSON, using sample data: \(error)")
                // Fallback to sample sounds
                await MainActor.run {
                    self.sounds = createSampleSounds()
                    self.updateSoundsIndex()
                }
            }
        }
    }

    /// Update the sounds by ID index
    private func updateSoundsIndex() {
        soundsById = Dictionary(uniqueKeysWithValues: sounds.map { ($0.id, $0) })
    }

    /// Load user favorites from UserDefaults
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "BabySounds.Favorites"),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data)
        {
            favorites = decoded
        }
    }

    /// Save user favorites to UserDefaults
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: "BabySounds.Favorites")
        }
    }

    /// Create sample sounds for development
    private func createSampleSounds() -> [Sound] {
        [
            Sound(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                titleKey: "White Noise",
                category: .white,
                fileName: "white_noise",
                fileExt: "mp3",
                loop: true,
                premium: false,
                defaultGainDb: 0,
                color: .white,
                emoji: "🌬️"
            ),
            Sound(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                titleKey: "Pink Noise",
                category: .pink,
                fileName: "pink_noise",
                fileExt: "mp3",
                loop: true,
                premium: false,
                defaultGainDb: 0,
                color: .pink,
                emoji: "🌸"
            ),
            Sound(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                titleKey: "Brown Noise",
                category: .brown,
                fileName: "brown_noise",
                fileExt: "mp3",
                loop: true,
                premium: false,
                defaultGainDb: 0,
                color: Color.brown,
                emoji: "🤎"
            ),
            Sound(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                titleKey: "Rain",
                category: .nature,
                fileName: "rain",
                fileExt: "mp3",
                loop: true,
                premium: false,
                defaultGainDb: 0,
                color: .blue,
                emoji: "🌧️"
            ),
            Sound(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
                titleKey: "Ocean Waves",
                category: .nature,
                fileName: "ocean_waves",
                fileExt: "mp3",
                loop: true,
                premium: true,
                defaultGainDb: 0,
                color: .blue,
                emoji: "🌊"
            ),
            Sound(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
                titleKey: "Forest",
                category: .nature,
                fileName: "forest",
                fileExt: "mp3",
                loop: true,
                premium: true,
                defaultGainDb: 0,
                color: .green,
                emoji: "🌲"
            ),
            Sound(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
                titleKey: "Heartbeat",
                category: .womb,
                fileName: "heartbeat",
                fileExt: "mp3",
                loop: true,
                premium: true,
                defaultGainDb: 0,
                color: .red,
                emoji: "❤️"
            ),
            Sound(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
                titleKey: "Womb Sounds",
                category: .womb,
                fileName: "womb_sounds",
                fileExt: "mp3",
                loop: true,
                premium: true,
                defaultGainDb: 0,
                color: .pink,
                emoji: "🤱"
            ),
            Sound(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
                titleKey: "Fan",
                category: .fan,
                fileName: "fan",
                fileExt: "mp3",
                loop: true,
                premium: false,
                defaultGainDb: 0,
                color: .gray,
                emoji: "💨"
            ),
            Sound(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
                titleKey: "Air Conditioner",
                category: .fan,
                fileName: "air_conditioner",
                fileExt: "mp3",
                loop: true,
                premium: false,
                defaultGainDb: 0,
                color: .cyan,
                emoji: "❄️"
            ),
        ]
    }
}

// MARK: - JSON Loading

extension SoundCatalog {
    /// Load sounds from the bundled JSON file
    public func loadSoundsFromJSON() async throws {
        // TODO-DATA: Implement complete JSON loading with color parsing

        guard let url = Bundle.main.url(forResource: "sounds", withExtension: "json") else {
            throw SoundCatalogError.bundleFileNotFound("sounds.json")
        }

        let data = try Data(contentsOf: url)

        // Parse JSON structure
        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let soundsArray = jsonObject?["sounds"] as? [[String: Any]] else {
            throw SoundCatalogError.invalidJSONStructure
        }

        print("SoundCatalog: Found \(soundsArray.count) sounds in JSON")

        // Convert to our Sound models
        var loadedSounds: [Sound] = []

        for (index, soundData) in soundsArray.enumerated() {
            do {
                let sound = try parseSound(from: soundData)
                loadedSounds.append(sound)
                print("SoundCatalog: Loaded sound [\(index)]: \(sound.fileName)")
            } catch {
                print("SoundCatalog: Failed to parse sound at index \(index): \(error)")
                continue
            }
        }

        print("SoundCatalog: Successfully parsed \(loadedSounds.count) sounds")

        await MainActor.run {
            self.sounds = loadedSounds
            self.updateSoundsIndex()
            print("SoundCatalog: Updated UI with \(self.sounds.count) sounds")
        }
    }

    /// Parse a single sound from JSON data
    private func parseSound(from soundData: [String: Any]) throws -> Sound {
        // Required fields
        guard let idString = soundData["id"] as? String,
              let id = UUID(uuidString: idString)
        else {
            throw SoundCatalogError.invalidJSONStructure
        }

        guard let titleKey = soundData["titleKey"] as? String else {
            throw SoundCatalogError.invalidJSONStructure
        }

        guard let categoryString = soundData["category"] as? String,
              let category = SoundCategory(rawValue: categoryString)
        else {
            throw SoundCatalogError.invalidJSONStructure
        }

        guard let fileName = soundData["fileName"] as? String else {
            throw SoundCatalogError.invalidJSONStructure
        }

        // Optional fields with defaults
        let fileExt = soundData["fileExt"] as? String ?? "mp3"
        let loop = soundData["loop"] as? Bool ?? true
        let premium = soundData["premium"] as? Bool ?? false
        let defaultGainDb = soundData["defaultGainDb"] as? Float ?? 0.0
        let emoji = soundData["emoji"] as? String

        // Parse color from JSON
        let color = parseColor(from: soundData["color"]) ?? defaultColor(for: category)

        return Sound(
            id: id,
            titleKey: LocalizedStringKey(titleKey),
            category: category,
            fileName: fileName,
            fileExt: fileExt,
            loop: loop,
            premium: premium,
            defaultGainDb: defaultGainDb,
            color: color,
            emoji: emoji
        )
    }

    /// Parse color from JSON color object
    private func parseColor(from colorData: Any?) -> Color? {
        guard let colorDict = colorData as? [String: Any],
              let red = colorDict["red"] as? Double,
              let green = colorDict["green"] as? Double,
              let blue = colorDict["blue"] as? Double
        else {
            return nil
        }

        let alpha = colorDict["alpha"] as? Double ?? 1.0

        return Color(
            red: red,
            green: green,
            blue: blue,
            opacity: alpha
        )
    }

    /// Get default color for a category if not specified in JSON
    private func defaultColor(for category: SoundCategory) -> Color {
        switch category {
        case .white:
            return .white

        case .pink:
            return .pink

        case .brown:
            return Color.brown

        case .nature:
            return .green

        case .womb:
            return .red

        case .fan:
            return .gray

        case .animal:
            return .orange

        case .transport:
            return .blue

        case .music:
            return .purple

        case .custom:
            return .mint
        }
    }
}

// MARK: - SoundCatalogError

public enum SoundCatalogError: Error, LocalizedError {
    case bundleFileNotFound(String)
    case invalidJSONStructure
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case let .bundleFileNotFound(fileName):
            return "Bundle file not found: \(fileName)"

        case .invalidJSONStructure:
            return "Invalid JSON structure in sounds catalog"

        case let .decodingError(error):
            return "Failed to decode sound catalog: \(error.localizedDescription)"
        }
    }
}
