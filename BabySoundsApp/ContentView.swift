import SwiftUI
import AVFoundation
import MediaPlayer
import StoreKit
@preconcurrency import UserNotifications

// MARK: - Haptic Feedback Manager

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

// MARK: - Main App View

struct ContentView: View {
    @StateObject private var soundManager = RealSoundManager()
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var parentGateManager = ParentGateManager.shared
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
            
            SleepSchedulesView()
                .environmentObject(soundManager)
                .environmentObject(premiumManager)
                .environmentObject(parentGateManager)
                .tabItem {
                    Image(systemName: "moon.zzz")
                    Text("Schedule")
                }
            
            FavoritesView()
                .environmentObject(soundManager)
                .environmentObject(premiumManager)
                .environmentObject(favoritesManager)
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
            
            MoreView()
                .environmentObject(soundManager)
                .environmentObject(premiumManager)
                .environmentObject(parentGateManager)
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text("More")
                }
        }
        .accentColor(.pink)
        .onAppear {
            soundManager.initializeAudio()
        }
    }
}

// MARK: - Sounds View

struct SoundsView: View {
    @EnvironmentObject var soundManager: RealSoundManager
    @EnvironmentObject var premiumManager: PremiumManager
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedCategory: SoundCategory = .all
    @State private var selectedSound: RealSound?
    @State private var showingPlayer = false
    @State private var showingPremiumSheet = false
    
    private let categories: [SoundCategory] = [.all, .nature, .white, .pink, .brown, .womb, .fan]
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Sounds")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "airplayaudio")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                // Category Tabs (только если не "All")
                if selectedCategory != .all {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                CategoryTab(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 12)
                }
                
                // Sounds Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(filteredSounds.enumerated()), id: \.element.id) { index, sound in
                            SoundCardModern(
                                sound: sound,
                                isPlaying: soundManager.isPlaying(sound.id),
                                isFavorite: favoritesManager.isFavorite(sound),
                                onTap: {
                                    HapticManager.shared.playSound()
                                    if sound.premium && !premiumManager.isPremium {
                                        showingPremiumSheet = true
                                    } else {
                                        selectedSound = sound
                                        showingPlayer = true
                                    }
                                },
                                onFavoriteTap: {
                                    HapticManager.shared.favoriteToggle()
                                    favoritesManager.toggleFavorite(sound)
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05)),
                                removal: .scale(scale: 0.8).combined(with: .opacity).animation(.easeOut(duration: 0.3))
                            ))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Space for now playing
                }
                
                Spacer()
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingPlayer) {
            if let sound = selectedSound {
                PlayerView(sound: sound)
                    .environmentObject(soundManager)
                    .environmentObject(premiumManager)
            }
        }
        .sheet(isPresented: $showingPremiumSheet) {
            PremiumUpgradeView()
                .environmentObject(premiumManager)
        }
        .overlay(alignment: .bottom) {
            if !soundManager.playingTracks.isEmpty {
                NowPlayingBar()
                    .environmentObject(soundManager)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 90)
            }
        }
    }
    
    private var filteredSounds: [RealSound] {
        if selectedCategory == .all {
            return soundManager.allSounds
        } else {
            return soundManager.sounds(for: selectedCategory)
        }
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let category: SoundCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.emoji)
                    .font(.caption)
                
                Text(category.localizedName)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.pink : Color(UIColor.secondarySystemGroupedBackground))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Sound Card

struct SoundCardModern: View {
    let sound: RealSound
    let isPlaying: Bool
    var isFavorite: Bool = false
    let onTap: () -> Void
    var onFavoriteTap: (() -> Void)? = nil
    
    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0
    
    private var cardContent: some View {
        VStack(spacing: 0) {
            // Image
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [sound.color, sound.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    // Sound visualization or icon
                    Text(sound.emoji)
                        .font(.system(size: 40))
                        .scaleEffect(isPlaying ? pulseScale : 1.0)
                        .animation(
                            isPlaying ? 
                            Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                            .easeOut(duration: 0.3),
                            value: isPlaying
                        )
                }
                .aspectRatio(1, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: 4) {
                        if let onFavoriteTap = onFavoriteTap {
                            Button(action: onFavoriteTap) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.caption)
                                    .foregroundColor(isFavorite ? .red : .white)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .frame(width: 24, height: 24)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if sound.premium {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 24, height: 24)
                                )
                        }
                    }
                    .padding(8)
                }
            
            // Title
            VStack(spacing: 4) {
                Text(sound.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if isPlaying {
                    Text("Playing")
                        .font(.caption)
                        .foregroundColor(.pink)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
            .frame(height: 50)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(currentScale)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: handlePress, perform: {})
        .onAppear(perform: handleAppear)
        .onChange(of: isPlaying) { _, newValue in
            handlePlayingChange(false, newValue)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sound.title)
        .accessibilityHint(accessibilityHintText)
        .accessibilityValue(isPlaying ? "Playing" : "Stopped")
        .accessibilityAddTraits(isPlaying ? [.isSelected] : [])
        .accessibilityAction(.default) { onTap() }
        .accessibilityAction(named: favoriteActionName) {
            onFavoriteTap?()
        }
    }
    
    private var currentScale: CGFloat {
        isPressed ? 0.95 : (isPlaying ? 1.05 : 1.0)
    }
    
    private var accessibilityHintText: String {
        isPlaying ? "Currently playing. Tap to open player controls." : "Tap to play this sound."
    }
    
    private var favoriteActionName: String {
        isFavorite ? "Remove from favorites" : "Add to favorites"
    }
    
    private func handlePress(_ pressing: Bool) {
        withAnimation(.easeInOut(duration: 0.1)) {
            isPressed = pressing
        }
    }
    
    private func handleAppear() {
        if isPlaying {
            pulseScale = 1.1
        }
    }
    
    private func handlePlayingChange(_ oldValue: Bool, _ newValue: Bool) {
        withAnimation {
            pulseScale = newValue ? 1.1 : 1.0
        }
    }
}

// MARK: - Loading View

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

// MARK: - Error View

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

// MARK: - Player View

struct PlayerView: View {
    let sound: RealSound
    @EnvironmentObject var soundManager: RealSoundManager
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var sleepTimer = SleepTimerManager.shared
    @StateObject private var fadeOutManager = FadeOutManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingTimer = false
    @State private var showingMixer = false
    @State private var timerHours = 0
    @State private var timerMinutes = 10
    
    private var isPlaying: Bool {
        soundManager.isPlaying(sound.id)
    }
    
