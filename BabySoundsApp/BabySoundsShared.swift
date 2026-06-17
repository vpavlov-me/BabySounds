import ActivityKit
import Foundation

enum BabySoundsShared {
    static let appGroupId = "group.com.babysounds.app"
    static let snapshotKey = "BabySoundsPlaybackSnapshot"
    static let defaultSoundSlug = "white-noise"
}

struct SharedPlaybackSnapshot: Codable {
    var currentSoundId: String?
    var currentSoundTitle: String?
    var isPlaying: Bool
    var timerEndDate: Date?
    var lastPlayedSoundId: String?
    var favoriteIds: [String]
    var status: String

    static let empty = SharedPlaybackSnapshot(
        currentSoundId: nil,
        currentSoundTitle: nil,
        isPlaying: false,
        timerEndDate: nil,
        lastPlayedSoundId: nil,
        favoriteIds: [],
        status: "Stopped"
    )
}

struct BabySoundsPlaybackAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var soundTitle: String
        var isPlaying: Bool
        var timerEndDate: Date?
        var status: String
    }

    var sessionName: String
}

struct WidgetSound: Identifiable, Hashable {
    let id: String
    let slug: String
    let title: String
    let subtitle: String
    let symbolName: String
}

enum SharedSoundCatalog {
    static let sounds: [WidgetSound] = [
        WidgetSound(id: "00000000-0000-0000-0000-000000000001", slug: "white-noise", title: "White Noise", subtitle: "White Noise", symbolName: "waveform"),
        WidgetSound(id: "00000000-0000-0000-0000-000000000002", slug: "pink-noise", title: "Pink Noise", subtitle: "Pink Noise", symbolName: "waveform.path.ecg"),
        WidgetSound(id: "00000000-0000-0000-0000-000000000003", slug: "deep-pink", title: "Deep Pink", subtitle: "Pink Noise", symbolName: "waveform.path.ecg.rectangle"),
        WidgetSound(id: "00000000-0000-0000-0000-000000000004", slug: "brown-noise", title: "Brown Noise", subtitle: "Brown Noise", symbolName: "wave.3.right"),
        WidgetSound(id: "00000000-0000-0000-0000-000000000005", slug: "air-conditioner", title: "Air Conditioner", subtitle: "Fan & Air", symbolName: "wind"),
        WidgetSound(id: "00000000-0000-0000-0000-000000000006", slug: "box-fan", title: "Box Fan", subtitle: "Fan & Air", symbolName: "fan.fill"),
        WidgetSound(id: "00000000-0000-0000-0000-000000000007", slug: "ocean-waves", title: "Ocean Waves", subtitle: "Nature", symbolName: "water.waves"),
        WidgetSound(id: "00000000-0000-0000-0000-000000000008", slug: "forest-rain", title: "Forest Rain", subtitle: "Nature", symbolName: "cloud.rain.fill"),
        WidgetSound(id: "00000000-0000-0000-0000-000000000009", slug: "gentle-stream", title: "Gentle Stream", subtitle: "Nature", symbolName: "drop.fill"),
        WidgetSound(id: "00000000-0000-0000-0000-000000000010", slug: "heartbeat", title: "Heartbeat", subtitle: "Womb Sounds", symbolName: "heart.fill"),
        WidgetSound(id: "00000000-0000-0000-0000-000000000011", slug: "womb-environment", title: "Womb Environment", subtitle: "Womb Sounds", symbolName: "waveform.path.ecg")
    ]

    static func sound(forSlug slug: String?) -> WidgetSound? {
        guard let slug else { return nil }
        return sounds.first { $0.slug == slug }
    }

    static func sound(forId id: String?) -> WidgetSound? {
        guard let id else { return nil }
        return sounds.first { $0.id.caseInsensitiveCompare(id) == .orderedSame }
    }

    static func preferredSounds(from snapshot: SharedPlaybackSnapshot, limit: Int) -> [WidgetSound] {
        var result: [WidgetSound] = []

        for id in snapshot.favoriteIds {
            if let sound = sound(forId: id), !result.contains(sound) {
                result.append(sound)
            }
            if result.count == limit { return result }
        }

        for slug in [snapshot.lastPlayedSoundId, snapshot.currentSoundId, BabySoundsShared.defaultSoundSlug] {
            if let sound = sound(forSlug: slug), !result.contains(sound) {
                result.append(sound)
            }
            if result.count == limit { return result }
        }

        for sound in sounds where !result.contains(sound) {
            result.append(sound)
            if result.count == limit { return result }
        }

        return result
    }
}

enum SharedPlaybackSnapshotReader {
    static func load() -> SharedPlaybackSnapshot {
        let defaults = UserDefaults(suiteName: BabySoundsShared.appGroupId) ?? .standard

        guard let data = defaults.data(forKey: BabySoundsShared.snapshotKey),
              let snapshot = try? JSONDecoder().decode(SharedPlaybackSnapshot.self, from: data)
        else {
            return .empty
        }

        return snapshot
    }
}
