import AVFoundation
import AVKit
import MediaPlayer
import SafariServices
import StoreKit
import SwiftUI
import UIKit
@preconcurrency import UserNotifications

// MARK: - HapticManager

struct SafariRoute: Identifiable {
    let id = UUID()
    let url: URL
}

struct InAppSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(red: 0x30 / 255, green: 0xAA / 255, blue: 0xF5 / 255, alpha: 1)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

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
    @AppStorage("HasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedSound: RealSound?
    @State private var showingPremiumSheet = false

    var body: some View {
        TabView {
            SoundsView(
                onSelectSound: { selectedSound = $0 },
                onPremiumRequired: { showingPremiumSheet = true }
            )
                .environmentObject(soundManager)
                .environmentObject(premiumManager)
                .tabItem {
                    Image(systemName: "music.note")
                        .accessibilityLabel("Sounds")
                }

            FavoritesView(onSelectSound: { selectedSound = $0 })
                .environmentObject(soundManager)
                .environmentObject(premiumManager)
                .environmentObject(favoritesManager)
                .tabItem {
                    Image(systemName: "heart.fill")
                        .accessibilityLabel("Favorites")
                }

            SettingsView()
                .environmentObject(soundManager)
                .environmentObject(premiumManager)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                        .accessibilityLabel("Settings")
                }
        }
        .tint(AppTheme.accent)
        .overlay(alignment: .bottom) {
            if soundManager.currentSound != nil {
                NowPlayingBar { sound in
                    selectedSound = sound
                }
                .environmentObject(soundManager)
                .padding(.bottom, 74)
            }
        }
        .onAppear {
            soundManager.initializeAudio()
        }
        .onOpenURL { url in
            soundManager.handleDeepLink(url)
        }
        .onReceive(soundManager.$deepLinkedSound.compactMap { $0 }) { sound in
            if sound.premium, !premiumManager.isPremium {
                showingPremiumSheet = true
            } else {
                selectedSound = sound
            }
            soundManager.deepLinkedSound = nil
        }
        .sheet(item: $selectedSound) { sound in
            PlayerView(sound: sound)
                .environmentObject(soundManager)
                .environmentObject(premiumManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingPremiumSheet) {
            PremiumUpgradeView()
                .environmentObject(premiumManager)
        }
        .fullScreenCover(isPresented: Binding(
            get: { !hasCompletedOnboarding },
            set: { isPresented in
                if !isPresented {
                    hasCompletedOnboarding = true
                }
            }
        )) {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environmentObject(premiumManager)
        }
    }
}

// MARK: - SoundsView

struct SoundsView: View {
    @EnvironmentObject var soundManager: RealSoundManager
    @EnvironmentObject var premiumManager: PremiumManager
    @StateObject private var favoritesManager = FavoritesManager.shared
    let onSelectSound: (RealSound) -> Void
    let onPremiumRequired: () -> Void

    private var sortedSounds: [RealSound] {
        soundManager.allSounds.sorted { first, second in
            if first.premium != second.premium {
                return !first.premium && second.premium
            }
            return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
        }
    }

    var body: some View {
        NavigationView {
            SoundGrid(
                sounds: sortedSounds,
                isPlaying: { soundManager.isPlaying($0.id) },
                isFavorite: { favoritesManager.isFavorite($0) },
                onTap: { sound in
                    if sound.premium, !premiumManager.isPremium {
                        onPremiumRequired()
                    } else {
                        onSelectSound(sound)
                    }
                },
                onFavoriteTap: { sound in
                    favoritesManager.toggleFavorite(sound)
                }
            )
            .navigationTitle("Sounds")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - SoundGrid

struct SoundGrid: View {
    let sounds: [RealSound]
    let isPlaying: (RealSound) -> Bool
    let isFavorite: (RealSound) -> Bool
    let onTap: (RealSound) -> Void
    let onFavoriteTap: (RealSound) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(sounds) { sound in
                    SoundCard(
                        sound: sound,
                        isPlaying: isPlaying(sound),
                        isFavorite: isFavorite(sound),
                        onTap: {
                            onTap(sound)
                        },
                        onFavoriteTap: {
                            onFavoriteTap(sound)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 110)
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
    }
}

// MARK: - SoundCard

struct SoundCard: View {
    let sound: RealSound
    let isPlaying: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavoriteTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            GeometryReader { proxy in
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        BundledArtwork(name: sound.artworkName)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .opacity(0.58)
                            .blur(radius: 14)
                            .scaleEffect(1.12)

                        BundledArtwork(name: sound.artworkName)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                    .background(Color.black)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.12), .black.opacity(0.58)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    }

                    Button(action: onFavoriteTap) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(isFavorite ? AppTheme.accent : .white.opacity(0.82))
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.16), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(10)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(isPlaying ? "NOW PLAYING" : sound.category.localizedName.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(isPlaying ? AppTheme.accent : .white.opacity(0.78))
                                .lineLimit(1)

                            if sound.premium {
                                Image(systemName: "crown.fill")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.orange)
                            }
                        }

                        Text(sound.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .aspectRatio(2.0 / 3.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
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
                        .foregroundStyle(isPlaying ? AppTheme.accent : Color.secondary)
                }

                Spacer()

                if sound.premium {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(Color.orange)
                }

                Button(action: onFavoriteTap) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? AppTheme.accent : Color.secondary)
                }
                .buttonStyle(.plain)

                Button(action: onPlayTap) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.accent)
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
            ZStack(alignment: .top) {
                Circle()
                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
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
                                .fill(AppTheme.accent)
                        )
                }
            }
        }
    }
}

// MARK: - PlayerView

struct PlayerView: View {
    let sound: RealSound
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var soundManager: RealSoundManager
    @EnvironmentObject var premiumManager: PremiumManager
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var sleepTimer = SleepTimerManager.shared
    @StateObject private var fadeOutManager = FadeOutManager.shared
    @State private var currentSound: RealSound
    @State private var showingPremiumSheet = false
    @State private var showingTimerSheet = false
    @State private var transitionDirection = 1
    @State private var playbackPosition: TimeInterval = 0
    @State private var isEditingPlaybackPosition = false

    private let progressTicker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(sound: RealSound) {
        self.sound = sound
        _currentSound = State(initialValue: sound)
    }

    private var orderedSounds: [RealSound] {
        soundManager.allSounds.sorted { first, second in
            if first.premium != second.premium {
                return !first.premium && second.premium
            }
            return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
        }
    }

