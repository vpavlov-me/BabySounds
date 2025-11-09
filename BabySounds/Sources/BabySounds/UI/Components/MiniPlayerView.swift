import AVFoundation
import SwiftUI

// MARK: - MiniPlayerView

struct MiniPlayerView: View {
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var soundCatalog: SoundCatalog

    @State private var progress = 0.0
    @Binding var showNowPlaying: Bool

    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        if let currentSound = audioManager.currentSound {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    .scaleEffect(y: 0.5)

                // Mini player content
                HStack(spacing: 12) {
                    // Artwork
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showNowPlaying = true
                        }
                        HapticManager.shared.impact(.light)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(
                                    colors: currentSound.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))

                            Text(currentSound.displayEmoji)
                                .font(.title2)
                        }
                        .frame(width: 44, height: 44)
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                // iPad pointer interaction - enlarge on hover
                                #if os(iOS)
                                    if hovering {
                                        // Scale effect for iPad pointer
                                    }
                                #endif
                            }
                        }
                    }

                    // Sound info
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showNowPlaying = true
                        }
                        HapticManager.shared.impact(.light)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentSound.titleKey)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text(currentSound.category.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Play/Pause button
                    Button {
                        togglePlayback()
                    } label: {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Rectangle())
            }
            .onReceive(timer) { _ in
                updateProgress()
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showNowPlaying = true
                }
                HapticManager.shared.impact(.light)
            }
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.y < -50 {
                            // Swipe up to open Now Playing
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                showNowPlaying = true
                            }
                            HapticManager.shared.impact(.medium)
                        } else if value.translation.x < -100 {
                            // Swipe left to dismiss (stop)
                            stopPlayback()
                        }
                    }
            )
        }
    }

    // MARK: - Private Methods

    private func togglePlayback() {
        if audioManager.isPlaying {
            audioManager.pauseCurrentSound()
        } else {
            audioManager.resumeCurrentSound()
        }
        HapticManager.shared.impact(.light)
    }

    private func stopPlayback() {
        audioManager.stopAllSounds()
        HapticManager.shared.impact(.medium)
    }

    private func updateProgress() {
        // Update progress based on timer if applicable
        if let timer = audioManager.currentTimer {
            let elapsed = Date().timeIntervalSince(timer.startTime)
            let total = timer.duration
            progress = min(elapsed / total, 1.0)
        } else {
            // For infinite playback, show animated progress
            progress = 0.5 // Static for now, could animate
        }
    }
}

// MARK: - ScaleButtonStyle

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - HapticManager

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
}

// MARK: - Sound Extensions

extension Sound {
    var gradientColors: [Color] {
        switch category {
        case .nature:
            return [.green.opacity(0.8), .blue.opacity(0.6)]

        case .white:
            return [.gray.opacity(0.8), .white]

        case .pink:
            return [.pink.opacity(0.8), .purple.opacity(0.6)]

        case .brown:
            return [.brown.opacity(0.8), .orange.opacity(0.6)]

        case .womb:
            return [.red.opacity(0.6), .pink.opacity(0.8)]

        case .fan:
            return [.blue.opacity(0.6), .cyan.opacity(0.8)]
        }
    }
}
