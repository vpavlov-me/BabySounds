import SwiftUI

// MARK: - Sound Cell

struct SoundCell: View {
    let sound: Sound
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var premiumManager: PremiumManager
    @ObservedObject var favoritesManager = FavoritesManager.shared
    
    @State private var dragOffset: CGSize = .zero
    @State private var showPremiumAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            artworkView
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Title
                    Text(sound.titleKey)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Premium badge
                    if sound.premium && !premiumManager.isPremium {
                        premiumBadge
                    }
                    
                    // More options button
                    Button {
                        // Handle more options
                        HapticManager.shared.impact(.light)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                    }
                }
                
                // Category
                Text(sound.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Playing indicator
            if audioManager.currentSound?.id == sound.id && audioManager.isPlaying {
                playingIndicator
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        )
        .offset(x: dragOffset.width)
        .background(
            // Swipe action background
            swipeActionBackground
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    if value.translation.x > 80 {
                        // Swipe right to favorite
                        toggleFavorite()
                        HapticManager.shared.impact(.medium)
                    }
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                }
        )
        .onTapGesture {
            playSound()
        }
        .alert("Premium Required", isPresented: $showPremiumAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Upgrade") {
                // Show paywall
            }
        } message: {
            Text("This sound requires a premium subscription to play.")
        }
    }
    
    // MARK: - Artwork View
    
    private var artworkView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: sound.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            Text(sound.displayEmoji)
                .font(.title2)
        }
        .frame(width: 44, height: 44)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Premium Badge
    
    private var premiumBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption2)
                .foregroundColor(.orange)
            
            Text("Premium")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
    }
    
    // MARK: - Playing Indicator
    
    private var playingIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(.pink)
                    .frame(width: 3, height: CGFloat.random(in: 8...16))
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever()
                        .delay(Double(index) * 0.1),
                        value: audioManager.isPlaying
                    )
            }
        }
        .frame(width: 16, height: 16)
    }
    
    // MARK: - Swipe Action Background
    
    private var swipeActionBackground: some View {
        HStack {
            if dragOffset.width > 0 {
                // Right swipe - favorite action
                HStack {
                    Image(systemName: favoritesManager.isFavorite(sound.id) ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(.pink)
                        .padding(.leading, 16)
                    
                    Spacer()
                }
                .background(Color.pink.opacity(0.1))
            }
            
            Spacer()
        }
    }
    
    // MARK: - Private Methods
    
    private func playSound() {
        if sound.premium && !premiumManager.isPremium {
            showPremiumAlert = true
            HapticManager.shared.notification(.warning)
            return
        }
        
        // Stop current sound if playing a different one
        if audioManager.currentSound?.id != sound.id {
            audioManager.stopAllSounds()
        }
        
        // Toggle playback
        if audioManager.currentSound?.id == sound.id && audioManager.isPlaying {
            audioManager.pauseCurrentSound()
        } else {
            Task {
                do {
                    try await audioManager.playSound(sound)
                    HapticManager.shared.impact(.light)
                } catch {
                    print("Failed to play sound: \(error)")
                    HapticManager.shared.notification(.error)
                }
            }
        }
    }
    
    private func toggleFavorite() {
        if favoritesManager.isFavorite(sound.id) {
            favoritesManager.removeFavorite(sound.id)
        } else {
            favoritesManager.addFavorite(sound)
        }
        HapticManager.shared.impact(.soft)
    }
}

// MARK: - Section Header

struct SectionHeaderView: View {
    let title: String
    let isSticky: Bool = true
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SectionHeaderView(title: "White Noise")
        
        SoundCell(sound: Sound(
            id: "white_noise",
            filename: "white_noise.mp3",
            titleKey: "White Noise",
            category: .white,
            premium: false,
            duration: 0
        ))
        
        SoundCell(sound: Sound(
            id: "forest_rain",
            filename: "forest_rain.mp3",
            titleKey: "Forest Rain",
            category: .nature,
            premium: true,
            duration: 0
        ))
    }
    .environmentObject(AudioEngineManager.shared)
    .environmentObject(PremiumManager.shared)
} 