    private var isPlaying: Bool {
        soundManager.isPlaying(currentSound.id)
    }

    var body: some View {
        GeometryReader { proxy in
            let viewportWidth = min(proxy.size.width, UIScreen.main.bounds.width)
            let viewportHeight = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            let coverSize = min(viewportWidth - 48, min(proxy.size.height * 0.42, 390))

            ZStack {
                BundledArtwork(name: currentSound.artworkName)
                    .frame(width: viewportWidth, height: viewportHeight)
                    .clipped()
                    .blur(radius: 34, opaque: true)
                    .scaleEffect(1.18)
                    .ignoresSafeArea(.container, edges: .all)
                    .overlay {
                        Color.black.opacity(0.46)
                            .ignoresSafeArea()
                    }
                    .overlay {
                        LinearGradient(
                            colors: [.black.opacity(0.10), .black.opacity(0.22), .black.opacity(0.72)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }
                    .id("artwork-\(currentSound.id)")
                    .transition(pageTransition)

                VStack(spacing: 0) {
                    Capsule()
                        .fill(.white.opacity(0.34))
                        .frame(width: 58, height: 5)
                        .padding(.top, max(proxy.safeAreaInsets.top + 10, 16))
                        .padding(.bottom, 12)

                    playerTopBar
                        .padding(.horizontal, 18)
                        .frame(width: viewportWidth)

                    Spacer(minLength: 18)

                    BundledArtwork(name: currentSound.artworkName)
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: coverSize, height: coverSize)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: .black.opacity(0.34), radius: 28, x: 0, y: 18)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(.white.opacity(0.10), lineWidth: 1)
                        }
                        .padding(.horizontal, 24)
                        .id("cover-\(currentSound.id)")
                        .transition(pageTransition)

                    Spacer(minLength: 28)

                    VStack(spacing: 24) {
                        titleBlock
                            .padding(.horizontal, 30)
                            .frame(width: viewportWidth)

                        trackProgressControl
                            .padding(.horizontal, 30)
                            .frame(width: viewportWidth)

                        playbackControls
                            .padding(.horizontal, 48)
                            .frame(width: viewportWidth)

                        volumeControl
                            .padding(.top, 4)
                            .padding(.horizontal, 30)
                            .frame(width: viewportWidth)

                        bottomActions
                            .padding(.top, 2)
                            .padding(.horizontal, 48)
                            .frame(width: viewportWidth)
                    }
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom + 18, 30))
                    .frame(width: viewportWidth)
                }
                .frame(width: viewportWidth, height: proxy.size.height)
                .id("content-\(currentSound.id)")
                .transition(pageTransition)
            }
            .frame(width: viewportWidth, height: viewportHeight, alignment: .top)
            .ignoresSafeArea(.container, edges: .bottom)
            .gesture(
                DragGesture(minimumDistance: 44)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height),
                              abs(value.translation.width) > 52
                        else { return }

                        switchSound(by: value.translation.width < 0 ? 1 : -1)
                    }
            )
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !soundManager.isPlaying(currentSound.id) {
                soundManager.toggleSound(currentSound)
            }
            playbackPosition = soundManager.playbackElapsedTime
        }
        .onReceive(progressTicker) { _ in
            guard !isEditingPlaybackPosition else { return }
            playbackPosition = soundManager.playbackElapsedTime
        }
        .sheet(isPresented: $showingPremiumSheet) {
            PremiumUpgradeView()
                .environmentObject(premiumManager)
        }
        .sheet(isPresented: $showingTimerSheet) {
            SleepTimerSheet(
                sound: currentSound,
                onStart: { minutes, fadeOutAtEnd in
                    startTimer(minutes: minutes, fadeOutAtEnd: fadeOutAtEnd)
                    showingTimerSheet = false
                },
                onStop: {
                    cancelTimer()
                }
            )
            .environmentObject(soundManager)
            .environmentObject(premiumManager)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var playerTopBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.08), in: Circle())
            }
            .accessibilityLabel("Close player")

            Spacer(minLength: 8)

            Button {
                HapticManager.shared.favoriteToggle()
                favoritesManager.toggleFavorite(currentSound)
            } label: {
                Image(systemName: favoritesManager.isFavorite(currentSound) ? "heart.fill" : "heart")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(favoritesManager.isFavorite(currentSound) ? AppTheme.accent : .white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.08), in: Circle())
            }
            .accessibilityLabel(favoritesManager.isFavorite(currentSound) ? "Remove from favorites" : "Add to favorites")
        }
    }

    private var titleBlock: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(currentSound.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(currentSound.category.localizedName)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            Image(systemName: currentSound.category.sfSymbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.10), in: Circle())
                .accessibilityHidden(true)
        }
    }

    private var trackProgressControl: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { min(max(playbackPosition, 0), soundManager.playbackDuration) },
                    set: { playbackPosition = $0 }
                ),
                in: 0...soundManager.playbackDuration,
                onEditingChanged: { isEditing in
                    isEditingPlaybackPosition = isEditing
                    if !isEditing {
                        soundManager.setPlaybackPosition(playbackPosition)
                    }
                }
            )
            .tint(.white.opacity(0.92))

            HStack {
                Text(formatDuration(playbackPosition))
                Spacer()
                Text("-\(formatDuration(max(soundManager.playbackDuration - playbackPosition, 0)))")
            }
            .font(.caption.monospacedDigit().weight(.semibold))
            .foregroundStyle(.white.opacity(0.56))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Playback progress")
        .accessibilityValue("\(formatDuration(playbackPosition)) of \(formatDuration(soundManager.playbackDuration))")
    }

    private var playbackControls: some View {
        HStack(alignment: .center, spacing: 64) {
            PlayerIconButton(systemImage: "backward.fill") {
                switchSound(by: -1)
            }
            .accessibilityLabel("Previous sound")

            Button {
                if isPlaying {
                    soundManager.pauseSound(currentSound)
                } else {
                    soundManager.toggleSound(currentSound)
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .contentShape(Rectangle())
                    .offset(x: isPlaying ? 0 : 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? "Pause" : "Play")

            PlayerIconButton(systemImage: "forward.fill") {
                switchSound(by: 1)
            }
            .accessibilityLabel("Next sound")
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var volumeControl: some View {
        HStack(spacing: 14) {
            Image(systemName: "speaker.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))
            Slider(
                value: Binding(
                    get: { soundManager.getVolume(for: currentSound.id) },
                    set: { soundManager.setVolume($0, for: currentSound.id) }
                ),
                in: 0...1
            )
            .tint(.white.opacity(0.92))
            Image(systemName: "speaker.wave.2.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))
        }
        .accessibilityElement(children: .contain)
    }

    private var bottomActions: some View {
        HStack(spacing: 44) {
            PlayerBottomActionButton(
                systemImage: sleepTimer.isActive ? "timer.circle.fill" : "timer",
                title: sleepTimer.isActive ? sleepTimer.formattedTimeRemaining : "Timer"
            ) {
                showingTimerSheet = true
            }
            .accessibilityLabel("Timer")

            SystemRoutePicker()
                .frame(width: 54, height: 54)
                .accessibilityLabel("Audio output")

            ShareLink(item: shareURL) {
                VStack(spacing: 7) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 25, weight: .semibold))
                        .frame(width: 54, height: 38)
                    Text("Share")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.white.opacity(0.74))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var shareURL: URL {
        URL(string: "babysounds://open?soundId=\(currentSound.slug)") ?? URL(string: "babysounds://open")!
    }

    private var pageTransition: AnyTransition {
        let insertionEdge: Edge = transitionDirection >= 0 ? .trailing : .leading
        let removalEdge: Edge = transitionDirection >= 0 ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    private func switchSound(by offset: Int) {
        guard let currentIndex = orderedSounds.firstIndex(where: { $0.id == currentSound.id }) else { return }
        let nextIndex = (currentIndex + offset + orderedSounds.count) % orderedSounds.count
        let nextSound = orderedSounds[nextIndex]

        guard !nextSound.premium || premiumManager.isPremium else {
            showingPremiumSheet = true
            return
        }

        transitionDirection = offset
        HapticManager.shared.selection()
        withAnimation(.easeInOut(duration: 0.28)) {
            currentSound = nextSound
        }
        playbackPosition = 0
        if !soundManager.isPlaying(nextSound.id) {
            soundManager.toggleSound(nextSound)
        }
    }

    private func startTimer(minutes: Int, fadeOutAtEnd: Bool) {
        guard minutes <= 30 || premiumManager.isPremium else {
            showingPremiumSheet = true
            return
        }

        if !soundManager.isPlaying(currentSound.id) {
            soundManager.toggleSound(currentSound)
        }

        sleepTimer.startTimer(duration: TimeInterval(minutes * 60)) {
            Task { @MainActor in
                if fadeOutAtEnd {
                    soundManager.fadeOutAllSounds(duration: 30.0)
                } else {
                    soundManager.stopAllSounds()
                }
            }
        }
        let endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        SharedPlaybackStore.shared.updateTimer(endDate: endDate)
    }

    private func cancelTimer() {
        sleepTimer.stopTimer()
        SharedPlaybackStore.shared.clearTimer()
    }

    private func stopImmediately() {
        soundManager.stopSound(currentSound)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

struct PlayerIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct PlayerBottomActionButton: View {
    let systemImage: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 25, weight: .semibold))
                    .frame(width: 54, height: 38)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(.white.opacity(0.74))
        }
        .buttonStyle(.plain)
    }
}

struct SystemRoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.prioritizesVideoDevices = false
        view.tintColor = .white.withAlphaComponent(0.74)
        view.activeTintColor = UIColor(red: 0x30 / 255, green: 0xAA / 255, blue: 0xF5 / 255, alpha: 1)
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = .white.withAlphaComponent(0.74)
        uiView.activeTintColor = UIColor(red: 0x30 / 255, green: 0xAA / 255, blue: 0xF5 / 255, alpha: 1)
    }
}

struct ProgressiveControlsBackdrop: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black.opacity(0.22), location: 0.24),
                            .init(color: .black.opacity(0.72), location: 0.58),
                            .init(color: .black, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.22), location: 0.34),
                    .init(color: .black.opacity(0.62), location: 0.72),
                    .init(color: .black.opacity(0.86), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .allowsHitTesting(false)
    }
}

