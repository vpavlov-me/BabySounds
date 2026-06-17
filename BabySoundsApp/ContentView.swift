import AVFoundation
import ActivityKit
import MediaPlayer
import StoreKit
import SwiftUI
import UIKit
@preconcurrency import UserNotifications

// MARK: - HapticManager

@MainActor
class HapticManager {
    static let shared = HapticManager()

    private init() {}

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // Specific feedback for baby app
    func playSound() {
        impact(.light)
    }

    func stopSound() {
        impact(.medium)
    }

    func favoriteToggle() {
        impact(.light)
    }

    func volumeChange() {
        selection()
    }

    func timerStart() {
        notification(.success)
    }

    func fadeStart() {
        impact(.soft)
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var soundManager = RealSoundManager()
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var favoritesManager = FavoritesManager.shared

    var body: some View {
        TabView {
            SoundsView()
                .environmentObject(soundManager)
                .environmentObject(premiumManager)
                .tabItem {
                    Image(systemName: "music.note")
                    Text("Sounds")
                }

            FavoritesView()
                .environmentObject(soundManager)
                .environmentObject(premiumManager)
                .environmentObject(favoritesManager)
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }

            SettingsView()
                .environmentObject(soundManager)
                .environmentObject(premiumManager)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .accentColor(.pink)
        .onAppear {
            soundManager.initializeAudio()
        }
        .onOpenURL { url in
            soundManager.handleDeepLink(url)
        }
    }
}

// MARK: - SoundsView

struct SoundsView: View {
    @EnvironmentObject var soundManager: RealSoundManager
    @EnvironmentObject var premiumManager: PremiumManager
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedSound: RealSound?
    @State private var showingPremiumSheet = false

    var body: some View {
        NavigationView {
            List(soundManager.allSounds) { sound in
                SoundRow(
                    sound: sound,
                    isPlaying: soundManager.isPlaying(sound.id),
                    isFavorite: favoritesManager.isFavorite(sound),
                    onTap: {
                        if sound.premium, !premiumManager.isPremium {
                            showingPremiumSheet = true
                        } else {
                            selectedSound = sound
                        }
                    },
                    onFavoriteTap: {
                        favoritesManager.toggleFavorite(sound)
                    },
                    onPlayTap: {
                        if sound.premium, !premiumManager.isPremium {
                            showingPremiumSheet = true
                        } else {
                            soundManager.toggleSound(sound)
                        }
                    }
                )
            }
            .navigationTitle("Sounds")
            .safeAreaInset(edge: .bottom) {
                if !soundManager.playingTracks.isEmpty {
                    NowPlayingBar()
                        .environmentObject(soundManager)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $selectedSound) { sound in
            PlayerView(sound: sound)
                .environmentObject(soundManager)
                .environmentObject(premiumManager)
        }
        .sheet(isPresented: $showingPremiumSheet) {
            PremiumUpgradeView()
                .environmentObject(premiumManager)
        }
    }
}

// MARK: - SoundRow

struct SoundRow: View {
    let sound: RealSound
    let isPlaying: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavoriteTap: () -> Void
    let onPlayTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                SoundArtwork(sound: sound, size: 56, iconSize: 24)
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 3) {
                    Text(sound.title)
                        .foregroundStyle(.primary)
                    Text(isPlaying ? "Now playing" : sound.category.localizedName)
                        .font(.caption)
                        .foregroundStyle(isPlaying ? Color.pink : Color.secondary)
                }

                Spacer()

                if sound.premium {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(Color.orange)
                }

                Button(action: onFavoriteTap) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? Color.pink : Color.secondary)
                }
                .buttonStyle(.plain)

                Button(action: onPlayTap) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.pink)
                }
                .buttonStyle(.plain)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - LoadingView

struct LoadingView: View {
    @State private var rotationAngle: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.pink.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(Color.pink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(Angle(degrees: rotationAngle))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: rotationAngle)
            }

            Text("Loading...")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
        }
        .onAppear {
            rotationAngle = 360
        }
    }
}

// MARK: - ErrorView

struct ErrorView: View {
    let message: String
    let onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text("Oops!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let onRetry = onRetry {
                Button(action: {
                    HapticManager.shared.impact(.medium)
                    onRetry()
                }) {
                    Text("Try Again")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.pink)
                        )
                }
            }
        }
    }
}

// MARK: - PlayerView

struct PlayerView: View {
    let sound: RealSound
    @EnvironmentObject var soundManager: RealSoundManager
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var sleepTimer = SleepTimerManager.shared
    @StateObject private var fadeOutManager = FadeOutManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingTimer = false
    @State private var timerHours = 0
    @State private var timerMinutes = 10

    private var isPlaying: Bool {
        soundManager.isPlaying(sound.id)
    }

    private var volume: Double {
        soundManager.getVolume(for: sound.id)
    }

