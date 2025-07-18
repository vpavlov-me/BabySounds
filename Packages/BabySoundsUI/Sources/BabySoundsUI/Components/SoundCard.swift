import SwiftUI

/// Sound card for BabySounds
///
/// Displays a sound with play button, volume control
/// and playback status indicator
public struct SoundCard: View {
    // MARK: - Properties
    
    let title: String
    let isPlaying: Bool
    let volume: Double
    let onPlayToggle: () -> Void
    let onVolumeChange: (Double) -> Void
    
    // MARK: - Initialization
    
    public init(
        title: String,
        isPlaying: Bool = false,
        volume: Double = 0.5,
        onPlayToggle: @escaping () -> Void,
        onVolumeChange: @escaping (Double) -> Void
    ) {
        self.title = title
        self.isPlaying = isPlaying
        self.volume = volume
        self.onPlayToggle = onPlayToggle
        self.onVolumeChange = onVolumeChange
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header with icon and title
            HStack {
                // Sound icon
                Image(systemName: soundIcon)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.babyBlue.opacity(0.3))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Playback indicator
                Circle()
                    .fill(isPlaying ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .scaleEffect(isPlaying ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isPlaying)
            }
            
            // Controls
            VStack(spacing: 8) {
                // Play button
                Button(action: onPlayToggle) {
                    HStack {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                        Text(isPlaying ? "Pause" : "Play")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(isPlaying ? Color.orange : Color.blue)
                    .cornerRadius(12)
                }
                .accessibilityLabel(isPlaying ? "Pause \(title)" : "Play \(title)")
                
                // Volume control
                if isPlaying {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Volume")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(volume * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: Binding(
                            get: { volume },
                            set: { onVolumeChange($0) }
                        ), in: 0...1)
                        .tint(.blue)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .padding()
        .background(Color.softGray)
        .cornerRadius(16)
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Private Computed Properties
    
    private var soundIcon: String {
        // Different icons for different sound types
        if title.lowercased().contains("white") {
            return "waveform"
        } else if title.lowercased().contains("rain") {
            return "cloud.rain"
        } else if title.lowercased().contains("ocean") {
            return "water.waves"
        } else if title.lowercased().contains("forest") {
            return "tree"
        } else {
            return "music.note"
        }
    }
    
    private var statusText: String {
        isPlaying ? "Playing" : "Stopped"
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SoundCard(
            title: "White Noise",
            isPlaying: false,
            volume: 0.5,
            onPlayToggle: {},
            onVolumeChange: { _ in }
        )
        
        SoundCard(
            title: "Rain Sounds",
            isPlaying: true,
            volume: 0.7,
            onPlayToggle: {},
            onVolumeChange: { _ in }
        )
    }
    .padding()
} 