struct SleepTimerSheet: View {
    let sound: RealSound
    let onStart: (Int, Bool) -> Void
    let onStop: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var premiumManager: PremiumManager
    @StateObject private var sleepTimer = SleepTimerManager.shared
    @State private var selectedMinutes = 30
    @State private var fadeOutAtEnd = true
    @State private var showingPremiumSheet = false

    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width, UIScreen.main.bounds.width)

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    Capsule()
                        .fill(.white.opacity(0.16))
                        .frame(width: 66, height: 6)
                        .padding(.top, 12)

                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(width: 48, height: 48)
                                .background(.white.opacity(0.10), in: Circle())
                        }
                        .accessibilityLabel("Close timer")
                    }
                    .padding(.horizontal, 24)

                    Text("Sleep timer")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 16)

                    Toggle(isOn: $fadeOutAtEnd) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fade out at end")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(sound.title)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: AppTheme.accent))
                    .padding(.top, 46)
                    .padding(.horizontal, 28)

                    Spacer(minLength: 28)

                    TimerDialView(
                        selectedMinutes: $selectedMinutes,
                        isRunning: sleepTimer.isActive,
                        timeText: sleepTimer.isActive ? sleepTimer.formattedTimeRemaining : "\(selectedMinutes):00"
                    )
                    .frame(width: min(width - 64, 330), height: min(width - 64, 330))

                    Spacer(minLength: 42)

                    Button {
                        if sleepTimer.isActive {
                            onStop()
                        } else {
                            guard selectedMinutes <= 30 || premiumManager.isPremium else {
                                showingPremiumSheet = true
                                return
                            }
                            onStart(selectedMinutes, fadeOutAtEnd)
                        }
                    } label: {
                        Text(sleepTimer.isActive ? "Stop" : "Start")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(AppTheme.accent, in: Capsule())
                    }
                    .padding(.horizontal, 58)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom + 18, 32))
                }
                .frame(width: width, height: proxy.size.height)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if sleepTimer.isActive {
                selectedMinutes = max(1, Int(ceil(sleepTimer.totalTime / 60)))
            }
        }
        .sheet(isPresented: $showingPremiumSheet) {
            PremiumUpgradeView()
                .environmentObject(premiumManager)
        }
    }
}

struct TimerDialView: View {
    @Binding var selectedMinutes: Int
    let isRunning: Bool
    let timeText: String

    private let step = 5
    private let maxMinutes = 60

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = size * 0.38
            let progress = Double(selectedMinutes) / Double(maxMinutes)

