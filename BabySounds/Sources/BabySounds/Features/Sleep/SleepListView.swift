import SwiftUI

// MARK: - SleepListView

struct SleepListView: View {
    @EnvironmentObject var soundCatalog: SoundCatalog
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var premiumManager: PremiumManager

    @State private var scrollOffset: CGFloat = 0
    @State private var showNowPlaying = false
    @State private var showSearch = false

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                // Main content
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        // Hero section
                        heroSection
                            .padding(.bottom, 24)

                        // Sound categories
                        ForEach(SoundCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            let sounds = soundCatalog.sounds(for: category)

                            if !sounds.isEmpty {
                                Section {
                                    ForEach(sounds, id: \.id) { sound in
                                        SoundCell(sound: sound)
                                            .transition(.asymmetric(
                                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)
                                            ))
                                    }
                                } header: {
                                    SectionHeaderView(title: category.displayName)
                                }
                            }
                        }

                        // Bottom spacing for mini player
                        Spacer()
                            .frame(height: 100)
                    }
                }
                .refreshable {
                    await refreshSounds()
                }
                .background(
                    // Scroll offset tracking
                    GeometryReader { scrollGeometry in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: scrollGeometry.frame(in: .named("scroll")).minY
                            )
                    }
                )
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }

                // Mini Player
                MiniPlayerView(showNowPlaying: $showNowPlaying)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Sleep")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Search button
                    Button {
                        showSearch = true
                        HapticManager.shared.impact(.light)
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.body)
                            .foregroundColor(.primary)
                    }

                    // AirPlay button
                    Button {
                        // Handle AirPlay
                        HapticManager.shared.impact(.light)
                    } label: {
                        Image(systemName: "airplayaudio")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView(isPresented: $showNowPlaying)
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Welcome message
            VStack(spacing: 8) {
                Text("Sleep Sounds")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Peaceful sounds to help you relax and fall asleep")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 16)

            // Quick access buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(quickAccessSounds, id: \.id) { sound in
                        QuickAccessButton(sound: sound)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Quick Access Sounds

    private var quickAccessSounds: [Sound] {
        // Return popular/featured sounds for quick access
        let allSounds = soundCatalog.allSounds
        return Array(allSounds.prefix(5))
    }

    // MARK: - Private Methods

    private func refreshSounds() async {
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await soundCatalog.loadSounds()
        HapticManager.shared.impact(.light)
    }
}

// MARK: - QuickAccessButton

struct QuickAccessButton: View {
    let sound: Sound
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var premiumManager: PremiumManager

    @State private var isPressed = false

    var body: some View {
        Button {
            playSound()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: sound.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

                    Text(sound.displayEmoji)
                        .font(.title2)
                }

                Text(sound.titleKey)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) { pressed in
            isPressed = pressed
        } perform: {
            playSound()
        }
    }

    private func playSound() {
        if sound.premium, !premiumManager.isPremium {
            // Show premium alert
            HapticManager.shared.notification(.warning)
            return
        }

        Task {
            do {
                try await audioManager.playSound(sound)
                HapticManager.shared.impact(.medium)
            } catch {
                print("Failed to play sound: \(error)")
                HapticManager.shared.notification(.error)
            }
        }
    }
}

// MARK: - ScrollOffsetPreferenceKey

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Sound Category Extension

extension SoundCategory {
    var displayName: String {
        switch self {
        case .all:
            return "All"

        case .nature:
            return "Nature"

        case .white:
            return "White Noise"

        case .pink:
            return "Pink Noise"

        case .brown:
            return "Brown Noise"

        case .womb:
            return "Womb Sounds"

        case .fan:
            return "Fan Sounds"
        }
    }

    var icon: String {
        switch self {
        case .all:
            return "music.note.list"

        case .nature:
            return "leaf"

        case .white:
            return "waveform"

        case .pink:
            return "waveform.path"

        case .brown:
            return "waveform.circle"

        case .womb:
            return "heart"

        case .fan:
            return "fanblades"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SleepListView()
            .environmentObject(AudioEngineManager.shared)
            .environmentObject(SoundCatalog())
            .environmentObject(PremiumManager.shared)
    }
}