    var body: some View {
        NavigationView {
            List {
                // Cover image
                Section {
                    SoundArtwork(sound: sound, size: 260, iconSize: 86)
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                }
                .listRowInsets(EdgeInsets())

                // Playback controls
                Section {
                    HStack {
                        Image(systemName: "speaker.fill").foregroundStyle(.secondary)
                        Slider(
                            value: Binding(
                                get: { volume },
                                set: { soundManager.setVolume($0, for: sound.id) }
                            ),
                            in: 0...1
                        )
                        .tint(.pink)
                        Image(systemName: "speaker.wave.2.fill").foregroundStyle(.secondary)
                    }

                    HStack {
                        Spacer()
                        Button(action: { soundManager.toggleSound(sound) }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(Color.pink)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                // Timer / Fade status
                if sleepTimer.isActive || fadeOutManager.isActiveFade {
                    Section("Active") {
                        if sleepTimer.isActive {
                            Label("Timer: \(sleepTimer.formattedTimeRemaining)", systemImage: "timer")
                                .foregroundStyle(Color.orange)
                        }
                        if fadeOutManager.isActiveFade {
                            Label("Fade out: \(fadeOutManager.formattedTimeRemaining)", systemImage: "minus.magnifyingglass")
                                .foregroundStyle(Color.blue)
                        }
                    }
                }

                // Actions
                Section {
                    Button {
                        if sleepTimer.isActive {
                            sleepTimer.stopTimer()
                        } else {
                            showingTimer = true
                        }
                    } label: {
                        Label(
                            sleepTimer.isActive ? "Cancel Timer (\(sleepTimer.formattedTimeRemaining))" : "Set Sleep Timer",
                            systemImage: "timer"
                        )
                        .foregroundStyle(sleepTimer.isActive ? Color.orange : Color.primary)
                    }

                    Button {
                        if fadeOutManager.isActiveFade {
                            soundManager.stopFadeOut()
                        } else {
                            soundManager.fadeOutAllSounds(duration: 30.0)
                        }
                    } label: {
                        Label(
                            fadeOutManager.isActiveFade ? "Cancel Fade Out" : "Fade Out",
                            systemImage: "minus.magnifyingglass"
                        )
                        .foregroundStyle(fadeOutManager.isActiveFade ? Color.orange : Color.primary)
                    }
                }
            }
            .navigationTitle(sound.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !soundManager.isPlaying(sound.id) {
                    soundManager.toggleSound(sound)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.favoriteToggle()
                        favoritesManager.toggleFavorite(sound)
                    } label: {
                        Image(systemName: favoritesManager.isFavorite(sound) ? "heart.fill" : "heart")
                            .foregroundStyle(favoritesManager.isFavorite(sound) ? Color.pink : Color.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTimer) {
            TimerPickerView(
                hours: $timerHours,
                minutes: $timerMinutes,
                isPresented: $showingTimer
            )
            .environmentObject(soundManager)
            .environmentObject(PremiumManager.shared)
        }
    }
}

// MARK: - BundledArtwork

struct BundledArtwork: View {
    let name: String

    var body: some View {
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "DesignAssets"),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [.blue.opacity(0.32), .indigo.opacity(0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - SoundArtwork

struct SoundArtwork: View {
    let sound: RealSound
    let size: CGFloat
    let iconSize: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: min(size * 0.18, 28))
            .overlay {
                BundledArtwork(name: sound.artworkName)
                    .clipShape(RoundedRectangle(cornerRadius: min(size * 0.18, 28)))
                    .overlay {
                        LinearGradient(
                            colors: [.clear, .black.opacity(size > 120 ? 0.18 : 0.10)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: min(size * 0.18, 28)))
                    }
            }
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: min(size * 0.18, 28))
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
            .clipped()
            .accessibilityHidden(true)
    }
}

// MARK: - TimerPickerView

struct TimerPickerView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var isPresented: Bool
    @EnvironmentObject var soundManager: RealSoundManager
    @EnvironmentObject var premiumManager: PremiumManager
    @StateObject private var sleepTimer = SleepTimerManager.shared
    @State private var showingPremiumSheet = false

    private let timerOptions = [15, 30, 45, 60]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Sleep Timer")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                if sleepTimer.isActive {
                    VStack(spacing: 12) {
                        Label(sleepTimer.formattedTimeRemaining, systemImage: "timer")
                            .font(.title3)
                            .foregroundStyle(Color.orange)

                        Button("Cancel Timer") {
                            sleepTimer.stopTimer()
                            SharedPlaybackStore.shared.clearTimer()
                            if let sound = soundManager.currentSound {
                                PlaybackLiveActivityController.startOrUpdate(
                                    soundTitle: sound.title,
                                    isPlaying: true,
                                    status: "Playing"
                                )
                            }
                            isPresented = false
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                    .padding(.vertical, 8)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(timerOptions, id: \.self) { option in
                        Button {
                            startTimer(minutes: option)
                        } label: {
                            VStack(spacing: 6) {
                                Text("\(option)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("min")
                                    .font(.caption)
                                if option > 30 && !premiumManager.isPremium {
                                    Label("Premium", systemImage: "crown.fill")
                                        .font(.caption2)
                                        .foregroundStyle(Color.orange)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 92)
                        }
                        .buttonStyle(.bordered)
                        .tint(option > 30 && !premiumManager.isPremium ? .orange : .pink)
                    }
                }

                Text("The timer ends with a gentle fade out.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 28)
            .padding(.horizontal, 20)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumUpgradeView()
                    .environmentObject(premiumManager)
            }
        }
    }

    private func startTimer(minutes: Int) {
        guard minutes <= 30 || premiumManager.isPremium else {
            showingPremiumSheet = true
            return
        }

        sleepTimer.startTimer(duration: TimeInterval(minutes * 60)) {
            Task { @MainActor in
                soundManager.fadeOutAllSounds(duration: 30.0)
            }
        }
        let endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        SharedPlaybackStore.shared.updateTimer(endDate: endDate)
        if let sound = soundManager.currentSound {
            PlaybackLiveActivityController.startOrUpdate(
                soundTitle: sound.title,
                isPlaying: true,
                timerEndDate: endDate,
                status: "Timer"
            )
        }
        isPresented = false
    }
}

// MARK: - NowPlayingBar

struct NowPlayingBar: View {
    @EnvironmentObject var soundManager: RealSoundManager
    @StateObject private var sleepTimer = SleepTimerManager.shared
    @StateObject private var fadeOutManager = FadeOutManager.shared

    var body: some View {
        if let firstPlayingSound = soundManager.currentSound {
            HStack(spacing: 12) {
                // Sound icon
                SoundArtwork(sound: firstPlayingSound, size: 40, iconSize: 18)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(firstPlayingSound.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)

                    if sleepTimer.isActive || fadeOutManager.isActiveFade {
                        HStack(spacing: 8) {
                            if sleepTimer.isActive {
                                HStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text(sleepTimer.formattedTimeRemaining)
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }

                            if fadeOutManager.isActiveFade {
                                HStack(spacing: 4) {
                                    Image(systemName: "minus.magnifyingglass")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                    Text(fadeOutManager.formattedTimeRemaining)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    } else {
                        Text("Playing") // Placeholder
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Controls
                HStack(spacing: 16) {
                    Button(action: {
                        soundManager.toggleSound(firstPlayingSound)
                    }) {
                        Image(systemName: "pause.fill")
                            .font(.title3)
                            .foregroundColor(.pink)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - FavoritesManager

@MainActor
class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    @Published var favoriteIds: Set<UUID> = []

    private let userDefaultsKey = "FavoriteSounds"

    private init() {
        loadFavorites()
    }

    func toggleFavorite(_ sound: RealSound) {
        if favoriteIds.contains(sound.id) {
            favoriteIds.remove(sound.id)
            print("❤️ Removed \(sound.title) from favorites")
        } else {
            favoriteIds.insert(sound.id)
            print("❤️ Added \(sound.title) to favorites")
        }
        saveFavorites()
        SharedPlaybackStore.shared.updateFavorites(favoriteIds)
    }

    func isFavorite(_ sound: RealSound) -> Bool {
        return favoriteIds.contains(sound.id)
    }

    private func saveFavorites() {
        let idStrings = favoriteIds.map { $0.uuidString }
        UserDefaults.standard.set(idStrings, forKey: userDefaultsKey)
        print("💾 Saved \(favoriteIds.count) favorites")
    }

    private func loadFavorites() {
        if let idStrings = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            favoriteIds = Set(idStrings.compactMap { UUID(uuidString: $0) })
            print("📖 Loaded \(favoriteIds.count) favorites")
        }
        SharedPlaybackStore.shared.updateFavorites(favoriteIds)
    }
}

// MARK: - FavoritesView

struct FavoritesView: View {
    @EnvironmentObject var soundManager: RealSoundManager
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedSound: RealSound?

    var favoriteSounds: [RealSound] {
        soundManager.allSounds.filter { favoritesManager.isFavorite($0) }
    }

    var body: some View {
        NavigationView {
            Group {
                if favoriteSounds.isEmpty {
                    EmptyFavoritesView()
                } else {
                    List(favoriteSounds) { sound in
                        SoundRow(
                            sound: sound,
                            isPlaying: soundManager.isPlaying(sound.id),
                            isFavorite: true,
                            onTap: {
                                selectedSound = sound
                            },
                            onFavoriteTap: {
                                favoritesManager.toggleFavorite(sound)
                            },
                            onPlayTap: {
                                soundManager.toggleSound(sound)
                            }
                        )
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $selectedSound) { sound in
            PlayerView(sound: sound)
                .environmentObject(soundManager)
                .environmentObject(FavoritesManager.shared)
        }
    }
}

// MARK: - EmptyFavoritesView

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("No Favorite Sounds")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Tap the heart icon on any sound to add it to your favorites")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - PremiumUpgradeView

struct PremiumUpgradeView: View {
    @EnvironmentObject var premiumManager: PremiumManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 40)

                        // Premium Icon
                        Image(systemName: "crown.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)

                        // Title
                        VStack(spacing: 16) {
                            Text("Unlock Premium Sounds")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Text("Unlock premium sounds and longer sleep timers for calm nights.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                        }

                        // Features
                        VStack(spacing: 16) {
                            FeatureRow(
                                icon: "music.note.list",
                                title: "Premium Sounds",
                                subtitle: "More calming sounds when you need them"
                            )
                            FeatureRow(
                                icon: "timer",
                                title: "Extended Sleep Timer",
                                subtitle: "45 and 60 minute timer options"
                            )
                        }
                        .padding(.horizontal, 20)

                        // Pricing
                        VStack(spacing: 16) {
                            if premiumManager.availableProducts.isEmpty {
                                // Loading state
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Loading plans...")
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 56)
                            } else {
                                // Show real StoreKit products
                                ForEach(premiumManager.availableProducts, id: \.id) { product in
                                    ProductCard(product: product, premiumManager: premiumManager, dismiss: dismiss)
                                }
                            }

                            Button("Restore Purchases") {
                                Task {
                                    await premiumManager.restorePurchases()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - FeatureRow

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - ProductCard

struct ProductCard: View {
    let product: Product
    let premiumManager: PremiumManager
    let dismiss: DismissAction

    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title2)
                        .fontWeight(.bold)

                    if product.id == "baby.annual" {
                        Text("Save 50%")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
            }

            Button(action: {
                Task {
                    isLoading = true
                    await premiumManager.purchaseProduct(product)
                    isLoading = false

                    if premiumManager.isPremium {
                        dismiss()
                    }
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Start 7-Day Free Trial")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(product.id == "baby.annual" ? Color.green : Color.blue)
                )
            }
            .disabled(isLoading || premiumManager.isLoading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            product.id == "baby.annual" ? Color.green : Color.blue,
                            lineWidth: product.id == "baby.annual" ? 2 : 1
                        )
                )
        )
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var soundManager: RealSoundManager
    @EnvironmentObject var premiumManager: PremiumManager
    @State private var showingPremiumSheet = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: premiumManager.isPremium ? "crown.fill" : "crown")
                            .foregroundColor(premiumManager.isPremium ? .orange : .gray)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(premiumManager.isPremium ? "Premium Active" : "Free Plan")
                                .foregroundColor(.primary)
                            Text(premiumManager.isPremium ? "Premium Sounds and Extended Timer unlocked" : "Premium unlocks premium sounds and 45/60 minute timers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if !premiumManager.isPremium {
                            Button("Upgrade") {
                                showingPremiumSheet = true
                            }
                            .font(.caption)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }

                    Button("Restore Purchases") {
                        Task {
                            await premiumManager.restorePurchases()
                        }
                    }
                    .foregroundColor(.blue)
                } header: {
                    Text("PREMIUM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button {
                        open(URL(string: "mailto:support@babysounds.app?subject=Baby%20Sounds%20Feedback"))
                    } label: {
                        Label("Send Feedback", systemImage: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)

                    Button {
                        open(URL(string: "https://apps.apple.com/app/id6670503696?action=write-review"))
                    } label: {
                        Label("Rate App", systemImage: "star.fill")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("SUPPORT")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button {
                        open(URL(string: "https://babysounds.app/privacy"))
                    } label: {
                        SettingsLinkRow(icon: "hand.raised.fill", title: "Privacy Policy")
                    }
                    .buttonStyle(.plain)

                    Button {
                        open(URL(string: "https://babysounds.app/terms"))
                    } label: {
                        SettingsLinkRow(icon: "doc.text.fill", title: "Terms of Use")
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("LEGAL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } footer: {
                    Text("BabySounds 1.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingPremiumSheet) {
            PremiumUpgradeView()
                .environmentObject(premiumManager)
        }
    }

    private func open(_ url: URL?) {
        guard let url else { return }
        UIApplication.shared.open(url)
    }
}

struct SettingsLinkRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - SoundCategory

enum SoundCategory: String, CaseIterable, Codable {
    case all
    case nature
    case white
    case pink
    case brown
    case womb
    case fan

    var localizedName: String {
        switch self {
        case .all:    return "All"
        case .nature: return "Nature"
        case .white:  return "White Noise"
        case .pink:   return "Pink Noise"
        case .brown:  return "Brown Noise"
        case .womb:   return "Womb Sounds"
        case .fan:    return "Fan & Air"
        }
    }

    var emoji: String {
        switch self {
        case .all:    return "🎵"
        case .nature: return "🌿"
        case .white: return "🌬️"
        case .pink: return "🌸"
        case .brown: return "🤎"
        case .womb: return "❤️"
        case .fan: return "💨"
        }
    }

    var sfSymbol: String {
        switch self {
        case .all:    return "square.grid.2x2.fill"
        case .nature: return "leaf.fill"
        case .white:  return "speaker.wave.3.fill"
        case .pink:   return "waveform"
        case .brown:  return "wave.3.right"
        case .womb:   return "heart.fill"
        case .fan:    return "wind"
        }
    }
}

// MARK: - Sound Generator Types

enum SoundGeneratorType {
    case white, tvStatic
    case pink, deepPink
    case brown, red
    case airConditioner, boxFan
    case ocean, rain, stream, thunder
    case heartbeat, womb
}

// MARK: - Noise Generator State (runs on audio thread)

final class NoiseGeneratorState: @unchecked Sendable {
    let type: SoundGeneratorType
    let sampleRate: Double
    private var sampleIndex: Int64 = 0

    // Pink noise state (Paul Kellet algorithm)
    private var pk_b0: Float = 0, pk_b1: Float = 0, pk_b2: Float = 0
    private var pk_b3: Float = 0, pk_b4: Float = 0, pk_b5: Float = 0, pk_b6: Float = 0

    // Brown noise state
    private var brownOut: Float = 0
    private var brownOut2: Float = 0

    // LFO phase (radians)
    private var lfoPhase: Double = 0

    // Thunder state
    private var thunderCountdown: Int = 0

    init(type: SoundGeneratorType, sampleRate: Double) {
        self.type = type
        self.sampleRate = sampleRate
        lfoPhase = Double.random(in: 0...(2 * .pi))
        thunderCountdown = Int(sampleRate * Double.random(in: 4...10))
    }

    func nextSample() -> Float {
        sampleIndex &+= 1
        switch type {
        case .white:          return white()
        case .tvStatic:       return tvStatic()
        case .pink:           return pink() * 0.50
        case .deepPink:       return pink() * 0.62
        case .brown:          return brownNoise()
        case .red:            return brownNoise() * 1.10
        case .airConditioner: return airConditioner()
        case .boxFan:         return boxFan()
        case .ocean:          return ocean()
        case .rain:           return rain()
        case .stream:         return stream()
        case .thunder:        return thunder()
        case .heartbeat:      return heartbeat()
        case .womb:           return wombSound()
        }
    }

    // MARK: White noise
    private func white() -> Float {
        return Float.random(in: -0.45...0.45)
    }

    // MARK: TV Static – white with random amplitude drops
    private func tvStatic() -> Float {
        let w = Float.random(in: -0.45...0.45)
        return Float.random(in: 0...1) > 0.03 ? w : w * 0.08
    }

    // MARK: Pink noise – Paul Kellet algorithm
    private func pink() -> Float {
        let w = Float.random(in: -1...1)
        pk_b0 = 0.99886 * pk_b0 + w * 0.0555179
        pk_b1 = 0.99332 * pk_b1 + w * 0.0750759
        pk_b2 = 0.96900 * pk_b2 + w * 0.1538520
        pk_b3 = 0.86650 * pk_b3 + w * 0.3104856
        pk_b4 = 0.55000 * pk_b4 + w * 0.5329522
        pk_b5 = -0.7616 * pk_b5 - w * 0.0168980
        let out = (pk_b0 + pk_b1 + pk_b2 + pk_b3 + pk_b4 + pk_b5 + pk_b6 + w * 0.5362) * 0.11
        pk_b6 = w * 0.115926
        return out
    }

    // MARK: Brown noise – leaky integrator of white
    private func brownNoise() -> Float {
        let w = Float.random(in: -1...1)
        brownOut = (brownOut + 0.02 * w) / 1.02
        return brownOut * 3.5
    }

    // MARK: Air conditioner – brown + subtle 60 Hz hum
    private func airConditioner() -> Float {
        let w = Float.random(in: -1...1)
        brownOut = (brownOut + 0.02 * w) / 1.02
        let b = brownOut * 3.0
        let hum = sin(Float(sampleIndex) * 2.0 * .pi * 60.0 / Float(sampleRate)) * 0.015
        return (b + hum) * 0.80
    }

    // MARK: Box fan – pink with rotational ~7.5 Hz AM
    private func boxFan() -> Float {
        let p = pink()
        let mod = 0.85 + 0.15 * sin(Float(sampleIndex) * 2.0 * .pi * 7.5 / Float(sampleRate))
        return p * mod * 0.60
    }

    // MARK: Ocean waves – pink with slow 0.1 Hz amplitude envelope
    private func ocean() -> Float {
        let p = pink()
        lfoPhase += (2.0 * .pi * 0.10) / sampleRate
        if lfoPhase >= 2.0 * .pi { lfoPhase -= 2.0 * .pi }
        let env = 0.20 + 0.80 * (sin(Float(lfoPhase)) * 0.5 + 0.5)
        return p * env * 0.55
    }

    // MARK: Forest rain – pink base + sparse droplet crackles
    private func rain() -> Float {
        let base = pink() * 0.40
        if Int.random(in: 0..<180) == 0 {
            return base + Float.random(in: -0.22...0.22)
        }
        return base
    }

    // MARK: Gentle stream – pink with medium 1.5 Hz AM
    private func stream() -> Float {
        let p = pink()
        lfoPhase += (2.0 * .pi * 1.5) / sampleRate
        if lfoPhase >= 2.0 * .pi { lfoPhase -= 2.0 * .pi }
        let env = 0.50 + 0.50 * sin(Float(lfoPhase))
        return p * env * 0.55
    }

    // MARK: Thunderstorm – rain + occasional decaying deep rumble
    private func thunder() -> Float {
        let rainBase = pink() * 0.30
        thunderCountdown -= 1
        if thunderCountdown <= 0 {
            thunderCountdown = Int(sampleRate * Double.random(in: 6...16))
        }
        let rumbleDuration = Int(sampleRate * 2.2)
        if thunderCountdown < rumbleDuration {
            let decay = Float(thunderCountdown) / Float(rumbleDuration)
            let w = Float.random(in: -1...1)
            brownOut = (brownOut + 0.02 * w) / 1.02
            return rainBase + brownOut * 3.5 * decay * 0.65
        }
        return rainBase
    }

    // MARK: Heartbeat – ~65 BPM lub-dub + brown background
    private func heartbeat() -> Float {
        let period = sampleRate * 60.0 / 65.0
        let phase = Double(sampleIndex).truncatingRemainder(dividingBy: period) / period
        var beat: Float = 0
        if phase < 0.04 {
            let t = Float(phase / 0.04)
            beat = sin(t * .pi) * exp(-8.0 * t) * 0.80
        } else if phase >= 0.07 && phase < 0.12 {
            let t = Float((phase - 0.07) / 0.05)
            beat = sin(t * .pi) * exp(-9.0 * t) * 0.50
        }
        let w = Float.random(in: -1...1)
        brownOut2 = (brownOut2 + 0.02 * w) / 1.02
        return beat + brownOut2 * 0.90
    }

    // MARK: Womb – ~55 BPM fetal heartbeat + deep brown rumble
    private func wombSound() -> Float {
        let period = sampleRate * 60.0 / 55.0
        let phase = Double(sampleIndex).truncatingRemainder(dividingBy: period) / period
        var beat: Float = 0
        if phase < 0.05 {
            let t = Float(phase / 0.05)
            beat = sin(t * .pi) * exp(-6.0 * t) * 0.55
        }
        let w = Float.random(in: -1...1)
        brownOut = (brownOut + 0.02 * w) / 1.02
        return (beat + brownOut * 2.0) * 0.60
    }

    // Creates an AVAudioSourceNode whose render block runs on the audio thread
    // (no @MainActor isolation — this is a plain method on a non-actor class)
    func makeSourceNode(format: AVAudioFormat) -> AVAudioSourceNode {
        AVAudioSourceNode(format: format) { [self] _, _, frameCount, audioBufferList in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let sample = self.nextSample()
                for buffer in ablPointer {
                    let buf = UnsafeMutableBufferPointer<Float>(buffer)
                    if frame < buf.count { buf[frame] = sample }
                }
            }
            return noErr
        }
    }
}

// MARK: - RealSound

// Реальная модель Sound (упрощенная версия)
struct RealSound: Identifiable {
    let id: UUID
    let title: String
    let category: SoundCategory
    let premium: Bool
    let color: Color
    let emoji: String

    init(
        title: String,
        id: UUID,
        category: SoundCategory,
        premium: Bool = false,
        color: Color,
        emoji: String? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.premium = premium
        self.color = color
        self.emoji = emoji ?? category.emoji
    }

    var slug: String {
        title
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    var artworkName: String {
        switch title {
        case "White Noise", "Pink Noise", "Deep Pink", "Brown Noise":
            return "white-noise"
        case "Air Conditioner", "Box Fan":
            return "fan"
        case "Ocean Waves":
            return "ocean"
        case "Forest Rain":
            return "rain"
        case "Gentle Stream":
            return "forest-rain"
        case "Heartbeat", "Womb Environment":
            return "heartbeat"
        default:
            return "white-noise"
        }
    }

    var sfSymbol: String {
        switch title {
        case "White Noise": return "waveform"
        case "Pink Noise": return "waveform.path.ecg"
        case "Deep Pink": return "waveform.path.ecg.rectangle"
        case "Brown Noise": return "wave.3.right"
        case "Air Conditioner": return "wind"
        case "Box Fan": return "fan.fill"
        case "Ocean Waves": return "water.waves"
        case "Forest Rain": return "cloud.rain.fill"
        case "Gentle Stream": return "drop.fill"
        case "Heartbeat": return "heart.fill"
        case "Womb Environment": return "waveform.path.ecg"
        default: return category.sfSymbol
        }
    }

    var generatorType: SoundGeneratorType {
        switch title {
        case "White Noise":        return .white
        case "TV Static":          return .tvStatic
        case "Pink Noise":         return .pink
        case "Deep Pink":          return .deepPink
        case "Brown Noise":        return .brown
        case "Red Noise":          return .red
        case "Air Conditioner":    return .airConditioner
        case "Box Fan":            return .boxFan
        case "Ocean Waves":        return .ocean
        case "Forest Rain":        return .rain
        case "Gentle Stream":      return .stream
        case "Thunderstorm":       return .thunder
        case "Heartbeat":          return .heartbeat
        case "Womb Environment":   return .womb
        default:                   return .white
        }
    }
}

// MARK: - RealSoundManager

@MainActor
class RealSoundManager: ObservableObject {
    @Published var playingTracks: Set<UUID> = []
    @Published var trackVolumes: [UUID: Double] = [:]
    @Published var masterVolume = 0.5 {
        didSet {
            // Apply safe volume limits before updating
            let safeVolume = SafeVolumeManager.shared.applySafeVolume(to: Float(masterVolume))
            let safeMasterVolume = Double(safeVolume)

            if abs(safeMasterVolume - masterVolume) > 0.01 {
                // Volume was limited by safety manager
                print("🔒 Volume limited by SafeVolumeManager: \(masterVolume) → \(safeMasterVolume)")
                DispatchQueue.main.async {
                    self.masterVolume = safeMasterVolume
                }
                return
            }

            updateMasterVolume()
        }
    }

    @Published var isAudioReady = false

    private let maxConcurrentTracks = 1
    private let engine = AVAudioEngine()
    private var sourceNodes: [UUID: AVAudioSourceNode] = [:]
    private var generatorStates: [UUID: NoiseGeneratorState] = [:]
    private let safeVolumeManager = SafeVolumeManager.shared
    private let fadeOutManager = FadeOutManager.shared
    private let sharedPlaybackStore = SharedPlaybackStore.shared
    private var hasPreparedAudioEngine = false

    var currentSound: RealSound? {
        guard let currentId = playingTracks.first else { return nil }
        return allSounds.first { $0.id == currentId }
    }

    // MVP sound catalog
    let allSounds: [RealSound] = [
        RealSound(title: "White Noise", id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, category: .white, color: .gray),
        RealSound(title: "Pink Noise", id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, category: .pink, color: .pink),
        RealSound(title: "Deep Pink", id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, category: .pink, premium: true, color: .purple),
        RealSound(title: "Brown Noise", id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, category: .brown, color: .brown),
        RealSound(title: "Air Conditioner", id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, category: .fan, color: .blue),
        RealSound(title: "Box Fan", id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!, category: .fan, color: .cyan),
        RealSound(title: "Ocean Waves", id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!, category: .nature, color: .blue),
        RealSound(title: "Forest Rain", id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!, category: .nature, color: .green),
        RealSound(title: "Gentle Stream", id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!, category: .nature, premium: true, color: .teal),
        RealSound(title: "Heartbeat", id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!, category: .womb, color: .red),
        RealSound(title: "Womb Environment", id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!, category: .womb, premium: true, color: .pink),
    ]

    func initializeAudio() {
        print("🎵 Initializing Real Audio System with AVAudioEngine...")

        // Настройка аудио сессии
        setupAudioSession()

        // Аудио-движок запускается лениво при первом Play, чтобы старт приложения
        // не зависел от готовности аудио-IO в Simulator или на устройстве.
        setupAudioEngine()

        // Инициализация SafeVolumeManager
        safeVolumeManager.startListeningSession()

        // Применение безопасной громкости
        let safeInitialVolume = safeVolumeManager.applySafeVolume(to: Float(masterVolume))
        masterVolume = Double(safeInitialVolume)

        isAudioReady = true
        print("✅ Real Audio System Ready with SafeVolumeManager")

        // Инициализация громкости для всех звуков
        for sound in allSounds {
            trackVolumes[sound.id] = 0.5
        }

        // Настройка наблюдения за fade out для обновления громкости
        setupFadeOutObserver()
        sharedPlaybackStore.updateFavorites(FavoritesManager.shared.favoriteIds)
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            // Настройка Now Playing Info
            setupNowPlayingInfo()

            print("✅ Audio session configured with background playback")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }

    private func setupNowPlayingInfo() {
        // Настройка для отображения в Control Center и Lock Screen
        var nowPlayingInfo: [String: Any] = [:]
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Baby Sounds"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Sleep Helper"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Baby Sleep Sounds"
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        print("✅ Now Playing Info configured")
    }

    private func setupAudioEngine() {
        print("✅ Audio engine will start on first playback")
    }

    private func prepareAudioEngineIfNeeded() -> Bool {
        guard !hasPreparedAudioEngine else { return true }

        do {
            // AVAudioEngine manages mainMixerNode→outputNode automatically.
            // Manual connection with a mismatched format causes kAUStartIO error.
            engine.mainMixerNode.outputVolume = 1.0
            engine.prepare()
            try engine.start()
            hasPreparedAudioEngine = true
            let sr = engine.outputNode.outputFormat(forBus: 0).sampleRate
            print("✅ Audio engine started at \(sr) Hz")
            return true
        } catch {
            print("❌ Failed to start audio engine: \(error)")
            return false
        }
    }

    func sounds(for category: SoundCategory) -> [RealSound] {
        category == .all ? allSounds : allSounds.filter { $0.category == category }
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "babysounds" else { return }

        guard url.host == "play" || url.host == "open",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let soundId = components.queryItems?.first(where: { $0.name == "soundId" })?.value,
              let sound = allSounds.first(where: { $0.slug == soundId || $0.id.uuidString == soundId })
        else {
            return
        }

        if url.host == "play" {
            toggleSound(sound)
        }
    }

    func isPlaying(_ soundId: UUID) -> Bool {
        return playingTracks.contains(soundId)
    }

    func getVolume(for soundId: UUID) -> Double {
        return trackVolumes[soundId] ?? 0.5
    }

    func toggleSound(_ sound: RealSound) {
        if playingTracks.contains(sound.id) {
            stopSound(sound)
        } else {
            playSound(sound)
        }
    }

    private func playSound(_ sound: RealSound) {
        if !playingTracks.isEmpty {
            stopAllSounds()
        }
        playGeneratedAudio(sound: sound)
    }

    private func playGeneratedAudio(sound: RealSound) {
        let sampleRate = 44100.0
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            print("❌ Failed to create audio format")
            return
        }

        let generator = NoiseGeneratorState(type: sound.generatorType, sampleRate: sampleRate)
        generatorStates[sound.id] = generator

        // sourceNode render block is created on NoiseGeneratorState (non-actor class)
        // so Swift 6 does NOT inject @MainActor isolation into the audio-thread callback
        let sourceNode = generator.makeSourceNode(format: format)

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        sourceNode.volume = Float((trackVolumes[sound.id] ?? 0.5) * masterVolume)

        guard prepareAudioEngineIfNeeded() else {
            engine.detach(sourceNode)
            generatorStates.removeValue(forKey: sound.id)
            return
        }

        sourceNodes[sound.id] = sourceNode
        playingTracks.insert(sound.id)
        updateNowPlayingInfo(with: sound)
        sharedPlaybackStore.updatePlayback(sound: sound, isPlaying: true)
        PlaybackLiveActivityController.startOrUpdate(soundTitle: sound.title, isPlaying: true)
        print("▶️ Playing generated audio: \(sound.title) [\(sound.generatorType)]")
    }

    private func updateNowPlayingInfo(with sound: RealSound) {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]

        nowPlayingInfo[MPMediaItemPropertyTitle] = sound.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Baby Sounds"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = sound.category.localizedName
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0

        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 3600.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        print("🎵 Updated Now Playing: \(sound.title)")
    }

    func stopSound(_ sound: RealSound) {
        playingTracks.remove(sound.id)

        // Stop generated (DSP) node
        if let sourceNode = sourceNodes[sound.id] {
            engine.detach(sourceNode)
            sourceNodes.removeValue(forKey: sound.id)
            generatorStates.removeValue(forKey: sound.id)
            print("⏹️ Stopped generated audio: \(sound.title)")
        }

        if playingTracks.isEmpty {
            sharedPlaybackStore.clearPlayback(lastPlayedSoundId: sound.slug)
            PlaybackLiveActivityController.end()
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        }
    }

    func stopAllSounds() {
        let soundsToStop = playingTracks
        for soundId in soundsToStop {
            if let sound = allSounds.first(where: { $0.id == soundId }) {
                stopSound(sound)
            }
        }
        print("⏹️ Stopped all sounds")
    }

    func fadeOutAllSounds(duration: TimeInterval = 10.0) {
        guard !playingTracks.isEmpty else { return }

        fadeOutManager.startFadeOut(duration: duration) { [weak self] in
            Task { @MainActor in
                self?.stopAllSounds()
                print("🌅 Fade out completed - all sounds stopped")
            }
        }
        if let sound = currentSound {
            sharedPlaybackStore.updatePlayback(sound: sound, isPlaying: true, status: "Fading Out")
            PlaybackLiveActivityController.startOrUpdate(soundTitle: sound.title, isPlaying: true, status: "Fading Out")
        }
    }

    func stopFadeOut() {
        fadeOutManager.stopFadeOut()
    }

    func setVolume(_ volume: Double, for soundId: UUID) {
        trackVolumes[soundId] = volume

        let fadeMultiplier = fadeOutManager.currentVolumeMultiplier
        let finalVolume = Float(volume * masterVolume) * fadeMultiplier

        if let sourceNode = sourceNodes[soundId] {
            sourceNode.volume = finalVolume
        }

        if let sound = allSounds.first(where: { $0.id == soundId }) {
            let fadeInfo = fadeOutManager
                .isActiveFade ? " (fade: \(Int(fadeOutManager.currentVolumeMultiplier * 100))%)" : ""
            print("🔊 \(sound.title) volume: \(Int(volume * 100))%\(fadeInfo)")
        }
    }

    private func updateMasterVolume() {
        let fadeMultiplier = fadeOutManager.currentVolumeMultiplier
        for (soundId, sourceNode) in sourceNodes {
            let trackVolume = trackVolumes[soundId] ?? 0.5
            sourceNode.volume = Float(trackVolume * masterVolume) * fadeMultiplier
        }
        let fadeInfo = fadeOutManager.isActiveFade ? " (fade: \(Int(fadeMultiplier * 100))%)" : ""
        print("🔊 Master volume: \(Int(masterVolume * 100))%\(fadeInfo)")
    }

    private func setupFadeOutObserver() {
        // Периодическое обновление громкости во время fade out
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                if self.fadeOutManager.isActiveFade {
                    self.updateMasterVolume()
                }
            }
        }
    }
}

// MARK: - SafeVolumeManager

@MainActor
class SafeVolumeManager: ObservableObject {
    static let shared = SafeVolumeManager()

    @Published var isSafeVolumeEnabled = true
    @Published var currentListeningDuration: TimeInterval = 0

    // Conservative default volume limits
    private let maxChildSafeVolume: Float = 0.7 // 70% = ~85dB
    private let defaultChildVolume: Float = 0.4
    private let warningThreshold: Float = 0.6

    private var sessionStartTime: Date?

    private init() {
        // Load settings from UserDefaults
        isSafeVolumeEnabled = UserDefaults.standard.object(forKey: "SafeVolumeEnabled") as? Bool ?? true
    }

    func applySafeVolume(to volume: Float) -> Float {
        guard isSafeVolumeEnabled else {
            return min(volume, 1.0)
        }

        let safeVolume = min(volume, maxChildSafeVolume)

        if safeVolume < volume {
            print("🔒 Volume limited: \(volume) → \(safeVolume) (Safe Volume Active)")
        }

        return safeVolume
    }

    func startListeningSession() {
        sessionStartTime = Date()
        currentListeningDuration = 0
        print("🎧 Safe listening session started")
    }

    func endListeningSession() {
        if let startTime = sessionStartTime {
            let duration = Date().timeIntervalSince(startTime)
            print("🎧 Safe listening session ended: \(Int(duration))s")
        }
        sessionStartTime = nil
        currentListeningDuration = 0
    }

    func setSafeVolumeEnabled(_ enabled: Bool) {
        isSafeVolumeEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "SafeVolumeEnabled")
        print("🔒 Safe Volume \(enabled ? "enabled" : "disabled")")
    }
}

// MARK: - SleepTimerManager

@MainActor
class SleepTimerManager: ObservableObject {
    static let shared = SleepTimerManager()

    @Published var isActive = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0

    private var timer: Timer?
    private var onTimerComplete: (() -> Void)?

    private init() {}

    func startTimer(duration: TimeInterval, onComplete: @escaping () -> Void) {
        stopTimer() // Stop any existing timer

        totalTime = duration
        timeRemaining = duration
        isActive = true
        onTimerComplete = onComplete

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.completeTimer()
                }
            }
        }

        HapticManager.shared.timerStart()
        print("⏰ Sleep timer started: \(Int(duration / 60)) minutes")
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false
        timeRemaining = 0
        totalTime = 0
        onTimerComplete = nil

        print("⏰ Sleep timer stopped")
    }

    func addTime(_ additionalTime: TimeInterval) {
        guard isActive else { return }

        timeRemaining += additionalTime
        totalTime += additionalTime

        print("⏰ Added \(Int(additionalTime / 60)) minutes to sleep timer")
    }

    private func completeTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false

        print("⏰ Sleep timer completed - executing completion action")
        onTimerComplete?()

        timeRemaining = 0
        totalTime = 0
        onTimerComplete = nil
    }

    var formattedTimeRemaining: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = Int(timeRemaining.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = Int(timeRemaining.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var progressPercentage: Double {
        guard totalTime > 0 else { return 0 }
        return (totalTime - timeRemaining) / totalTime
    }
}

// MARK: - FadeOutManager

@MainActor
class FadeOutManager: ObservableObject {
    static let shared = FadeOutManager()

    @Published var isActiveFade = false
    @Published var fadeProgress = 0.0

    private var fadeTimer: Timer?
    private var fadeStartTime: Date?
    private var totalFadeDuration: TimeInterval = 0
    private var onFadeComplete: (() -> Void)?

    private init() {}

    func startFadeOut(duration: TimeInterval = 10.0, onComplete: @escaping () -> Void) {
        stopFadeOut() // Stop any existing fade

        totalFadeDuration = duration
        fadeStartTime = Date()
        isActiveFade = true
        fadeProgress = 0.0
        onFadeComplete = onComplete

        // Start fade animation
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                guard let startTime = self.fadeStartTime else { return }

                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(elapsed / self.totalFadeDuration, 1.0)

                self.fadeProgress = progress

                if progress >= 1.0 {
                    self.completeFade()
                }
            }
        }

        HapticManager.shared.fadeStart()
        print("🌅 Fade out started: \(Int(duration))s")
    }

    func stopFadeOut() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        isActiveFade = false
        fadeProgress = 0.0
        fadeStartTime = nil
        onFadeComplete = nil

        print("🌅 Fade out stopped")
    }

    private func completeFade() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        isActiveFade = false

        print("🌅 Fade out completed - executing completion action")
        onFadeComplete?()

        fadeProgress = 0.0
        fadeStartTime = nil
        totalFadeDuration = 0
        onFadeComplete = nil
    }

    var currentVolumeMultiplier: Float {
        if isActiveFade {
            return Float(1.0 - fadeProgress)
        }
        return 1.0
    }

    var formattedTimeRemaining: String {
        guard isActiveFade, let startTime = fadeStartTime else { return "" }

        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(totalFadeDuration - elapsed, 0)

        let minutes = Int(remaining) / 60
        let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))

        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Real StoreKit 2 Integration

import StoreKit

// MARK: - RealSubscriptionService

@MainActor
class RealSubscriptionService: ObservableObject {
    static let shared = RealSubscriptionService()

    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var availableProducts: [Product] = []
    @Published var isLoading = false
    @Published var lastError: String?

    private var productsLoaded = false
    private var transactionUpdateTask: Task<Void, Never>?

    // Product IDs
    private let productIds = [
        "baby.monthly",
        "baby.annual",
    ]

    enum SubscriptionStatus {
        case notSubscribed
        case subscribed(Product)
        case inTrial(Product)
        case expired(Product)

        var isActive: Bool {
            switch self {
            case .inTrial, .subscribed:
                return true
            case .expired, .notSubscribed:
                return false
            }
        }

        var displayText: String {
            switch self {
            case .notSubscribed:
                return "Not Subscribed"
            case let .subscribed(product):
                return "Premium Active - \(product.displayName)"
            case let .inTrial(product):
                return "Free Trial - \(product.displayName)"
            case let .expired(product):
                return "Expired - \(product.displayName)"
            }
        }
    }

    private init() {
        startTransactionObserver()
    }

    deinit {
        transactionUpdateTask?.cancel()
    }

    // MARK: - Public Methods

    func initialize() async {
        await loadProducts()
        await updateSubscriptionStatus()
    }

    func loadProducts() async {
        guard !productsLoaded else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: productIds)

            // Sort products: monthly first, then annual
            let sortedProducts = products.sorted { product1, product2 in
                if product1.id == "baby.monthly" {
                    return true
                } else if product2.id == "baby.monthly" {
                    return false
                } else {
                    return product1.price < product2.price
                }
            }

            availableProducts = sortedProducts
            productsLoaded = true
            lastError = nil

            print("✅ [StoreKit] Loaded \(products.count) products")
            for product in products {
                print("  • \(product.id): \(product.displayPrice) - \(product.displayName)")
            }

        } catch {
            print("❌ [StoreKit] Failed to load products: \(error)")
            lastError = "Failed to load products: \(error.localizedDescription)"
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case let .success(verification):
                // Handle successful purchase
                switch verification {
                case let .verified(transaction):
                    print("✅ Purchase successful: \(transaction.productID)")
                    await updateSubscriptionStatus()
                    await transaction.finish()
                case let .unverified(_, verificationError):
                    print("❌ Transaction unverified: \(verificationError)")
                    lastError = "Transaction verification failed"
                }
            case .userCancelled:
                print("🚫 User cancelled purchase")
                lastError = nil
            case .pending:
                print("⏳ Purchase pending...")
                lastError = "Purchase is pending"
            @unknown default:
                print("❓ Unknown purchase result")
                lastError = "Unknown purchase result"
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            lastError = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ Purchases restored successfully")
            lastError = nil
        } catch {
            print("❌ Restore failed: \(error)")
            lastError = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    private func startTransactionObserver() {
        transactionUpdateTask = Task.detached {
            for await result in Transaction.updates {
                switch result {
                case let .verified(transaction):
                    print("🔄 Transaction update: \(transaction.productID)")
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                case let .unverified(_, error):
                    print("❌ Unverified transaction: \(error)")
                }
            }
        }
    }

    private func updateSubscriptionStatus() async {
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            switch result {
            case let .verified(transaction):
                if productIds.contains(transaction.productID) {
                    // Find the product
                    if let product = availableProducts.first(where: { $0.id == transaction.productID }) {
                        // Check if it's still valid
                        if let expirationDate = transaction.expirationDate,
                           expirationDate > Date()
                        {
                            // Check if in trial period
                            if let statusArray = try? await product.subscription?.status {
                                for status in statusArray {
                                    switch status.state {
                                    case .subscribed:
                                        subscriptionStatus = .subscribed(product)
                                        print("💎 Premium subscription active: \(product.displayName)")
                                        return
                                    case .inBillingRetryPeriod, .inGracePeriod:
                                        subscriptionStatus = .subscribed(product)
                                        print("💎 Premium subscription active (grace period): \(product.displayName)")
                                        return
                                    case .expired, .revoked:
                                        subscriptionStatus = .expired(product)
                                        print("💎 Subscription expired: \(product.displayName)")
                                    default:
                                        print("💎 Unknown subscription state: \(status.state)")
                                    }
                                }
                            }

                            // Fallback: assume subscribed if we have a valid transaction
                            subscriptionStatus = .subscribed(product)
                            print("💎 Premium subscription active: \(product.displayName)")
                            return
                        } else {
                            subscriptionStatus = .expired(product)
                            print("💎 Subscription expired: \(product.displayName)")
                        }
                    }
                }
            case let .unverified(_, error):
                print("❌ Unverified entitlement: \(error)")
            }
        }

        // No active subscription found
        subscriptionStatus = .notSubscribed
        print("💎 No active subscription")
    }
}

// MARK: - PremiumManager

@MainActor
class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    @Published var isPremium = false
    @Published var isLoading = false

    private let subscriptionService = RealSubscriptionService.shared

    private init() {
        // Watch for subscription status changes
        subscriptionService.$subscriptionStatus
            .map { $0.isActive }
            .assign(to: &$isPremium)

        subscriptionService.$isLoading
            .assign(to: &$isLoading)

        // Initialize StoreKit
        Task {
            await subscriptionService.initialize()
        }
    }

    func purchasePremium() async {
        guard let monthlyProduct = subscriptionService.availableProducts.first(where: { $0.id == "baby.monthly" })
        else {
            print("❌ Monthly product not available")
            return
        }

        await subscriptionService.purchase(monthlyProduct)
    }

    func purchaseProduct(_ product: Product) async {
        await subscriptionService.purchase(product)
    }

    func restorePurchases() async {
        await subscriptionService.restorePurchases()
    }

    var availableProducts: [Product] {
        subscriptionService.availableProducts
    }

    var subscriptionStatus: RealSubscriptionService.SubscriptionStatus {
        subscriptionService.subscriptionStatus
    }
}

// MARK: - Shared Playback State

@MainActor
final class SharedPlaybackStore {
    static let shared = SharedPlaybackStore()

    private let defaults = UserDefaults(suiteName: BabySoundsShared.appGroupId) ?? .standard

    private init() {}

    func updatePlayback(
        sound: RealSound,
        isPlaying: Bool,
        status: String = "Playing"
    ) {
        var snapshot = loadSnapshot()
        snapshot.currentSoundId = sound.slug
        snapshot.currentSoundTitle = sound.title
        snapshot.isPlaying = isPlaying
        snapshot.lastPlayedSoundId = sound.slug
        snapshot.status = status
        save(snapshot)
    }

    func updateTimer(endDate: Date) {
        var snapshot = loadSnapshot()
        snapshot.timerEndDate = endDate
        snapshot.status = "Timer"
        save(snapshot)
    }

    func clearTimer() {
        var snapshot = loadSnapshot()
        snapshot.timerEndDate = nil
        snapshot.status = snapshot.isPlaying ? "Playing" : "Stopped"
        save(snapshot)
    }

    func clearPlayback(lastPlayedSoundId: String?) {
        var snapshot = loadSnapshot()
        snapshot.currentSoundId = nil
        snapshot.currentSoundTitle = nil
        snapshot.isPlaying = false
        snapshot.timerEndDate = nil
        snapshot.lastPlayedSoundId = lastPlayedSoundId ?? snapshot.lastPlayedSoundId
        snapshot.status = "Stopped"
        save(snapshot)
    }

    func updateFavorites(_ ids: Set<UUID>) {
        var snapshot = loadSnapshot()
        snapshot.favoriteIds = ids.map(\.uuidString).sorted()
        save(snapshot)
    }

    private func loadSnapshot() -> SharedPlaybackSnapshot {
        guard let data = defaults.data(forKey: BabySoundsShared.snapshotKey),
              let snapshot = try? JSONDecoder().decode(SharedPlaybackSnapshot.self, from: data)
        else {
            return .empty
        }

        return snapshot
    }

    private func save(_ snapshot: SharedPlaybackSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: BabySoundsShared.snapshotKey)
    }
}

// MARK: - Live Activity

enum PlaybackLiveActivityController {
    static func startOrUpdate(
        soundTitle: String,
        isPlaying: Bool,
        timerEndDate: Date? = nil,
        status: String = "Playing"
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = BabySoundsPlaybackAttributes.ContentState(
            soundTitle: soundTitle,
            isPlaying: isPlaying,
            timerEndDate: timerEndDate,
            status: status
        )

        Task {
            if let currentActivity = Activity<BabySoundsPlaybackAttributes>.activities.first {
                await currentActivity.update(ActivityContent(state: state, staleDate: nil))
            } else {
                do {
                    _ = try Activity.request(
                        attributes: BabySoundsPlaybackAttributes(sessionName: "BabySounds"),
                        content: ActivityContent(state: state, staleDate: nil),
                        pushType: nil
                    )
                } catch {
                    print("⚠️ Live Activity unavailable: \(error)")
                }
            }
        }
    }

    static func end() {
        Task {
            let state = BabySoundsPlaybackAttributes.ContentState(
                soundTitle: "BabySounds",
                isPlaying: false,
                timerEndDate: nil,
                status: "Stopped"
            )
            for activity in Activity<BabySoundsPlaybackAttributes>.activities {
                await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
            }
        }
    }
}

// MARK: - Color Extensions

extension Color {
    static let softPink = Color(red: 1.0, green: 0.7, blue: 0.8)
}

#Preview {
    ContentView()
}