            ZStack {
                ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { minute in
                    Text(minute == 0 ? "00" : "\(minute)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white.opacity(minute == selectedMinutes ? 0.92 : 0.45))
                        .position(labelPosition(for: minute, center: center, radius: radius + 34))
                }

                Circle()
                    .stroke(.white.opacity(0.09), lineWidth: 9)
                    .frame(width: radius * 2, height: radius * 2)

                Circle()
                    .trim(from: 0, to: max(0.01, progress))
                    .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: radius * 2, height: radius * 2)

                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 26, height: 26)
                    .position(knobPosition(progress: progress, center: center, radius: radius))
                    .shadow(color: AppTheme.accent.opacity(0.38), radius: 12, x: 0, y: 0)

                Text(timeText)
                    .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.74)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !isRunning else { return }
                        selectedMinutes = minutes(for: value.location, center: center)
                    }
            )
        }
    }

    private func labelPosition(for minute: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = (Double(minute) / Double(maxMinutes)) * 2 * Double.pi - Double.pi / 2
        return CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }

    private func knobPosition(progress: Double, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = progress * 2 * Double.pi - Double.pi / 2
        return CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }

    private func minutes(for location: CGPoint, center: CGPoint) -> Int {
        let dx = location.x - center.x
        let dy = location.y - center.y
        var angle = atan2(dy, dx) + .pi / 2
        if angle < 0 {
            angle += 2 * .pi
        }
        let rawMinutes = Int(round((angle / (2 * .pi)) * Double(maxMinutes) / Double(step))) * step
        return min(max(rawMinutes == 0 ? maxMinutes : rawMinutes, step), maxMinutes)
    }
}

// MARK: - BundledArtwork

struct BundledArtwork: View {
    let name: String
    var contentMode: ContentMode = .fill

    var body: some View {
        if let image = UIImage.bundledArtwork(named: name) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            LinearGradient(
                colors: [.blue.opacity(0.32), .indigo.opacity(0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private extension UIImage {
    static func bundledArtwork(named name: String) -> UIImage? {
        let bundle = Bundle.main

        let directAsset = UIImage(named: name)
        let fileURLs = [
            bundle.url(forResource: name, withExtension: "png", subdirectory: "DesignAssets"),
            bundle.url(forResource: name, withExtension: nil, subdirectory: "DesignAssets"),
            bundle.url(forResource: name, withExtension: "png")
        ]

        return directAsset ?? fileURLs
            .compactMap { $0 }
            .lazy
            .compactMap { UIImage(contentsOfFile: $0.path) }
            .first
    }
}

private func makeNowPlayingArtwork(from image: UIImage) -> MPMediaItemArtwork {
    MPMediaItemArtwork(boundsSize: image.size) { _ in image }
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
                        .tint(option > 30 && !premiumManager.isPremium ? .orange : AppTheme.accent)
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
        isPresented = false
    }
}

// MARK: - NowPlayingBar

struct NowPlayingBar: View {
    @EnvironmentObject var soundManager: RealSoundManager
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var sleepTimer = SleepTimerManager.shared
    @StateObject private var fadeOutManager = FadeOutManager.shared
    let onOpen: (RealSound) -> Void

    var body: some View {
        if let firstPlayingSound = soundManager.currentSound {
            Button {
                onOpen(firstPlayingSound)
            } label: {
                HStack(spacing: 12) {
                    SoundArtwork(sound: firstPlayingSound, size: 40, iconSize: 16)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(firstPlayingSound.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if sleepTimer.isActive || fadeOutManager.isActiveFade {
                            HStack(spacing: 8) {
                                if sleepTimer.isActive {
                                    Label(sleepTimer.formattedTimeRemaining, systemImage: "timer")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.orange)
                                }

                                if fadeOutManager.isActiveFade {
                                    Label(fadeOutManager.formattedTimeRemaining, systemImage: "minus.magnifyingglass")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(AppTheme.accent)
                                }
                            }
                        } else {
                            Text("Playing")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.white.opacity(0.62))
                        }
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 18) {
                        Button {
                            HapticManager.shared.favoriteToggle()
                            favoritesManager.toggleFavorite(firstPlayingSound)
                        } label: {
                            Image(systemName: favoritesManager.isFavorite(firstPlayingSound) ? "heart.fill" : "heart")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(favoritesManager.isFavorite(firstPlayingSound) ? AppTheme.accent : .white)
                                .frame(width: 34, height: 34)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(favoritesManager.isFavorite(firstPlayingSound) ? "Remove from favorites" : "Add to favorites")

                        Button {
                            if soundManager.isPlaying(firstPlayingSound.id) {
                                soundManager.pauseSound(firstPlayingSound)
                            } else {
                                soundManager.toggleSound(firstPlayingSound)
                            }
                        } label: {
                            Image(systemName: soundManager.isPlaying(firstPlayingSound.id) ? "pause.fill" : "play.fill")
                                .font(.title3.weight(.bold))
                                .foregroundColor(AppTheme.accent)
                                .frame(width: 34, height: 34)
                                .contentShape(Rectangle())
                                .offset(x: soundManager.isPlaying(firstPlayingSound.id) ? 0 : 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(soundManager.isPlaying(firstPlayingSound.id) ? "Pause" : "Play")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.28), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
            .transition(.move(edge: .bottom).combined(with: .opacity))
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
    @EnvironmentObject var premiumManager: PremiumManager
    @StateObject private var favoritesManager = FavoritesManager.shared
    let onSelectSound: (RealSound) -> Void

    var favoriteSounds: [RealSound] {
        soundManager.allSounds
            .filter { favoritesManager.isFavorite($0) }
            .sorted { first, second in
                if first.premium != second.premium {
                    return !first.premium && second.premium
                }
                return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            }
    }

    var body: some View {
        NavigationView {
            Group {
                if favoriteSounds.isEmpty {
                    EmptyFavoritesView()
                } else {
                    SoundGrid(
                        sounds: favoriteSounds,
                        isPlaying: { soundManager.isPlaying($0.id) },
                        isFavorite: { _ in true },
                        onTap: { sound in
                            onSelectSound(sound)
                        },
                        onFavoriteTap: { sound in
                            favoritesManager.toggleFavorite(sound)
                        }
                    )
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - EmptyFavoritesView

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 24) {
            BundledArtwork(name: "favorites-empty")
                .scaledToFit()
                .frame(width: 132, height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: AppTheme.accent.opacity(0.20), radius: 18, x: 0, y: 10)

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

// MARK: - Onboarding

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var premiumManager: PremiumManager
    @State private var page = 0
    @State private var showingPaywall = false

    private let pages = [
        OnboardingPage(
            artwork: "onboarding-sounds",
            title: "Sleep sounds for calm nights",
            subtitle: "Open BabySounds at bedtime and start a soft loop in one tap."
        ),
        OnboardingPage(
            artwork: "onboarding-player",
            title: "Set a gentle sleep timer",
            subtitle: "Choose a timer, fade out at the end, and let the sound disappear quietly."
        ),
        OnboardingPage(
            artwork: "onboarding-paywall",
            title: "Keep favorites close",
            subtitle: "Save the sounds that work best and return to them from the app, widgets, and Live Activities."
        )
    ]

    var body: some View {
        ZStack {
            AppTheme.surface.ignoresSafeArea()
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? AppTheme.accent : .white.opacity(0.25))
                            .frame(width: index == page ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: page)
                    }
                }
                .padding(.bottom, 20)

                Button {
                    if page == pages.count - 1 {
                        showingPaywall = true
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            page += 1
                        }
                    }
                } label: {
                    Text(page == pages.count - 1 ? "Continue" : "Next")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(AppTheme.accent, in: Capsule())
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 18)
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showingPaywall, onDismiss: {
            hasCompletedOnboarding = true
        }) {
            PremiumUpgradeView(allowDismiss: true) {
                hasCompletedOnboarding = true
            }
            .environmentObject(premiumManager)
        }
    }
}

struct OnboardingPage {
    let artwork: String
    let title: String
    let subtitle: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            BundledArtwork(name: page.artwork)
                .scaledToFit()
                .frame(height: 500)
                .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 42, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.34), radius: 24, x: 0, y: 16)
                .padding(.horizontal, 62)
                .padding(.top, 48)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)

                Text(page.subtitle)
                    .font(.body)
                    .lineSpacing(3)
                    .lineLimit(3)
                    .minimumScaleFactor(0.86)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.66))
                    .padding(.horizontal, 34)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 150)
        }
    }
}

// MARK: - PremiumUpgradeView

struct PremiumUpgradeView: View {
    @EnvironmentObject var premiumManager: PremiumManager
    @Environment(\.dismiss) private var dismiss
    let allowDismiss: Bool
    let onCompleted: (() -> Void)?
    @State private var isPurchasing = false
    @State private var purchaseMessage: String?
    @State private var safariRoute: SafariRoute?

