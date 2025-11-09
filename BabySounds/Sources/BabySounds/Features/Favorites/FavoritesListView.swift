import SwiftUI

// MARK: - Favorites List View

struct FavoritesListView: View {
    @EnvironmentObject var soundCatalog: SoundCatalog
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var premiumManager: PremiumManager
    @ObservedObject var favoritesManager = FavoritesManager.shared
    
    @State private var isEditing = false
    @State private var showNowPlaying = false
    
    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                Group {
                    if favoriteSounds.isEmpty {
                        emptyStateView
                    } else {
                        favoritesList
                    }
                }
                
                // Mini Player
                MiniPlayerView(showNowPlaying: $showNowPlaying)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Favorites")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !favoriteSounds.isEmpty {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isEditing.toggle()
                        }
                        HapticManager.shared.impact(.light)
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView(isPresented: $showNowPlaying)
        }
    }
    
    // MARK: - Favorites List
    
    private var favoritesList: some View {
        List {
            ForEach(favoriteSounds, id: \.id) { sound in
                FavoriteCell(sound: sound, isEditing: isEditing)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .onMove(perform: isEditing ? moveItems : nil)
            .onDelete(perform: isEditing ? deleteItems : nil)
            
            // Bottom spacing for mini player
            Color.clear
                .frame(height: 100)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Illustration
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.pink.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "heart")
                        .font(.system(size: 40))
                        .foregroundColor(.pink.opacity(0.6))
                }
                
                VStack(spacing: 8) {
                    Text("No Favorites Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Swipe right on sounds to add them to your favorites")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            // Quick action button
            NavigationLink(destination: SleepListView()) {
                HStack {
                    Image(systemName: "plus")
                        .font(.headline)
                    Text("Browse Sounds")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.pink)
                .foregroundColor(.white)
                .cornerRadius(25)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Computed Properties
    
    private var favoriteSounds: [Sound] {
        let allSounds = soundCatalog.allSounds
        return favoritesManager.favoriteIds
            .compactMap { id in allSounds.first { $0.id == id } }
    }
    
    // MARK: - Private Methods
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        var reorderedIds = favoritesManager.favoriteIds
        reorderedIds.move(fromOffsets: source, toOffset: destination)
        favoritesManager.reorderFavorites(reorderedIds)
        HapticManager.shared.impact(.light)
    }
    
    private func deleteItems(at offsets: IndexSet) {
        let idsToRemove = offsets.map { favoriteSounds[$0].id }
        for id in idsToRemove {
            favoritesManager.removeFavorite(id)
        }
        HapticManager.shared.impact(.medium)
    }
}

// MARK: - Favorite Cell

struct FavoriteCell: View {
    let sound: Sound
    let isEditing: Bool
    
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var premiumManager: PremiumManager
    @ObservedObject var favoritesManager = FavoritesManager.shared
    
    @State private var showPremiumAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Reorder handle (only in edit mode)
            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
            }
            
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
                    
                    // Remove button (only in edit mode)
                    if isEditing {
                        Button {
                            removeFavorite()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Category
                Text(sound.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Playing indicator (only when not editing)
            if !isEditing && audioManager.currentSound?.id == sound.id && audioManager.isPlaying {
                playingIndicator
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .onTapGesture {
            if !isEditing {
                playSound()
            }
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
    
    private func removeFavorite() {
        favoritesManager.removeFavorite(sound.id)
        HapticManager.shared.impact(.soft)
    }
}

// MARK: - Favorites Manager Extension

extension FavoritesManager {
    var favoriteIds: [String] {
        Array(favorites)
    }
    
    func reorderFavorites(_ newOrder: [String]) {
        // For now, we'll keep the Set structure but could enhance to maintain order
        favorites = Set(newOrder)
        saveFavorites()
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        FavoritesListView()
            .environmentObject(AudioEngineManager.shared)
            .environmentObject(SoundCatalog())
            .environmentObject(PremiumManager.shared)
    }
}
