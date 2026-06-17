import ActivityKit
import SwiftUI
import WidgetKit

@main
struct BabySoundsWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickStartWidget()
        PlaybackLiveActivityWidget()
    }
}

struct QuickStartEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedPlaybackSnapshot
    let sounds: [WidgetSound]
}

struct QuickStartProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickStartEntry {
        QuickStartEntry(
            date: .now,
            snapshot: .empty,
            sounds: Array(SharedSoundCatalog.sounds.prefix(context.family == .systemSmall ? 1 : 4))
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickStartEntry) -> Void) {
        completion(makeEntry(for: context.family))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickStartEntry>) -> Void) {
        completion(Timeline(entries: [makeEntry(for: context.family)], policy: .after(.now.addingTimeInterval(15 * 60))))
    }

    private func makeEntry(for family: WidgetFamily) -> QuickStartEntry {
        let snapshot = SharedPlaybackSnapshotReader.load()
        let limit = family == .systemSmall ? 1 : 4
        return QuickStartEntry(
            date: .now,
            snapshot: snapshot,
            sounds: SharedSoundCatalog.preferredSounds(from: snapshot, limit: limit)
        )
    }
}

struct QuickStartWidget: Widget {
    let kind = "QuickStartWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickStartProvider()) { entry in
            QuickStartWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.07, blue: 0.13),
                            Color(red: 0.01, green: 0.02, blue: 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("BabySounds")
        .description("Quickly reopen a calming sound for bedtime.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QuickStartWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuickStartEntry

    var body: some View {
        if family == .systemSmall {
            SmallQuickStartView(entry: entry)
        } else {
            MediumQuickStartView(entry: entry)
        }
    }
}

struct SmallQuickStartView: View {
    let entry: QuickStartEntry

    private var sound: WidgetSound {
        entry.sounds.first ?? SharedSoundCatalog.sounds[0]
    }

    var body: some View {
        Link(destination: playURL(for: sound)) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: sound.symbolName)
                    .font(.title2)
                    .foregroundStyle(.pink)

                Spacer()

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.snapshot.isPlaying ? "Playing" : "Start")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                    Text(sound.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
        }
        .widgetAccentable()
    }
}

struct MediumQuickStartView: View {
    let entry: QuickStartEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.snapshot.isPlaying ? "Playing" : "Quick Start")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(entry.snapshot.currentSoundTitle ?? "Bedtime sounds")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(.pink)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(entry.sounds) { sound in
                    Link(destination: playURL(for: sound)) {
                        HStack(spacing: 8) {
                            Image(systemName: sound.symbolName)
                                .frame(width: 20)
                                .foregroundStyle(.pink)
                            Text(sound.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        }
                    }
                }
            }
        }
        .padding()
        .widgetAccentable()
    }
}

struct PlaybackLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BabySoundsPlaybackAttributes.self) { context in
            LiveActivityLockScreenView(context: context)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.pink)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.status, systemImage: context.state.isPlaying ? "pause.fill" : "stop.fill")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let timerEndDate = context.state.timerEndDate {
                        Text(timerEndDate, style: .timer)
                            .font(.caption.monospacedDigit())
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.soundTitle)
                        .font(.headline)
                        .lineLimit(1)
                }
            } compactLeading: {
                Image(systemName: context.state.isPlaying ? "moon.zzz.fill" : "moon.fill")
                    .foregroundStyle(.pink)
            } compactTrailing: {
                if let timerEndDate = context.state.timerEndDate {
                    Text(timerEndDate, style: .timer)
                        .font(.caption2.monospacedDigit())
                } else {
                    Image(systemName: "waveform")
                        .foregroundStyle(.pink)
                }
            } minimal: {
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(.pink)
            }
            .widgetURL(URL(string: "babysounds://open"))
            .keylineTint(.pink)
        }
    }
}

struct LiveActivityLockScreenView: View {
    let context: ActivityViewContext<BabySoundsPlaybackAttributes>

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.pink.opacity(0.18))
                Image(systemName: context.state.isPlaying ? "moon.zzz.fill" : "moon.fill")
                    .foregroundStyle(.pink)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(context.state.soundTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(context.state.status)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            if let timerEndDate = context.state.timerEndDate {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(timerEndDate, style: .timer)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white)
                    Text("Timer")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.62))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private func playURL(for sound: WidgetSound) -> URL {
    URL(string: "babysounds://play?soundId=\(sound.slug)")!
}