    init(allowDismiss: Bool = true, onCompleted: (() -> Void)? = nil) {
        self.allowDismiss = allowDismiss
        self.onCompleted = onCompleted
    }

    private var recommendedProduct: Product? {
        premiumManager.availableProducts.first(where: { $0.id == "baby.annual" }) ?? premiumManager.availableProducts.first
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                BundledArtwork(name: "onboarding-paywall")
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .overlay {
                        LinearGradient(
                            colors: [.black.opacity(0.10), .black.opacity(0.62), .black.opacity(0.94)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }

                VStack(spacing: 0) {
                    HStack {
                        if allowDismiss {
                            Button {
                                dismiss()
                                onCompleted?()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.88))
                                    .frame(width: 44, height: 44)
                                    .background(.black.opacity(0.22), in: Circle())
                            }
                            .accessibilityLabel("Close premium")
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, max(proxy.safeAreaInsets.top + 12, 30))

                    Spacer(minLength: 58)

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 62, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .shadow(color: AppTheme.accent.opacity(0.45), radius: 18, x: 0, y: 0)
                        .padding(.bottom, 28)

                    VStack(spacing: 8) {
                        Text("BabySounds Premium")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        Text("Unlock the full bedtime experience")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.white.opacity(0.70))
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 16) {
                        PaywallFeatureRow(icon: "sparkles", title: "All premium sounds", subtitle: "High quality calming loops")
                        PaywallFeatureRow(icon: "timer", title: "Longer sleep timer", subtitle: "Up to 60 minutes")
                        PaywallFeatureRow(icon: "rectangle.on.rectangle.slash", title: "No ads", subtitle: "Uninterrupted sleep")
                        PaywallFeatureRow(icon: "waveform", title: "Fresh sounds", subtitle: "More bedtime scenes over time")
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 44)

                    Spacer(minLength: 22)

                    Button {
                        Task {
                            if recommendedProduct == nil {
                                purchaseMessage = nil
                                await premiumManager.refreshProducts()
                                if recommendedProduct == nil {
                                    purchaseMessage = "Plans are not available in this environment. Check StoreKit configuration or try again."
                                }
                                return
                            }

                            guard let product = recommendedProduct else { return }
                            isPurchasing = true
                            await premiumManager.purchaseProduct(product)
                            isPurchasing = false
                            if premiumManager.isPremium {
                                dismiss()
                                onCompleted?()
                            } else {
                                purchaseMessage = "Purchase was not completed. Please try again."
                            }
                        }
                    } label: {
                        VStack(spacing: 4) {
                            if isPurchasing || premiumManager.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else if recommendedProduct == nil {
                                Text("Load Premium Plans")
                                    .font(.title3.weight(.bold))
                                Text("Tap to retry StoreKit")
                                    .font(.subheadline.weight(.semibold))
                                    .opacity(0.78)
                            } else {
                                Text("Start 4-Day Free Trial")
                                    .font(.title3.weight(.bold))
                                Text(recommendedProduct.map { "\($0.displayPrice) after trial" } ?? "Then subscription continues")
                                    .font(.subheadline.weight(.semibold))
                                    .opacity(0.78)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 76)
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .disabled(isPurchasing || premiumManager.isLoading)
                    .padding(.horizontal, 28)

                    if let purchaseMessage {
                        Text(purchaseMessage)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.66))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 34)
                            .padding(.top, 10)
                    }

                    Text("Cancel anytime. No commitment.")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.62))
                        .padding(.top, purchaseMessage == nil ? 18 : 10)

                    HStack(spacing: 16) {
                        Button("Restore Purchases") {
                            Task { await premiumManager.restorePurchases() }
                        }
                        Button("Terms of Use") {
                            openInApp(URL(string: "https://babysounds.app/terms"))
                        }
                        Button("Privacy Policy") {
                            openInApp(URL(string: "https://babysounds.app/privacy"))
                        }
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .padding(.top, 24)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom + 14, 26))
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if premiumManager.availableProducts.isEmpty {
                await premiumManager.refreshProducts()
            }
        }
        .sheet(item: $safariRoute) { route in
            InAppSafariView(url: route.url)
                .ignoresSafeArea()
        }
    }

    private func openInApp(_ url: URL?) {
        guard let url else { return }
        if ["http", "https"].contains(url.scheme?.lowercased()) {
            safariRoute = SafariRoute(url: url)
        } else {
            UIApplication.shared.open(url)
        }
    }
}

struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(AppTheme.accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var soundManager: RealSoundManager
    @EnvironmentObject var premiumManager: PremiumManager
    @State private var showingPremiumSheet = false
    @State private var safariRoute: SafariRoute?

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.surface.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        Button {
                            showingPremiumSheet = true
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundStyle(.orange)
                                    .frame(width: 52, height: 52)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(premiumManager.isPremium ? "Premium" : "Upgrade to Premium")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)
                                    Text(premiumManager.isPremium ? "You have access to all features" : "Start a 4-day free trial")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.62))
                                }

                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.54))
                            }
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.accent.opacity(0.28), .white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(.white.opacity(0.08), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)

                        SettingsSection(title: "Account") {
                            SettingsActionRow(icon: "arrow.clockwise.circle.fill", title: "Restore Purchases") {
                                Task { await premiumManager.restorePurchases() }
                            }
                        }

                        SettingsSection(title: "Support") {
                            SettingsActionRow(icon: "envelope.fill", title: "Send Feedback") {
                                open(URL(string: "mailto:support@babysounds.app?subject=Baby%20Sounds%20Feedback"))
                            }
                            SettingsActionRow(icon: "star.fill", title: "Rate the App") {
                                open(URL(string: "https://apps.apple.com/app/id6670503696?action=write-review"))
                            }
                            ShareLink(item: URL(string: "https://babysounds.app")!) {
                                SettingsRowContent(icon: "square.and.arrow.up.fill", title: "Share BabySounds", trailing: "chevron.right")
                            }
                            .buttonStyle(.plain)
                        }

                        SettingsSection(title: "Information") {
                            SettingsActionRow(icon: "hand.raised.fill", title: "Privacy Policy") {
                                openInApp(URL(string: "https://babysounds.app/privacy"))
                            }
                            SettingsActionRow(icon: "doc.plaintext.fill", title: "Terms of Use") {
                                openInApp(URL(string: "https://babysounds.app/terms"))
                            }
                            SettingsRowContent(icon: "number.circle.fill", title: "Version", trailingText: "1.0.0")
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingPremiumSheet) {
            PremiumUpgradeView()
                .environmentObject(premiumManager)
        }
        .sheet(item: $safariRoute) { route in
            InAppSafariView(url: route.url)
                .ignoresSafeArea()
        }
    }

    private func open(_ url: URL?) {
        guard let url else { return }
        UIApplication.shared.open(url)
    }

    private func openInApp(_ url: URL?) {
        guard let url else { return }
        safariRoute = SafariRoute(url: url)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.52))
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content
            }
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.06), lineWidth: 1)
            }
        }
    }
}

struct SettingsActionRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsRowContent(icon: icon, title: title, trailing: "chevron.right")
        }
        .buttonStyle(.plain)
    }
}