    private var volume: Double {
        soundManager.getVolume(for: sound.id)
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [sound.color.opacity(0.3), sound.color.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Chevron down
                    Image(systemName: "chevron.down")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Sound Card
                VStack(spacing: 24) {
                    // Large sound visualization
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [sound.color, sound.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 280, height: 280)
                        .overlay {
                            Text(sound.emoji)
                                .font(.system(size: 80))
                        }
                        .shadow(color: sound.color.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Title and favorite
                    HStack {
                        Text(sound.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            HapticManager.shared.favoriteToggle()
                            favoritesManager.toggleFavorite(sound)
                        }) {
                            Image(systemName: favoritesManager.isFavorite(sound) ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(favoritesManager.isFavorite(sound) ? .red : .secondary)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Volume Control
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "speaker.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(
                                value: Binding(
                                    get: { volume },
                                    set: { soundManager.setVolume($0, for: sound.id) }
                                ),
                                in: 0...1
                            )
                            .accentColor(.pink)
                            
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    // Timer Display
                    VStack(spacing: 12) {
                        if sleepTimer.isActive {
                            VStack(spacing: 8) {
                                Text("Sleep Timer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    
                                    Text(sleepTimer.formattedTimeRemaining)
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                }
                                
                                // Progress bar
                                ProgressView(value: sleepTimer.progressPercentage)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                                    .frame(width: 120)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                        
                        if fadeOutManager.isActiveFade {
                            VStack(spacing: 8) {
                                Text("Fade Out")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "minus.magnifyingglass")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Text(fadeOutManager.formattedTimeRemaining)
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                                
                                // Progress bar
                                ProgressView(value: fadeOutManager.fadeProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                    .frame(width: 120)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                    }
                    
                    // Control Buttons
                    HStack(spacing: 60) {
                        // Play/Pause
                        Button(action: {
                            soundManager.toggleSound(sound)
                        }) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.pink)
                        }
                        
                        // Stop
                        Button(action: {
                            if isPlaying {
                                soundManager.toggleSound(sound)
                            }
                        }) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.pink)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Bottom Controls
                    HStack(spacing: 80) {
                        // Timer
                        VStack(spacing: 4) {
                            Button(action: { 
                                if sleepTimer.isActive {
                                    sleepTimer.stopTimer()
                                } else {
                                    showingTimer = true 
                                }
                            }) {
                                Image(systemName: sleepTimer.isActive ? "timer.circle.fill" : "timer")
                                    .font(.title2)
                                    .foregroundColor(sleepTimer.isActive ? .orange : .secondary)
                            }
                            Text(sleepTimer.isActive ? "Stop" : "Timer")
                                .font(.caption)
                                .foregroundColor(sleepTimer.isActive ? .orange : .secondary)
                        }
                        
                        // Fade out
                        VStack(spacing: 4) {
                            Button(action: {
                                if fadeOutManager.isActiveFade {
                                    soundManager.stopFadeOut()
                                } else {
                                    soundManager.fadeOutAllSounds(duration: 10.0)
                                }
                            }) {
                                Image(systemName: fadeOutManager.isActiveFade ? "pause.circle.fill" : "minus.magnifyingglass")
                                    .font(.title2)
                                    .foregroundColor(fadeOutManager.isActiveFade ? .orange : .blue)
                            }
                            Text(fadeOutManager.isActiveFade ? "Stop Fade" : "Fade out")
                                .font(.caption)
                                .foregroundColor(fadeOutManager.isActiveFade ? .orange : .blue)
                        }
                        
                        // Mixer
                        VStack(spacing: 4) {
                            Button(action: { showingMixer = true }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                            }
                            Text("Mixer")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                        
                        // AirPlay
                        VStack(spacing: 4) {
                            Button(action: {}) {
                                Image(systemName: "airplayaudio")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            Text("AirPlay/BT")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 40)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingTimer) {
            TimerPickerView(
                hours: $timerHours,
                minutes: $timerMinutes,
                isPresented: $showingTimer
            )
            .environmentObject(soundManager)
        }
        .sheet(isPresented: $showingMixer) {
            MixingControlView()
                .environmentObject(soundManager)
        }
    }
}

// MARK: - Timer Picker

struct TimerPickerView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var isPresented: Bool
    @EnvironmentObject var soundManager: RealSoundManager
    @StateObject private var sleepTimer = SleepTimerManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color.pink.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text("Choose how long the player should play")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Picker
                    HStack(spacing: 20) {
                        // Hours
                        VStack {
                            Picker("Hours", selection: $hours) {
                                ForEach(0...6, id: \.self) { hour in
                                    Text("\(hour)")
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 60, height: 120)
                            .clipped()
                        }
                        
                        Text("hours")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        // Minutes
                        VStack {
                            Picker("Minutes", selection: $minutes) {
                                ForEach(Array(stride(from: 0, through: 50, by: 10)), id: \.self) { minute in
                                    Text("\(minute)")
                                        .tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 60, height: 120)
                            .clipped()
                        }
                        
                        Text("min")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    
                    Button("Start Timer") {
                        let totalMinutes = hours * 60 + minutes
                        let duration = TimeInterval(totalMinutes * 60)
                        
                        sleepTimer.startTimer(duration: duration) {
                            // Stop all playing sounds when timer completes
                            Task { @MainActor in
                                soundManager.stopAllSounds()
                                print("⏰ Sleep timer completed - all sounds stopped")
                            }
                        }
                        
                        isPresented = false
                    }
                    .disabled(hours == 0 && minutes == 0)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill((hours == 0 && minutes == 0) ? Color.gray.opacity(0.3) : Color.white)
                    )
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
}

// MARK: - Now Playing Bar

struct NowPlayingBar: View {
    @EnvironmentObject var soundManager: RealSoundManager
    @StateObject private var sleepTimer = SleepTimerManager.shared
    @StateObject private var fadeOutManager = FadeOutManager.shared
    @State private var showingMixer = false
    
    var body: some View {
        if let firstPlayingSound = soundManager.allSounds.first(where: { soundManager.isPlaying($0.id) }) {
            HStack(spacing: 12) {
                // Sound icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(firstPlayingSound.color.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(firstPlayingSound.emoji)
                            .font(.title3)
                    }
                
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
                    Button(action: {}) {
                        Image(systemName: "speaker.wave.2")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        // Mixer button (if multiple sounds playing)
                        if soundManager.playingTracks.count > 1 {
                            Button(action: { showingMixer = true }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        // Play/Pause button
                        Button(action: {
                            soundManager.toggleSound(firstPlayingSound)
                        }) {
                            Image(systemName: "pause.fill")
                                .font(.title3)
                                .foregroundColor(.pink)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .sheet(isPresented: $showingMixer) {
                MixingControlView()
                    .environmentObject(soundManager)
            }
        }
    }
}

// MARK: - Favorites Manager

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
    }
}

// MARK: - Favorites View

struct FavoritesView: View {
    @EnvironmentObject var soundManager: RealSoundManager
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedSound: RealSound?
    @State private var showingPlayer = false
    
    var favoriteSounds: [RealSound] {
        soundManager.allSounds.filter { favoritesManager.isFavorite($0) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if favoriteSounds.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 16) {
                            ForEach(favoriteSounds) { sound in
                                SoundCardModern(
                                    sound: sound,
                                    isPlaying: soundManager.isPlaying(sound.id),
                                    isFavorite: true,
                                    onTap: {
                                        selectedSound = sound
                                        showingPlayer = true
                                    },
                                    onFavoriteTap: {
                                        favoritesManager.toggleFavorite(sound)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingPlayer) {
            if let sound = selectedSound {
                PlayerView(sound: sound)
                    .environmentObject(soundManager)
                    .environmentObject(FavoritesManager.shared)
            }
        }
    }
}

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

// MARK: - Premium Upgrade View

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
                            
                            Text("Get access to all premium sounds, unlimited mixing, and advanced features")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                        }
                        
                        // Features
                        VStack(spacing: 16) {
                            FeatureRow(icon: "music.note.list", title: "50+ Premium Sounds", subtitle: "Exclusive high-quality audio")
                            FeatureRow(icon: "slider.horizontal.3", title: "Advanced Mixing", subtitle: "Up to 4 sounds simultaneously")
                            FeatureRow(icon: "timer", title: "Extended Sleep Timer", subtitle: "Custom timer up to 8 hours")
                            FeatureRow(icon: "heart.fill", title: "Unlimited Favorites", subtitle: "Save your perfect sound mix")
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
                // Require parent gate for purchases
                let parentGate = ParentGateManager.shared
                parentGate.requestAuthorization { authorized in
                    if authorized {
                        Task {
                            isLoading = true
                            await premiumManager.purchaseProduct(product)
                            isLoading = false
                            
                            if premiumManager.isPremium {
                                dismiss()
                            }
                        }
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
                        .stroke(product.id == "baby.annual" ? Color.green : Color.blue, lineWidth: product.id == "baby.annual" ? 2 : 1)
                )
        )
    }
}

// MARK: - Parent Gate View

struct ParentGateView: View {
    @EnvironmentObject var parentGate: ParentGateManager
    @State private var challenge = ParentGateManager.MathChallenge.generate()
    @State private var selectedAnswer: Int?
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                            .symbolEffect(.pulse)
                        
                        Text("Parental Verification")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("This action requires adult supervision. Please solve the math problem below.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                    }
                    
                    // Math Challenge
                    VStack(spacing: 24) {
                        Text(challenge.question)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(challenge.options, id: \.self) { option in
                                Button(action: {
                                    selectedAnswer = option
                                    showError = false
                                }) {
                                    Text("\(option)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(selectedAnswer == option ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 60)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(selectedAnswer == option ? Color.blue : Color(.tertiarySystemFill))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        if showError {
                            Text("Incorrect answer. Please try again.")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button("Submit Answer") {
                            guard let answer = selectedAnswer else { return }
                            
                            if parentGate.verifyAnswer(answer, for: challenge) {
                                dismiss()
                            } else {
                                showError = true
                                selectedAnswer = nil
                                // Generate new challenge
                                challenge = ParentGateManager.MathChallenge.generate()
                            }
                        }
                        .disabled(selectedAnswer == nil)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial)
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        parentGate.cancel()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Sleep Schedules View

struct SleepSchedulesView: View {
    @EnvironmentObject var soundManager: RealSoundManager
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var parentGateManager: ParentGateManager
    @StateObject private var scheduleManager = SleepScheduleManager.shared
    
    @State private var showingAddSchedule = false
    @State private var showingPermissionAlert = false
    @State private var showingPremiumUpgrade = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Header с информацией о следующем событии
                        if let nextEvent = scheduleManager.nextScheduledEvent {
                            NextEventCard(event: nextEvent)
                        }
                        
                        // Список расписаний
                        ForEach(scheduleManager.schedules) { schedule in
                            ScheduleCard(
                                schedule: schedule,
                                onToggle: {
                                    Task {
                                        try? await scheduleManager.toggleSchedule(schedule)
                                    }
                                },
                                onEdit: {
                                    // TODO: Implement edit
                                },
                                onDelete: {
                                    Task {
                                        await scheduleManager.deleteSchedule(schedule)
                                    }
                                }
                            )
                        }
                        
                        if scheduleManager.schedules.isEmpty {
                            EmptySchedulesView {
                                addNewSchedule()
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Sleep Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addNewSchedule) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .task {
                await scheduleManager.checkAndRequestNotificationPermission()
            }
            .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Sleep schedules need notification permission to remind you about bedtime.")
            }
            .sheet(isPresented: $showingPremiumUpgrade) {
                PremiumUpgradeView()
                    .environmentObject(premiumManager)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func addNewSchedule() {
        // Проверяем premium лимиты
        if !premiumManager.isPremium && scheduleManager.schedules.count >= 1 {
            showingPremiumUpgrade = true
            return
        }
        
        // Требуем родительский контроль для добавления расписаний
        parentGateManager.requestAuthorization { authorized in
            if authorized {
                showingAddSchedule = true
            }
        }
    }
}

struct NextEventCard: View {
    let event: (schedule: SleepSchedule, time: Date, type: String)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: event.type == "reminder" ? "bell.fill" : "moon.zzz.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.type == "reminder" ? "Next Reminder" : "Next Bedtime")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(event.schedule.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(event.time, style: .time)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(event.time, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ScheduleCard: View {
    let schedule: SleepSchedule
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(schedule.selectedSounds.count) sounds selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: .constant(schedule.isEnabled))
                    .labelsHidden()
                    .onTapGesture {
                        onToggle()
                    }
            }
            
            HStack {
                // Время сна
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bedtime")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(schedule.bedTime, style: .time)
                        .font(.title3)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Дни недели
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatSelectedDays(schedule.selectedDays))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            // Кнопки действий
            HStack {
                Button("Edit") {
                    onEdit()
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Delete") {
                    onDelete()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .opacity(schedule.isEnabled ? 1.0 : 0.6)
        )
    }
    
    private func formatSelectedDays(_ days: Set<Weekday>) -> String {
        if days.count == 7 {
            return "Every day"
        } else if days.count == 5 && !days.contains(.saturday) && !days.contains(.sunday) {
            return "Weekdays"
        } else if days.count == 2 && days.contains(.saturday) && days.contains(.sunday) {
            return "Weekends"
        } else {
            return days.map { $0.shortName }.sorted().joined(separator: ", ")
        }
    }
}

struct EmptySchedulesView: View {
    let onAddSchedule: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Sleep Schedules")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Create a bedtime routine with automatic sound playback")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onAddSchedule) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add First Schedule")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue)
                )
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Sleep Schedule Manager

@MainActor
class SleepScheduleManager: ObservableObject {
    static let shared = SleepScheduleManager()
    
    @Published var schedules: [SleepSchedule] = []
    @Published var isNotificationPermissionGranted: Bool = false
    
    private let userDefaultsKey = "SavedSleepSchedules"
    
    private init() {
        loadSchedules()
        checkNotificationPermission()
    }
    
    func checkAndRequestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        await MainActor.run {
            self.isNotificationPermissionGranted = settings.authorizationStatus == .authorized
        }
        
        if settings.authorizationStatus == .notDetermined {
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    self.isNotificationPermissionGranted = granted
                }
                print("✅ Notification permission granted: \(granted)")
            } catch {
                print("❌ Failed to request notification permission: \(error)")
            }
        }
    }
    
    func addSchedule(_ schedule: SleepSchedule) async throws {
        schedules.append(schedule)
        saveSchedules()
        
        if schedule.isEnabled {
            try await scheduleNotifications(for: schedule)
        }
        
        print("✅ Added sleep schedule: \(schedule.name)")
    }
    
    func toggleSchedule(_ schedule: SleepSchedule) async throws {
        guard let index = schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        
        schedules[index].isEnabled.toggle()
        schedules[index].lastModified = Date()
        
        if schedules[index].isEnabled {
            try await scheduleNotifications(for: schedules[index])
        } else {
            await removeNotifications(for: schedules[index])
        }
        
        saveSchedules()
    }
    
    func deleteSchedule(_ schedule: SleepSchedule) async {
        await removeNotifications(for: schedule)
        schedules.removeAll { $0.id == schedule.id }
        saveSchedules()
        print("🗑️ Deleted sleep schedule: \(schedule.name)")
    }
    
    private func scheduleNotifications(for schedule: SleepSchedule) async throws {
        guard isNotificationPermissionGranted else {
            throw NSError(domain: "SleepSchedule", code: 1, userInfo: [NSLocalizedDescriptionKey: "Notification permission required"])
        }
        
        // Simplified notification scheduling for demo
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications
        await removeNotifications(for: schedule)
        
        // Schedule reminder notification
        let content = UNMutableNotificationContent()
        content.title = "Bedtime Reminder"
        content.body = "Time for \(schedule.name) routine in \(schedule.reminderMinutes) minutes"
        content.sound = .default
        
        let calendar = Calendar.current
        let bedTimeComponents = calendar.dateComponents([.hour, .minute], from: schedule.bedTime)
        
        var triggerDate = DateComponents()
        triggerDate.hour = bedTimeComponents.hour
        triggerDate.minute = (bedTimeComponents.minute ?? 0) - schedule.reminderMinutes
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
        let request = UNNotificationRequest(identifier: schedule.reminderNotificationId, content: content, trigger: trigger)
        
        try await center.add(request)
        print("📅 Scheduled notifications for: \(schedule.name)")
    }
    
    private func removeNotifications(for schedule: SleepSchedule) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            schedule.reminderNotificationId,
            schedule.bedtimeNotificationId
        ])
    }
    
    private func checkNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            await MainActor.run {
                self.isNotificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func saveSchedules() {
        do {
            let data = try JSONEncoder().encode(schedules)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("💾 Saved \(schedules.count) sleep schedules")
        } catch {
            print("❌ Failed to save schedules: \(error)")
        }
    }
    
    private func loadSchedules() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("📱 No saved sleep schedules")
            return
        }
        
        do {
            schedules = try JSONDecoder().decode([SleepSchedule].self, from: data)
            print("📖 Loaded \(schedules.count) sleep schedules")
        } catch {
            print("❌ Failed to load schedules: \(error)")
        }
    }
    
    var nextScheduledEvent: (schedule: SleepSchedule, time: Date, type: String)? {
        let now = Date()
        let calendar = Calendar.current
        
        var nextEvent: (schedule: SleepSchedule, time: Date, type: String)?
        
        for schedule in schedules.filter({ $0.isEnabled }) {
            // Calculate next bedtime
            let bedTimeComponents = calendar.dateComponents([.hour, .minute], from: schedule.bedTime)
            
            for dayOffset in 0..<7 {
                guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                let weekday = Weekday(from: calendar.component(.weekday, from: targetDate))
                
                guard schedule.selectedDays.contains(weekday) else { continue }
                
                guard let scheduledBedTime = calendar.date(bySettingHour: bedTimeComponents.hour ?? 20,
                                                          minute: bedTimeComponents.minute ?? 0,
                                                          second: 0,
                                                          of: targetDate) else { continue }
                
                if scheduledBedTime > now {
                    if nextEvent == nil || scheduledBedTime < nextEvent!.time {
                        nextEvent = (schedule, scheduledBedTime, "bedtime")
                    }
                    break
                }
            }
        }
        
        return nextEvent
    }
}

// MARK: - Sleep Schedule Models

struct SleepSchedule: Identifiable, Codable {
    let id: UUID
    var name: String
    var isEnabled: Bool
    var bedTime: Date
    var selectedDays: Set<Weekday>
    var reminderMinutes: Int
    var selectedSounds: [String]
    var autoFadeMinutes: Int
    let dateCreated: Date
    var lastModified: Date
    
    init(
        id: UUID = UUID(),
        name: String = "My Sleep Schedule",
        isEnabled: Bool = true,
        bedTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
        selectedDays: Set<Weekday> = Set(Weekday.allCases),
        reminderMinutes: Int = 30,
        selectedSounds: [String] = [],
        autoFadeMinutes: Int = 45,
        dateCreated: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.bedTime = bedTime
        self.selectedDays = selectedDays
        self.reminderMinutes = reminderMinutes
        self.selectedSounds = selectedSounds
        self.autoFadeMinutes = autoFadeMinutes
        self.dateCreated = dateCreated
        self.lastModified = lastModified
    }
    
    var reminderNotificationId: String {
        "schedule_reminder_\(id.uuidString)"
    }
    
    var bedtimeNotificationId: String {
        "schedule_bedtime_\(id.uuidString)"
    }
}

enum Weekday: String, CaseIterable, Codable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
    
    init(from weekday: Int) {
        switch weekday {
        case 1: self = .sunday
        case 2: self = .monday
        case 3: self = .tuesday
        case 4: self = .wednesday
        case 5: self = .thursday
        case 6: self = .friday
        case 7: self = .saturday
        default: self = .monday
        }
    }
}

// MARK: - More View

struct MoreView: View {
    @EnvironmentObject var soundManager: RealSoundManager
    @EnvironmentObject var premiumManager: PremiumManager
    @StateObject private var safeVolumeManager = SafeVolumeManager.shared
    @StateObject private var parentGateManager = ParentGateManager.shared
    
    @State private var showingSettings = false
    @State private var showingParentGate = false
    @State private var showingPremiumSheet = false
    
    var body: some View {
        NavigationView {
            List {
                // Premium Status Section
                Section {
                    HStack {
                        Image(systemName: premiumManager.isPremium ? "crown.fill" : "crown")
                            .foregroundColor(premiumManager.isPremium ? .orange : .gray)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(premiumManager.isPremium ? "Premium Active" : "Free Plan")
                                .foregroundColor(.primary)
                            
                            Text(premiumManager.subscriptionStatus.displayText)
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
                    
                    if !premiumManager.isPremium {
                        Button("Restore Purchases") {
                            parentGateManager.requestAuthorization { authorized in
                                if authorized {
                                    Task {
                                        await premiumManager.restorePurchases()
                                    }
                                }
                            }
                        }
                        .foregroundColor(.blue)
                    }
                } header: {
                    Text("SUBSCRIPTION")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    HStack {
                        Text("Play sound right away when opening player")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("Change language")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("APP SETTINGS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Child Safety Section
                Section {
                    Button(action: {
                        parentGateManager.requestAuthorization { authorized in
                            if authorized {
                                showingSettings = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Child Safety Settings")
                                    .foregroundColor(.primary)
                                
                                Text("Volume limits, parental controls")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    HStack {
                        Image(systemName: safeVolumeManager.isSafeVolumeEnabled ? "speaker.2.fill" : "speaker.slash.fill")
                            .foregroundColor(safeVolumeManager.isSafeVolumeEnabled ? .green : .orange)
                            .frame(width: 24)
                        
                        Text("Safe Volume")
                        
                        Spacer()
                        
                        Toggle("", isOn: $safeVolumeManager.isSafeVolumeEnabled)
                            .labelsHidden()
                            .onChange(of: safeVolumeManager.isSafeVolumeEnabled) { _, enabled in
                                safeVolumeManager.setSafeVolumeEnabled(enabled)
                            }
                    }
                    
                    if safeVolumeManager.isParentalOverrideActive {
                        HStack {
                            Image(systemName: "lock.open")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Parental Override Active")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("Deactivate") {
                                safeVolumeManager.deactivateParentalOverride()
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                } header: {
                    Text("CHILD SAFETY")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } footer: {
                    if safeVolumeManager.isSafeVolumeEnabled {
                        Text("Volume is limited to 70% for child hearing protection (WHO guidelines)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        parentGateManager.requestAuthorization { authorized in
                            if authorized {
                                // Open App Store rating
                                if let url = URL(string: "https://apps.apple.com/app/id6670503696?action=write-review") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }) {
                        Label("Rate our app", systemImage: "star.fill")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        parentGateManager.requestAuthorization { authorized in
                            if authorized {
                                // Share app
                                let shareText = "Check out Baby Sounds - soothing sounds for babies!"
                                let activityController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first {
                                    window.rootViewController?.present(activityController, animated: true)
                                }
                            }
                        }
                    }) {
                        Label("Tell friends about the app", systemImage: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        parentGateManager.requestAuthorization { authorized in
                            if authorized {
                                // Send feedback email
                                if let url = URL(string: "mailto:support@babysounds.app?subject=Baby%20Sounds%20Feedback") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }) {
                        Label("Send us your feedback", systemImage: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("SUPPORT")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    HStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.gradient)
                            .frame(width: 50, height: 50)
                            .overlay {
                                Image(systemName: "moon.stars.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Check out our new app with lullabies songs. It's FREE for a limited time. Hurry up!")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                } header: {
                    Text("CHECK OUR OTHER APPS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: {
                        parentGateManager.requestAuthorization { authorized in
                            if authorized {
                                // Open privacy policy
                                if let url = URL(string: "https://babysounds.app/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                            Text("Privacy policy")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        parentGateManager.requestAuthorization { authorized in
                            if authorized {
                                // Open terms of use
                                if let url = URL(string: "https://babysounds.app/terms") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("Terms of Use")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        parentGateManager.requestAuthorization { authorized in
                            if authorized {
                                // Open acknowledgements
                                if let url = URL(string: "https://babysounds.app/acknowledgements") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Acknowledgement")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("LEGAL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } footer: {
                    Text("Sleep Baby 1.7.2 (20)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $parentGateManager.isShowingGate) {
            ParentGateView()
                .environmentObject(parentGateManager)
        }
        .sheet(isPresented: $showingSettings) {
            SafetySettingsView()
                .environmentObject(safeVolumeManager)
                .environmentObject(parentGateManager)
        }
        .sheet(isPresented: $showingPremiumSheet) {
            PremiumUpgradeView()
                .environmentObject(premiumManager)
        }
    }
}

// MARK: - Safety Settings View

struct SafetySettingsView: View {
    @EnvironmentObject var safeVolumeManager: SafeVolumeManager
    @EnvironmentObject var parentGateManager: ParentGateManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "speaker.2.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Safe Volume Limit")
                            Text("Maximum volume: 70% (WHO guidelines)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $safeVolumeManager.isSafeVolumeEnabled)
                            .labelsHidden()
                            .onChange(of: safeVolumeManager.isSafeVolumeEnabled) { _, enabled in
                                safeVolumeManager.setSafeVolumeEnabled(enabled)
                            }
                    }
                    
                    if !safeVolumeManager.isParentalOverrideActive {
                        Button("Temporarily Override (30 min)") {
                            parentGateManager.requestAuthorization { authorized in
                                if authorized {
                                    safeVolumeManager.activateParentalOverride()
                                }
                            }
                        }
                        .foregroundColor(.orange)
                    } else {
                        HStack {
                            Image(systemName: "lock.open")
                                .foregroundColor(.blue)
                            
                            Text("Override Active")
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Button("End Override") {
                                safeVolumeManager.deactivateParentalOverride()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                } header: {
                    Text("VOLUME PROTECTION")
                } footer: {
                    Text("Volume is automatically limited to protect children's hearing according to WHO guidelines (85dB exposure limit).")
                }
                
                Section {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Listening Time")
                            Text("Current session: \(Int(safeVolumeManager.currentListeningDuration / 60)) minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Break Reminders")
                            Text("Recommended after 45 minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                    }
                } header: {
                    Text("LISTENING SESSION")
                } footer: {
                    Text("Automatic break reminders help protect against hearing fatigue and encourage healthy listening habits.")
                }
                
                Section {
                    HStack {
                        Image(systemName: "shield.checkered")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Parent Gate Active")
                            Text("Protection for premium purchases")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    Button("Test Parent Gate") {
                        parentGateManager.requestAuthorization { _ in
                            // Just a test
                        }
                    }
                    .foregroundColor(.blue)
                } header: {
                    Text("PARENTAL CONTROLS")
                } footer: {
                    Text("Math challenges protect children from unintended purchases and settings changes.")
                }
            }
            .navigationTitle("Child Safety")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Sound Category Extension

extension SoundCategory {
    static let all = SoundCategory.nature // Используем nature как "All" для простоты
}

// MARK: - Real Models (упрощенные версии из BabySoundsCore)

enum SoundCategory: String, CaseIterable, Codable {
    case nature = "nature"
    case white = "white"
    case pink = "pink"
    case brown = "brown"
    case womb = "womb"
    case fan = "fan"
    
    var localizedName: String {
        switch self {
        case .nature: return "Nature"
        case .white: return "White Noise"
        case .pink: return "Pink Noise"
        case .brown: return "Brown Noise"
        case .womb: return "Womb Sounds"
        case .fan: return "Fan & Air"
        }
    }
    
    var emoji: String {
        switch self {
        case .nature: return "🌿"
        case .white: return "🌬️"
        case .pink: return "🌸"
        case .brown: return "🤎"
        case .womb: return "❤️"
        case .fan: return "💨"
        }
    }
}

// Реальная модель Sound (упрощенная версия)
struct RealSound: Identifiable {
    let id = UUID()
    let title: String
    let category: SoundCategory
    let fileName: String
    let fileExt: String
    let loop: Bool
    let premium: Bool
    let defaultGainDb: Float
    let color: Color
    let emoji: String
    
    init(title: String, category: SoundCategory, fileName: String, fileExt: String = "mp3", loop: Bool = true, premium: Bool = false, defaultGainDb: Float = 0.0, color: Color, emoji: String? = nil) {
        self.title = title
        self.category = category
        self.fileName = fileName
        self.fileExt = fileExt
        self.loop = loop
        self.premium = premium
        self.defaultGainDb = defaultGainDb
        self.color = color
        self.emoji = emoji ?? category.emoji
    }
    
    var filePath: String {
        "Resources/Sounds/\(category.rawValue)/\(fileName).\(fileExt)"
    }
}

// MARK: - Real Sound Manager с интеграцией AVAudioEngine

@MainActor
class RealSoundManager: ObservableObject {
    @Published var playingTracks: Set<UUID> = []
    @Published var trackVolumes: [UUID: Double] = [:]
    @Published var masterVolume: Double = 0.5 {
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
    
    private let maxConcurrentTracks = 4
    private let engine = AVAudioEngine()
    private var playerNodes: [UUID: AVAudioPlayerNode] = [:]
    private var audioFiles: [String: AVAudioFile] = [:]
    private let safeVolumeManager = SafeVolumeManager.shared
    private let fadeOutManager = FadeOutManager.shared
    
    // Реальные звуки с файлами
    let allSounds: [RealSound] = [
        // White Noise
        RealSound(title: "White Noise", category: .white, fileName: "white_noise", fileExt: "aiff", color: .gray, emoji: "🌀"),
        RealSound(title: "TV Static", category: .white, fileName: "white_noise", fileExt: "aiff", color: .gray, emoji: "📺"),
        
        // Pink Noise  
        RealSound(title: "Pink Noise", category: .pink, fileName: "pink_noise", fileExt: "aiff", color: .pink, emoji: "🌸"),
        RealSound(title: "Soft Pink", category: .pink, fileName: "pink_noise", fileExt: "aiff", premium: true, color: .purple, emoji: "💕"),
        
        // Brown Noise
        RealSound(title: "Brown Noise", category: .brown, fileName: "brown_noise", fileExt: "aiff", color: .brown, emoji: "🤎"),
        RealSound(title: "Deep Brown", category: .brown, fileName: "brown_noise", fileExt: "aiff", premium: true, color: .red, emoji: "🔥"),
        
        // Fan & Air
        RealSound(title: "Fan", category: .fan, fileName: "fan", fileExt: "aiff", color: .blue, emoji: "💨"),
        RealSound(title: "Hair Dryer", category: .fan, fileName: "fan", fileExt: "aiff", premium: true, color: .cyan, emoji: "💇‍♀️"),
        
        // Nature
        RealSound(title: "Ocean Waves", category: .nature, fileName: "white_noise", fileExt: "aiff", color: .blue, emoji: "🌊"),
        RealSound(title: "Rain", category: .nature, fileName: "pink_noise", fileExt: "aiff", color: .gray, emoji: "🌧️"),
        RealSound(title: "Forest", category: .nature, fileName: "brown_noise", fileExt: "aiff", premium: true, color: .green, emoji: "🌳"),
        
        // Womb
        RealSound(title: "Heartbeat", category: .womb, fileName: "fan", fileExt: "aiff", color: .red, emoji: "💓"),
        RealSound(title: "Womb Sounds", category: .womb, fileName: "white_noise", fileExt: "aiff", premium: true, color: .pink, emoji: "🤱"),
    ]
    
    func initializeAudio() {
        print("🎵 Initializing Real Audio System with AVAudioEngine...")
        
        // Настройка аудио сессии
        setupAudioSession()
        
        // Настройка аудио движка
        setupAudioEngine()
        
        // Инициализация SafeVolumeManager
        safeVolumeManager.startListeningSession()
        
        // Применение безопасной громкости
        let safeInitialVolume = safeVolumeManager.applySafeVolume(to: Float(masterVolume))
        masterVolume = Double(safeInitialVolume)
        
        // Симуляция инициализации (на случай проблем с аудио файлами)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isAudioReady = true
            print("✅ Real Audio System Ready with SafeVolumeManager")
        }
        
        // Инициализация громкости для всех звуков
        for sound in allSounds {
            trackVolumes[sound.id] = 0.5
        }
        
        // Настройка наблюдения за fade out для обновления громкости
        setupFadeOutObserver()
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
        do {
            // Подключение главного микшера к выходу
            let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: format)
            
            // Запуск движка
            try engine.start()
            print("✅ Audio engine started")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
        }
    }
    
    func sounds(for category: SoundCategory) -> [RealSound] {
        return allSounds.filter { $0.category == category }
    }
    
    func isPlaying(_ soundId: UUID) -> Bool {
        return playingTracks.contains(soundId)
    }
    
    func getVolume(for soundId: UUID) -> Double {
        return trackVolumes[soundId] ?? 0.5
    }
    
    func toggleSound(_ sound: RealSound) {
        guard isAudioReady else { return }
        
        if playingTracks.contains(sound.id) {
            stopSound(sound)
        } else {
            playSound(sound)
        }
    }
    
    private func playSound(_ sound: RealSound) {
        guard playingTracks.count < maxConcurrentTracks else {
            print("⚠️ Maximum \(maxConcurrentTracks) sounds playing")
            return
        }
        
        // Попытка загрузить реальный аудио файл
        if let audioFile = loadAudioFile(for: sound) {
            playRealAudio(sound: sound, audioFile: audioFile)
        } else {
            // Fallback: симуляция воспроизведения
            playSimulatedAudio(sound: sound)
        }
    }
    
    private func loadAudioFile(for sound: RealSound) -> AVAudioFile? {
        let cacheKey = "\(sound.fileName).\(sound.fileExt)"
        
        // Проверяем кэш
        if let cachedFile = audioFiles[cacheKey] {
            return cachedFile
        }
        
        // Пытаемся загрузить из bundle
        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExt) else {
            print("❌ Audio file not found: \(sound.fileName).\(sound.fileExt)")
            return nil
        }
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            audioFiles[cacheKey] = audioFile
            print("✅ Loaded audio file: \(sound.fileName).\(sound.fileExt) - Duration: \(Double(audioFile.length) / audioFile.fileFormat.sampleRate)s")
            return audioFile
        } catch {
            print("❌ Failed to load audio file: \(error)")
            return nil
        }
    }
    
    private func playRealAudio(sound: RealSound, audioFile: AVAudioFile) {
        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        
        // Подключение к микшеру
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFile.processingFormat)
        
        // Создание буфера
        guard let buffer = createBuffer(from: audioFile) else {
            print("❌ Failed to create buffer for \(sound.fileName)")
            return
        }
        
        // Планирование воспроизведения
        if sound.loop {
            playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        } else {
            playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
                DispatchQueue.main.async {
                    self?.stopSound(sound)
                }
            })
        }
        
        // Запуск воспроизведения
        playerNode.play()
        
        // Сохранение ссылок
        playerNodes[sound.id] = playerNode
        playingTracks.insert(sound.id)
        
        // Обновление Now Playing Info
        updateNowPlayingInfo(with: sound)
        
        print("▶️ Playing real audio: \(sound.title)")
    }
    
    private func playSimulatedAudio(sound: RealSound) {
        playingTracks.insert(sound.id)
        
        // Обновление Now Playing Info для симуляции
        updateNowPlayingInfo(with: sound)
        
        print("▶️ Playing simulated: \(sound.title) (\(sound.fileName))")
    }
    
    private func updateNowPlayingInfo(with sound: RealSound) {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = sound.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Baby Sounds"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = sound.category.localizedName
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
        
        // Для зацикленных звуков ставим большую длительность
        if sound.loop {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 3600.0 // 1 час
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        print("🎵 Updated Now Playing: \(sound.title)")
    }
    
    private func createBuffer(from audioFile: AVAudioFile) -> AVAudioPCMBuffer? {
        let frameCount = UInt32(audioFile.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: frameCount) else {
            return nil
        }
        
        do {
            try audioFile.read(into: buffer)
            return buffer
        } catch {
            print("❌ Failed to read audio file into buffer: \(error)")
            return nil
        }
    }
    
    func stopSound(_ sound: RealSound) {
        playingTracks.remove(sound.id)
        
        // Остановка реального воспроизведения
        if let playerNode = playerNodes[sound.id] {
            playerNode.stop()
            engine.detach(playerNode)
            playerNodes.removeValue(forKey: sound.id)
            print("⏹️ Stopped real audio: \(sound.title)")
        } else {
            print("⏹️ Stopped simulated: \(sound.title)")
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
    }
    
    func stopFadeOut() {
        fadeOutManager.stopFadeOut()
    }
    
    func setVolume(_ volume: Double, for soundId: UUID) {
        trackVolumes[soundId] = volume
        
        // Применение громкости к реальному воспроизведению с учетом fade out
        if let playerNode = playerNodes[soundId] {
            let fadeMultiplier = fadeOutManager.currentVolumeMultiplier
            let finalVolume = Float(volume * masterVolume) * fadeMultiplier
            playerNode.volume = finalVolume
        }
        
        if let sound = allSounds.first(where: { $0.id == soundId }) {
            let fadeInfo = fadeOutManager.isActiveFade ? " (fade: \(Int(fadeOutManager.currentVolumeMultiplier * 100))%)" : ""
            print("🔊 \(sound.title) volume: \(Int(volume * 100))%\(fadeInfo)")
        }
    }
    
    private func updateMasterVolume() {
        // Обновление громкости для всех активных треков с учетом fade out
        let fadeMultiplier = fadeOutManager.currentVolumeMultiplier
        for (soundId, playerNode) in playerNodes {
            let trackVolume = trackVolumes[soundId] ?? 0.5
            let finalVolume = Float(trackVolume * masterVolume) * fadeMultiplier
            playerNode.volume = finalVolume
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

// MARK: - Mixing Control View

struct MixingControlView: View {
    @EnvironmentObject var soundManager: RealSoundManager
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var playingSounds: [RealSound] {
        soundManager.allSounds.filter { soundManager.isPlaying($0.id) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Sound Mixer")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Stop All") {
                        soundManager.stopAllSounds()
                    }
                    .foregroundColor(.red)
                    .opacity(playingSounds.isEmpty ? 0.5 : 1.0)
                    .disabled(playingSounds.isEmpty)
                }
                .padding()
                .background(Color(.systemGray6))
                
                if playingSounds.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Sounds Playing")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Start playing sounds to control their individual volumes here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(playingSounds, id: \.id) { sound in
                                MixingControlCard(sound: sound)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemBackground))
        }
    }
}

struct MixingControlCard: View {
    let sound: RealSound
    @EnvironmentObject var soundManager: RealSoundManager
    
    @State private var localVolume: Double = 0.5
    
    var body: some View {
        VStack(spacing: 16) {
            // Sound info
            VStack(spacing: 8) {
                // Icon/emoji
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [sound.color, sound.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 60)
                    .overlay {
                        Text(sound.emoji)
                            .font(.system(size: 24))
                    }
                
                Text(sound.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }
            
            // Volume control
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(localVolume * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Slider(value: $localVolume, in: 0...1) { editing in
                        if !editing {
                            soundManager.setVolume(localVolume, for: sound.id)
                        }
                    }
                    .accentColor(sound.color)
                    
                    // Quick volume buttons
                    HStack(spacing: 8) {
                        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { volume in
                            Button(action: {
                                localVolume = volume
                                soundManager.setVolume(volume, for: sound.id)
                            }) {
                                Text("\(Int(volume * 100))")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(abs(localVolume - volume) < 0.1 ? .white : sound.color)
                                    .frame(width: 24, height: 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(abs(localVolume - volume) < 0.1 ? sound.color : sound.color.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
            }
            
            // Control buttons
            HStack(spacing: 12) {
                Button(action: {
                    soundManager.stopSound(sound)
                }) {
                    Image(systemName: "stop.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.red)
                        )
                }
                
                Button(action: {
                    // Solo - stop all other sounds except this one
                    let otherSounds = soundManager.allSounds.filter { $0.id != sound.id && soundManager.isPlaying($0.id) }
                    for otherSound in otherSounds {
                        soundManager.stopSound(otherSound)
                    }
                }) {
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.orange)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .onAppear {
            localVolume = soundManager.trackVolumes[sound.id] ?? 0.5
        }
        .onChange(of: soundManager.trackVolumes[sound.id]) { oldValue, newValue in
            if let newValue = newValue {
                localVolume = newValue
            }
        }
    }
}

// MARK: - Safe Volume Manager

@MainActor
class SafeVolumeManager: ObservableObject {
    static let shared = SafeVolumeManager()
    
    @Published var isSafeVolumeEnabled: Bool = true
    @Published var isParentalOverrideActive: Bool = false
    @Published var currentListeningDuration: TimeInterval = 0
    
    // WHO recommended limits
    private let maxChildSafeVolume: Float = 0.7 // 70% = ~85dB
    private let defaultChildVolume: Float = 0.4
    private let warningThreshold: Float = 0.6
    
    private var sessionStartTime: Date?
    
    private init() {
        // Load settings from UserDefaults
        isSafeVolumeEnabled = UserDefaults.standard.object(forKey: "SafeVolumeEnabled") as? Bool ?? true
        isParentalOverrideActive = UserDefaults.standard.bool(forKey: "ParentalOverrideActive")
    }
    
    func applySafeVolume(to volume: Float) -> Float {
        guard isSafeVolumeEnabled && !isParentalOverrideActive else {
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
    
    func activateParentalOverride() {
        isParentalOverrideActive = true
        UserDefaults.standard.set(true, forKey: "ParentalOverrideActive")
        
        // Auto-deactivate after 30 minutes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1800) { [weak self] in
            self?.deactivateParentalOverride()
        }
        
        print("👨‍👩‍👧‍👦 Parental override activated (30 min)")
    }
    
    func deactivateParentalOverride() {
        isParentalOverrideActive = false
        UserDefaults.standard.set(false, forKey: "ParentalOverrideActive")
        print("👨‍👩‍👧‍👦 Parental override deactivated")
    }
}

// MARK: - Parent Gate Manager

@MainActor
class ParentGateManager: ObservableObject {
    static let shared = ParentGateManager()
    
    @Published var isShowingGate = false
    @Published var isAuthorized = false
    
    private var authorizationExpiry: Date?
    private let authorizationDuration: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    struct MathChallenge {
        let question: String
        let correctAnswer: Int
        let options: [Int]
        
        static func generate() -> MathChallenge {
            let a = Int.random(in: 5...25)
            let b = Int.random(in: 1...15)
            let operation = Bool.random() ? "+" : "-"
            
            let (question, answer) = operation == "+" ? 
                ("\(a) + \(b) = ?", a + b) : 
                ("\(a) - \(b) = ?", a - b)
            
            // Generate wrong options
            var options = [answer]
            while options.count < 4 {
                let wrongAnswer = answer + Int.random(in: -10...10)
                if wrongAnswer != answer && wrongAnswer >= 0 && !options.contains(wrongAnswer) {
                    options.append(wrongAnswer)
                }
            }
            options.shuffle()
            
            return MathChallenge(question: question, correctAnswer: answer, options: options)
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        // Check if already authorized and not expired
        if let expiry = authorizationExpiry, Date() < expiry {
            completion(true)
            return
        }
        
        // Show parent gate
        isShowingGate = true
        
        // Store completion for later
        self.authorizationCompletion = completion
    }
    
    func verifyAnswer(_ answer: Int, for challenge: MathChallenge) -> Bool {
        let isCorrect = answer == challenge.correctAnswer
        
        if isCorrect {
            // Grant authorization for 5 minutes
            authorizationExpiry = Date().addingTimeInterval(authorizationDuration)
            isAuthorized = true
            isShowingGate = false
            
            authorizationCompletion?(true)
            authorizationCompletion = nil
            
            print("✅ Parent gate passed - authorized for 5 minutes")
        } else {
            print("❌ Parent gate failed - incorrect answer")
            authorizationCompletion?(false)
        }
        
        return isCorrect
    }
    
    func cancel() {
        isShowingGate = false
        authorizationCompletion?(false)
        authorizationCompletion = nil
    }
    
    private var authorizationCompletion: ((Bool) -> Void)?
}

// MARK: - Sleep Timer Manager

@MainActor
class SleepTimerManager: ObservableObject {
    static let shared = SleepTimerManager()
    
    @Published var isActive: Bool = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    
    private var timer: Timer?
    private var onTimerComplete: (() -> Void)?
    
    private init() {}
    
    func startTimer(duration: TimeInterval, onComplete: @escaping () -> Void) {
        stopTimer() // Stop any existing timer
        
        self.totalTime = duration
        self.timeRemaining = duration
        self.isActive = true
        self.onTimerComplete = onComplete
        
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
        print("⏰ Sleep timer started: \(Int(duration/60)) minutes")
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
        
        print("⏰ Added \(Int(additionalTime/60)) minutes to sleep timer")
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

// MARK: - Fade Out Manager

@MainActor
class FadeOutManager: ObservableObject {
    static let shared = FadeOutManager()
    
    @Published var isActiveFade: Bool = false
    @Published var fadeProgress: Double = 0.0
    
    private var fadeTimer: Timer?
    private var fadeStartTime: Date?
    private var totalFadeDuration: TimeInterval = 0
    private var onFadeComplete: (() -> Void)?
    
    private init() {}
    
    func startFadeOut(duration: TimeInterval = 10.0, onComplete: @escaping () -> Void) {
        stopFadeOut() // Stop any existing fade
        
        self.totalFadeDuration = duration
        self.fadeStartTime = Date()
        self.isActiveFade = true
        self.fadeProgress = 0.0
        self.onFadeComplete = onComplete
        
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
        "baby.annual"
    ]
    
    enum SubscriptionStatus {
        case notSubscribed
        case subscribed(Product)
        case inTrial(Product)
        case expired(Product)
        
        var isActive: Bool {
            switch self {
            case .subscribed, .inTrial:
                return true
            case .notSubscribed, .expired:
                return false
            }
        }
        
        var displayText: String {
            switch self {
            case .notSubscribed:
                return "Not Subscribed"
            case .subscribed(let product):
                return "Premium Active - \(product.displayName)"
            case .inTrial(let product):
                return "Free Trial - \(product.displayName)"
            case .expired(let product):
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
            
            self.availableProducts = sortedProducts
            self.productsLoaded = true
            self.lastError = nil
            
            print("✅ [StoreKit] Loaded \(products.count) products")
            for product in products {
                print("  • \(product.id): \(product.displayPrice) - \(product.displayName)")
            }
            
        } catch {
            print("❌ [StoreKit] Failed to load products: \(error)")
            self.lastError = "Failed to load products: \(error.localizedDescription)"
        }
    }
    
    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Handle successful purchase
                switch verification {
                case .verified(let transaction):
                    print("✅ Purchase successful: \(transaction.productID)")
                    await updateSubscriptionStatus()
                    await transaction.finish()
                case .unverified(_, let verificationError):
                    print("❌ Transaction unverified: \(verificationError)")
                    self.lastError = "Transaction verification failed"
                }
            case .userCancelled:
                print("🚫 User cancelled purchase")
                self.lastError = nil
            case .pending:
                print("⏳ Purchase pending...")
                self.lastError = "Purchase is pending"
            @unknown default:
                print("❓ Unknown purchase result")
                self.lastError = "Unknown purchase result"
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            self.lastError = "Purchase failed: \(error.localizedDescription)"
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ Purchases restored successfully")
            self.lastError = nil
        } catch {
            print("❌ Restore failed: \(error)")
            self.lastError = "Restore failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Methods
    
    private func startTransactionObserver() {
        transactionUpdateTask = Task.detached {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    print("🔄 Transaction update: \(transaction.productID)")
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                case .unverified(_, let error):
                    print("❌ Unverified transaction: \(error)")
                }
            }
        }
    }
    
    private func updateSubscriptionStatus() async {
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if productIds.contains(transaction.productID) {
                    // Find the product
                    if let product = availableProducts.first(where: { $0.id == transaction.productID }) {
                        // Check if it's still valid
                        if let expirationDate = transaction.expirationDate,
                           expirationDate > Date() {
                            
                            // Check if in trial period
                            if let statusArray = try? await product.subscription?.status {
                                for status in statusArray {
                                    switch status.state {
                                    case .subscribed:
                                        self.subscriptionStatus = .subscribed(product)
                                        print("💎 Premium subscription active: \(product.displayName)")
                                        return
                                    case .inBillingRetryPeriod, .inGracePeriod:
                                        self.subscriptionStatus = .subscribed(product)
                                        print("💎 Premium subscription active (grace period): \(product.displayName)")
                                        return
                                    case .revoked, .expired:
                                        self.subscriptionStatus = .expired(product)
                                        print("💎 Subscription expired: \(product.displayName)")
                                        break
                                    default:
                                        print("💎 Unknown subscription state: \(status.state)")
                                        break
                                    }
                                }
                            }
                            
                            // Fallback: assume subscribed if we have a valid transaction
                            self.subscriptionStatus = .subscribed(product)
                            print("💎 Premium subscription active: \(product.displayName)")
                            return
                        } else {
                            self.subscriptionStatus = .expired(product)
                            print("💎 Subscription expired: \(product.displayName)")
                        }
                    }
                }
            case .unverified(_, let error):
                print("❌ Unverified entitlement: \(error)")
            }
        }
        
        // No active subscription found
        self.subscriptionStatus = .notSubscribed
        print("💎 No active subscription")
    }
}

// MARK: - Premium Manager

@MainActor
class PremiumManager: ObservableObject {
    static let shared = PremiumManager()
    
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    
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
        guard let monthlyProduct = subscriptionService.availableProducts.first(where: { $0.id == "baby.monthly" }) else {
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

// MARK: - Color Extensions

extension Color {
    static let softPink = Color(red: 1.0, green: 0.7, blue: 0.8)
}

#Preview {
    ContentView()
} 