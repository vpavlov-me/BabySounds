import SwiftUI
import AVFoundation

// MARK: - Now Playing View

struct NowPlayingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var soundCatalog: SoundCatalog
    
    @State private var selectedTimerMinutes = 0 // 0 = infinite
    @State private var volume: Double = 0.7
    @State private var showTimerPicker = false
    @State private var showVolumeControl = false
    @State private var dragOffset: CGSize = .zero
    @State private var isFavorite = false
    
    private let timerOptions = [0, 15, 30, 45, 60, 90, 120] // 0 = infinite
    
    var body: some View {
        if let currentSound = audioManager.currentSound {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    LinearGradient(
                        colors: currentSound.gradientColors + [Color.black.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    // Main content
                    VStack(spacing: 0) {
                        // Header
                        header
                        
                        Spacer()
                        
                        // Artwork
                        artworkSection(geometry: geometry)
                        
                        Spacer()
                        
                        // Controls
                        controlsSection
                        
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 24)
                    .offset(y: dragOffset.height)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.y > 0 {
                                dragOffset = value.translation
                            }
                        }
                        .onEnded { value in
                            if value.translation.y > 200 {
                                // Drag down to dismiss
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    isPresented = false
                                }
                                HapticManager.shared.impact(.medium)
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
            }
            .preferredColorScheme(.dark)
            .onAppear {
                setupView()
            }
            .actionSheet(isPresented: $showTimerPicker) {
                timerActionSheet
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // AirPlay button
            Button {
                // Handle AirPlay
                HapticManager.shared.impact(.light)
            } label: {
                Image(systemName: "airplayaudio")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // More options
            Button {
                // Handle more options
                HapticManager.shared.impact(.light)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Artwork Section
    
    private func artworkSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 24) {
            // Artwork with parallax effect
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: currentSound?.gradientColors ?? [.gray],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                if let currentSound = currentSound {
                    Text(currentSound.displayEmoji)
                        .font(.system(size: min(geometry.size.width * 0.3, 120)))
                }
            }
            .frame(width: 300, height: 300)
            .scaleEffect(1.0 - abs(dragOffset.height) / 1000)
            .rotation3DEffect(
                .degrees(dragOffset.height / 20),
                axis: (x: 1, y: 0, z: 0)
            )
            
            // Sound info
            VStack(spacing: 8) {
                Text(currentSound?.titleKey ?? "")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(currentSound?.category.displayName ?? "")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: 32) {
            // Main play controls
            HStack(spacing: 60) {
                // Favorite button
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title)
                        .foregroundColor(isFavorite ? .pink : .white)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Play/Pause button
                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Timer button
                Button {
                    showTimerPicker = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Text(timerDisplayText)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // Volume control
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Slider(value: $volume, in: 0...1) { editing in
                        if !editing {
                            audioManager.setVolume(volume)
                            HapticManager.shared.impact(.light)
                        }
                    }
                    .accentColor(.white)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Timer Action Sheet
    
    private var timerActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Sleep Timer"),
            message: Text("Choose how long to play"),
            buttons: timerOptions.map { minutes in
                .default(Text(minutes == 0 ? "Play Until Stopped" : "\(minutes) Minutes")) {
                    selectedTimerMinutes = minutes
                    setTimer(minutes: minutes)
                    HapticManager.shared.impact(.light)
                }
            } + [.cancel()]
        )
    }
    
    // MARK: - Computed Properties
    
    private var currentSound: Sound? {
        audioManager.currentSound
    }
    
    private var timerDisplayText: String {
        if selectedTimerMinutes == 0 {
            return "∞"
        } else {
            return "\(selectedTimerMinutes)m"
        }
    }
    
    // MARK: - Private Methods
    
    private func setupView() {
        volume = audioManager.currentVolume
        // Load favorite status
        if let sound = currentSound {
            isFavorite = FavoritesManager.shared.isFavorite(sound.id)
        }
    }
    
    private func togglePlayback() {
        if audioManager.isPlaying {
            audioManager.pauseCurrentSound()
        } else {
            audioManager.resumeCurrentSound()
        }
        HapticManager.shared.impact(.medium)
    }
    
    private func toggleFavorite() {
        guard let sound = currentSound else { return }
        
        if isFavorite {
            FavoritesManager.shared.removeFavorite(sound.id)
        } else {
            FavoritesManager.shared.addFavorite(sound)
        }
        
        isFavorite.toggle()
        HapticManager.shared.impact(.soft)
    }
    
    private func setTimer(minutes: Int) {
        if minutes == 0 {
            audioManager.clearTimer()
        } else {
            audioManager.setTimer(duration: TimeInterval(minutes * 60))
        }
    }
}

// MARK: - Favorites Manager (placeholder)

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favorites: Set<String> = []
    
    private init() {
        loadFavorites()
    }
    
    func isFavorite(_ soundId: String) -> Bool {
        favorites.contains(soundId)
    }
    
    func addFavorite(_ sound: Sound) {
        favorites.insert(sound.id)
        saveFavorites()
    }
    
    func removeFavorite(_ soundId: String) {
        favorites.remove(soundId)
        saveFavorites()
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "favorites"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favorites = decoded
        }
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: "favorites")
        }
    }
} 