struct SettingsRowContent: View {
    let icon: String
    let title: String
    var trailing: String?
    var trailingText: String?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.88))
                .frame(width: 28, height: 28)

            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.54))
            } else if let trailing {
                Image(systemName: trailing)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
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
        case "White Noise": return "white-noise"
        case "Pink Noise": return "pink-noise"
        case "Deep Pink": return "deep-pink"
        case "Brown Noise": return "brown-noise"
        case "Air Conditioner": return "air-conditioner"
        case "Box Fan": return "box-fan"
        case "Ocean Waves": return "ocean-waves"
        case "Forest Rain": return "forest-rain"
        case "Gentle Stream": return "gentle-stream"
        case "Heartbeat": return "heartbeat"
        case "Womb Environment": return "womb-environment"
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
    @Published var deepLinkedSound: RealSound?
    @Published private var pausedSound: RealSound?
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
    @Published var playbackElapsedTime: TimeInterval = 0

    private let maxConcurrentTracks = 1
    let playbackDuration: TimeInterval = 60 * 60
    private let engine = AVAudioEngine()
    private var sourceNodes: [UUID: AVAudioSourceNode] = [:]
    private var generatorStates: [UUID: NoiseGeneratorState] = [:]
    private let safeVolumeManager = SafeVolumeManager.shared
    private let fadeOutManager = FadeOutManager.shared
    private let sharedPlaybackStore = SharedPlaybackStore.shared
    private var hasPreparedAudioEngine = false
    private var remoteCommandsConfigured = false
    private var playbackStartDate: Date?
    private var playbackPositionOffset: TimeInterval = 0
    private var playbackProgressTimer: Timer?

    var currentSound: RealSound? {
        if let currentId = playingTracks.first {
            return allSounds.first { $0.id == currentId }
        }
        return pausedSound
    }

    // MVP sound catalog
    let allSounds: [RealSound] = [
        RealSound(title: "White Noise", id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, category: .white, color: .gray),
        RealSound(title: "Pink Noise", id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, category: .pink, color: AppTheme.accent),
        RealSound(title: "Deep Pink", id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, category: .pink, premium: true, color: .purple),
        RealSound(title: "Brown Noise", id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, category: .brown, color: .brown),
        RealSound(title: "Air Conditioner", id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, category: .fan, color: .blue),
        RealSound(title: "Box Fan", id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!, category: .fan, color: .cyan),
        RealSound(title: "Ocean Waves", id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!, category: .nature, color: .blue),
        RealSound(title: "Forest Rain", id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!, category: .nature, color: .green),
        RealSound(title: "Gentle Stream", id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!, category: .nature, premium: true, color: .teal),
        RealSound(title: "Heartbeat", id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!, category: .womb, color: .red),
        RealSound(title: "Womb Environment", id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!, category: .womb, premium: true, color: AppTheme.accent),
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
            try session.setCategory(.playback, mode: .default, policy: .longFormAudio, options: [])
            setupRemoteTransportControls()

            print("✅ Audio session configured for exclusive background playback")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }

    private func setupRemoteTransportControls() {
        guard !remoteCommandsConfigured else { return }
        remoteCommandsConfigured = true

        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.isEnabled = true
        commands.pauseCommand.isEnabled = true
        commands.togglePlayPauseCommand.isEnabled = true
        commands.stopCommand.isEnabled = true

        commands.nextTrackCommand.isEnabled = false
        commands.previousTrackCommand.isEnabled = false
        commands.skipForwardCommand.isEnabled = false
        commands.skipBackwardCommand.isEnabled = false
        commands.changePlaybackPositionCommand.isEnabled = true

        commands.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.resumeFromRemoteCommand()
            }
            return .success
        }

        commands.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.pauseFromRemoteCommand()
            }
            return .success
        }

        commands.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.toggleFromRemoteCommand()
            }
            return .success
        }

        commands.stopCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.stopAllSounds()
            }
            return .success
        }

        commands.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor in
                self?.setPlaybackPosition(event.positionTime)
            }
            return .success
        }
    }

    private func resumeFromRemoteCommand() {
        guard playingTracks.isEmpty, let sound = pausedSound else { return }
        playSound(sound)
    }

    private func pauseFromRemoteCommand() {
        guard let sound = currentSound, playingTracks.contains(sound.id) else { return }
        pauseSound(sound)
    }

    private func toggleFromRemoteCommand() {
        if playingTracks.isEmpty {
            resumeFromRemoteCommand()
        } else {
            pauseFromRemoteCommand()
        }
    }

    private func activateAudioSession() -> Bool {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            return true
        } catch {
            print("❌ Failed to activate audio session: \(error)")
            return false
        }
    }

    private func deactivateAudioSession() {
        engine.stop()
        hasPreparedAudioEngine = false

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print("⚠️ Failed to deactivate audio session: \(error)")
        }
    }

    private func setupAudioEngine() {
        print("✅ Audio engine will start on first playback")
    }

    private var currentPlaybackPosition: TimeInterval {
        let rawPosition: TimeInterval
        if let playbackStartDate, !playingTracks.isEmpty {
            rawPosition = playbackPositionOffset + Date().timeIntervalSince(playbackStartDate)
        } else {
            rawPosition = playbackPositionOffset
        }

        guard playbackDuration > 0 else { return max(rawPosition, 0) }
        let wrapped = rawPosition.truncatingRemainder(dividingBy: playbackDuration)
        return wrapped >= 0 ? wrapped : wrapped + playbackDuration
    }

    private func startPlaybackTimeline(reset: Bool) {
        if reset {
            playbackPositionOffset = 0
            playbackElapsedTime = 0
        } else {
            playbackPositionOffset = currentPlaybackPosition
            playbackElapsedTime = playbackPositionOffset
        }

        playbackStartDate = Date()
        playbackProgressTimer?.invalidate()
        playbackProgressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPlaybackPosition()
            }
        }
    }

    private func pausePlaybackTimeline() {
        playbackPositionOffset = currentPlaybackPosition
        playbackElapsedTime = playbackPositionOffset
        playbackStartDate = nil
        playbackProgressTimer?.invalidate()
        playbackProgressTimer = nil
        updateNowPlayingPlaybackPosition(rate: 0)
    }

    private func stopPlaybackTimeline(reset: Bool = true) {
        playbackStartDate = nil
        playbackProgressTimer?.invalidate()
        playbackProgressTimer = nil
        if reset {
            playbackPositionOffset = 0
            playbackElapsedTime = 0
        } else {
            playbackPositionOffset = currentPlaybackPosition
            playbackElapsedTime = playbackPositionOffset
        }
    }

    private func refreshPlaybackPosition() {
        playbackElapsedTime = currentPlaybackPosition
    }

    func setPlaybackPosition(_ position: TimeInterval) {
        let clampedPosition = min(max(position, 0), playbackDuration)
        playbackPositionOffset = clampedPosition
        playbackElapsedTime = clampedPosition
        if !playingTracks.isEmpty {
            playbackStartDate = Date()
        }
        updateNowPlayingPlaybackPosition(rate: playingTracks.isEmpty ? 0 : 1)
    }

    private func updateNowPlayingPlaybackPosition(rate: Double) {
        let infoCenter = MPNowPlayingInfoCenter.default()
        guard var nowPlayingInfo = infoCenter.nowPlayingInfo else { return }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playbackElapsedTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = playbackDuration
        infoCenter.nowPlayingInfo = nowPlayingInfo
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

        if url.host == "open" {
            deepLinkedSound = sound
        } else if url.host == "play" {
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
            stopAllSounds(preserveTimer: true)
        }
        playGeneratedAudio(sound: sound)
    }

    private func playGeneratedAudio(sound: RealSound) {
        guard activateAudioSession() else { return }
        let shouldResetPlaybackPosition = pausedSound?.id != sound.id

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
        sourceNode.volume = Float((trackVolumes[sound.id] ?? 0.5) * masterVolume) * fadeOutManager.currentVolumeMultiplier

        guard prepareAudioEngineIfNeeded() else {
            engine.detach(sourceNode)
            generatorStates.removeValue(forKey: sound.id)
            return
        }

        sourceNodes[sound.id] = sourceNode
        playingTracks.insert(sound.id)
        startPlaybackTimeline(reset: shouldResetPlaybackPosition)
        pausedSound = nil
        updateNowPlayingInfo(with: sound)
        sharedPlaybackStore.updatePlayback(sound: sound, isPlaying: true)
        print("▶️ Playing generated audio: \(sound.title) [\(sound.generatorType)]")
    }

    private func updateNowPlayingInfo(with sound: RealSound) {
        var nowPlayingInfo: [String: Any] = [:]

        nowPlayingInfo[MPMediaItemPropertyTitle] = sound.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Baby Sounds"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = sound.category.localizedName
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playbackElapsedTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = playbackDuration
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        nowPlayingInfo[MPNowPlayingInfoPropertyExternalContentIdentifier] = sound.slug

        if let image = UIImage.bundledArtwork(named: sound.artworkName) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = makeNowPlayingArtwork(from: image)
        }

        let infoCenter = MPNowPlayingInfoCenter.default()
        infoCenter.nowPlayingInfo = nowPlayingInfo
        infoCenter.playbackState = .playing
        print("🎵 Updated Now Playing: \(sound.title)")
    }

    func stopSound(_ sound: RealSound, preserveTimer: Bool = false) {
        playingTracks.remove(sound.id)
        if pausedSound?.id == sound.id {
            pausedSound = nil
        }

        // Stop generated (DSP) node
        if let sourceNode = sourceNodes[sound.id] {
            engine.detach(sourceNode)
            sourceNodes.removeValue(forKey: sound.id)
            generatorStates.removeValue(forKey: sound.id)
            print("⏹️ Stopped generated audio: \(sound.title)")
        }

        if playingTracks.isEmpty {
            sharedPlaybackStore.clearPlayback(lastPlayedSoundId: sound.slug)
            if !preserveTimer {
                stopPlaybackBoundTimers()
            }
            stopPlaybackTimeline()
            let infoCenter = MPNowPlayingInfoCenter.default()
            infoCenter.playbackState = .stopped
            infoCenter.nowPlayingInfo = nil
            deactivateAudioSession()
        }
    }

    func pauseSound(_ sound: RealSound) {
        guard playingTracks.contains(sound.id) else { return }

        pausePlaybackTimeline()
        playingTracks.remove(sound.id)

        if let sourceNode = sourceNodes[sound.id] {
            engine.detach(sourceNode)
            sourceNodes.removeValue(forKey: sound.id)
            generatorStates.removeValue(forKey: sound.id)
            print("⏸️ Paused generated audio: \(sound.title)")
        }

        pausedSound = sound
        stopPlaybackBoundTimers()
        sharedPlaybackStore.updatePlayback(sound: sound, isPlaying: false, status: "Paused")
        let infoCenter = MPNowPlayingInfoCenter.default()
        infoCenter.playbackState = .paused
        deactivateAudioSession()
    }

    func stopAllSounds(preserveTimer: Bool = false) {
        let soundsToStop = playingTracks
        if soundsToStop.isEmpty, let pausedSound {
            stopSound(pausedSound, preserveTimer: preserveTimer)
            print("⏹️ Stopped all sounds")
            return
        }
        for soundId in soundsToStop {
            if let sound = allSounds.first(where: { $0.id == soundId }) {
                stopSound(sound, preserveTimer: preserveTimer)
            }
        }
        print("⏹️ Stopped all sounds")
    }

    private func stopPlaybackBoundTimers() {
        if SleepTimerManager.shared.isActive {
            SleepTimerManager.shared.stopTimer()
            SharedPlaybackStore.shared.clearTimer()
        }

        if fadeOutManager.isActiveFade {
            fadeOutManager.stopFadeOut()
        }
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
        }
    }

    func startFadeOutToggle(for sound: RealSound, duration: TimeInterval = 30.0) {
        if fadeOutManager.isActiveFade {
            stopFadeOut()
            return
        }

        if !playingTracks.contains(sound.id) {
            playSound(sound)
        }

        fadeOutManager.startFadeInThenOut(fadeInDuration: 8.0, holdDuration: 2.0, fadeOutDuration: duration) { [weak self] in
            Task { @MainActor in
                self?.stopAllSounds()
                print("🌅 Fade in/out completed - all sounds stopped")
            }
        }

        updateMasterVolume()
        sharedPlaybackStore.updatePlayback(sound: sound, isPlaying: true, status: "Fading Out")
    }

    func stopFadeOut() {
        fadeOutManager.stopFadeOut()
        updateMasterVolume()
        if let sound = currentSound {
            sharedPlaybackStore.updatePlayback(sound: sound, isPlaying: true)
        }
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

    private enum FadeMode {
        case out
        case inThenOut
    }

    private var fadeTimer: Timer?
    private var fadeStartTime: Date?
    private var totalFadeDuration: TimeInterval = 0
    private var fadeInDuration: TimeInterval = 0
    private var holdDuration: TimeInterval = 0
    private var fadeOutDuration: TimeInterval = 0
    private var fadeMode: FadeMode = .out
    private var onFadeComplete: (() -> Void)?

    private init() {}

    func startFadeOut(duration: TimeInterval = 10.0, onComplete: @escaping () -> Void) {
        stopFadeOut() // Stop any existing fade

        totalFadeDuration = duration
        fadeInDuration = 0
        holdDuration = 0
        fadeOutDuration = duration
        fadeMode = .out
        fadeStartTime = Date()
        isActiveFade = true
        fadeProgress = 0.0
        onFadeComplete = onComplete

        startProgressTimer()

        HapticManager.shared.fadeStart()
        print("🌅 Fade out started: \(Int(duration))s")
    }

    func startFadeInThenOut(
        fadeInDuration: TimeInterval = 8.0,
        holdDuration: TimeInterval = 2.0,
        fadeOutDuration: TimeInterval = 30.0,
        onComplete: @escaping () -> Void
    ) {
        stopFadeOut()

        self.fadeInDuration = fadeInDuration
        self.holdDuration = holdDuration
        self.fadeOutDuration = fadeOutDuration
        totalFadeDuration = fadeInDuration + holdDuration + fadeOutDuration
        fadeMode = .inThenOut
        fadeStartTime = Date()
        isActiveFade = true
        fadeProgress = 0.0
        onFadeComplete = onComplete

        startProgressTimer()

        HapticManager.shared.fadeStart()
        print("🌅 Fade in/out started: \(Int(totalFadeDuration))s")
    }

    func stopFadeOut() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        isActiveFade = false
        fadeProgress = 0.0
        fadeStartTime = nil
        totalFadeDuration = 0
        fadeInDuration = 0
        holdDuration = 0
        fadeOutDuration = 0
        fadeMode = .out
        onFadeComplete = nil

        print("🌅 Fade out stopped")
    }

    private func startProgressTimer() {
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
        fadeInDuration = 0
        holdDuration = 0
        fadeOutDuration = 0
        fadeMode = .out
        onFadeComplete = nil
    }

    var currentVolumeMultiplier: Float {
        guard isActiveFade else { return 1.0 }

        switch fadeMode {
        case .out:
            return Float(1.0 - fadeProgress)
        case .inThenOut:
            guard let startTime = fadeStartTime else { return 1.0 }
            let elapsed = Date().timeIntervalSince(startTime)

            if fadeInDuration > 0, elapsed < fadeInDuration {
                return Float(max(min(elapsed / fadeInDuration, 1.0), 0.0))
            }

            if elapsed < fadeInDuration + holdDuration {
                return 1.0
            }

            guard fadeOutDuration > 0 else { return 0.0 }
            let fadeOutElapsed = elapsed - fadeInDuration - holdDuration
            let fadeOutProgress = max(min(fadeOutElapsed / fadeOutDuration, 1.0), 0.0)
            return Float(1.0 - fadeOutProgress)
        }
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

    func reloadProducts() async {
        productsLoaded = false
        availableProducts = []
        await loadProducts()
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

    func refreshProducts() async {
        await subscriptionService.reloadProducts()
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

// MARK: - Color Extensions

extension Color {
    static let softPink = Color(red: 1.0, green: 0.7, blue: 0.8)
}

#Preview {
    ContentView()
}
