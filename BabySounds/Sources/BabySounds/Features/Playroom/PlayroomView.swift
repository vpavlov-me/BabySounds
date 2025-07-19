import SwiftUI

// MARK: - Playroom View

struct PlayroomView: View {
    @EnvironmentObject var soundCatalog: SoundCatalog
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var parentGateManager: ParentGateManager
    
    @State private var showNowPlaying = false
    @State private var showParentGate = false
    @State private var pendingAction: (() -> Void)?
    @AppStorage("hasPassedParentGate") private var hasPassedParentGate = false
    @AppStorage("parentGateTimeout") private var parentGateTimeout: Double = 0
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background
                LinearGradient(
                    colors: [.purple.opacity(0.1), .pink.opacity(0.1), .orange.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Sound tiles grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(playroomSounds, id: \.id) { sound in
                                PlayroomTile(sound: sound)
                                    .onTapGesture {
                                        requireParentGate {
                                            playSound(sound)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Bottom spacing for mini player
                        Spacer()
                            .frame(height: 100)
                    }
                }
                .refreshable {
                    await refreshContent()
                }
                
                // Mini Player
                MiniPlayerView(showNowPlaying: $showNowPlaying)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true) // Hide navigation for full immersion
        .sheet(isPresented: $showParentGate) {
            ParentGateView(
                isPresented: $showParentGate,
                context: .playroom,
                onSuccess: {
                    hasPassedParentGate = true
                    parentGateTimeout = Date().timeIntervalSince1970 + 300 // 5 minutes
                    pendingAction?()
                    pendingAction = nil
                }
            )
        }
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView(isPresented: $showNowPlaying)
        }
        .onAppear {
            setupPlayroom()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Welcome message
            VStack(spacing: 8) {
                Text("🎪")
                    .font(.system(size: 60))
                
                Text("Playroom")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Fun sounds for little ones")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // Exit button (requires parent gate)
            Button {
                requireParentGate {
                    exitPlayroom()
                }
            } label: {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .font(.title3)
                    Text("Parents: Tap to Exit")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .foregroundColor(.primary)
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // MARK: - Computed Properties
    
    private var playroomSounds: [Sound] {
        // Filter sounds suitable for playroom (fun, engaging sounds)
        soundCatalog.allSounds.filter { sound in
            // Include nature sounds, fun sounds, but not purely therapeutic ones
            switch sound.category {
            case .nature, .womb:
                return true
            case .white, .pink, .brown, .fan:
                return false // These are more for sleep
            case .all:
                return false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func requireParentGate(action: @escaping () -> Void) {
        if isParentGateValid() {
            action()
        } else {
            pendingAction = action
            showParentGate = true
        }
    }
    
    private func isParentGateValid() -> Bool {
        hasPassedParentGate && Date().timeIntervalSince1970 < parentGateTimeout
    }
    
    private func playSound(_ sound: Sound) {
        if sound.premium && !premiumManager.isPremium {
            // Show premium alert with child-friendly messaging
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
    
    private func exitPlayroom() {
        // Handle exit logic - could navigate back or show different view
        HapticManager.shared.notification(.success)
    }
    
    private func setupPlayroom() {
        // Setup any needed configurations for playroom
    }
    
    private func refreshContent() async {
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await soundCatalog.loadSounds()
        HapticManager.shared.impact(.light)
    }
}

// MARK: - Playroom Tile

struct PlayroomTile: View {
    let sound: Sound
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var premiumManager: PremiumManager
    
    @State private var isPressed = false
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: sound.gradientColors + [sound.gradientColors.first?.opacity(0.3) ?? .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            
            // Content
            VStack(spacing: 16) {
                // Large emoji/icon
                Text(sound.displayEmoji)
                    .font(.system(size: 64))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Title
                Text(sound.titleKey)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                // Premium indicator
                if sound.premium && !premiumManager.isPremium {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        Text("Premium")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                }
                
                // Playing indicator
                if audioManager.currentSound?.id == sound.id && audioManager.isPlaying {
                    playingIndicator
                }
            }
            .padding(20)
        }
        .frame(width: 160, height: 160)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: { }
        .onAppear {
            // Start animation for visual appeal
            withAnimation(.easeInOut(duration: 0.6).delay(Double.random(in: 0...2))) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Playing Indicator
    
    private var playingIndicator: some View {
        HStack(spacing: 3) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white)
                    .frame(width: 4, height: CGFloat.random(in: 12...20))
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever()
                        .delay(Double(index) * 0.1),
                        value: audioManager.isPlaying
                    )
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
        }
        .frame(width: 24, height: 24)
        .background(
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 32, height: 32)
        )
    }
}

// MARK: - Parent Gate Context Extension

extension ParentGateContext {
    static let playroom = ParentGateContext.custom("playroom")
}

// MARK: - Preview

#Preview {
    PlayroomView()
        .environmentObject(AudioEngineManager.shared)
        .environmentObject(SoundCatalog())
        .environmentObject(PremiumManager.shared)
        .environmentObject(ParentGateManager.shared)
} 