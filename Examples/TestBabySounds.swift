import SwiftUI
import AVFoundation

@main
struct TestBabySoundsApp: App {
    var body: some Scene {
        WindowGroup {
            TestContentView()
        }
    }
}

struct TestContentView: View {
    @State private var isPlaying = false
    @State private var currentSound = "White Noise"
    @State private var volume: Double = 0.5
    @State private var timer: Timer?
    
    let sounds = [
        "White Noise",
        "Pink Noise", 
        "Brown Noise",
        "Ocean Waves",
        "Rain",
        "Forest",
        "Womb Sounds",
        "Heartbeat",
        "Fan",
        "Air Conditioner"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("BabySounds")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Soothing sounds for better sleep")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Current Sound Display
                VStack(spacing: 16) {
                    Text("Now Playing")
                        .font(.caption)
                        .textCase(.uppercase)
                        .foregroundColor(.secondary)
                    
                    Text(currentSound)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // Play/Pause Button
                    Button(action: togglePlayPause) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                    }
                    .scaleEffect(isPlaying ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isPlaying)
                }
                
                // Volume Control
                VStack(spacing: 8) {
                    Text("Volume")
                        .font(.caption)
                        .textCase(.uppercase)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.secondary)
                        
                        Slider(value: $volume, in: 0...1)
                            .accentColor(.blue)
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Sound Selection
                VStack(spacing: 12) {
                    Text("Choose Sound")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(sounds, id: \.self) { sound in
                            SoundCard(
                                title: sound,
                                isSelected: sound == currentSound,
                                action: { selectSound(sound) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Footer
                Text("Perfect for babies, toddlers, and adults")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func togglePlayPause() {
        withAnimation {
            isPlaying.toggle()
        }
        
        if isPlaying {
            print("▶️ Playing: \(currentSound)")
            // Simulate audio playback
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                // Audio simulation
            }
        } else {
            print("⏸️ Paused")
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func selectSound(_ sound: String) {
        withAnimation {
            currentSound = sound
        }
        print("🎵 Selected: \(sound)")
        
        if isPlaying {
            // Restart with new sound
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                // Audio simulation
            }
        }
    }
}

struct SoundCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private var icon: String {
        switch title.lowercased() {
        case "white noise", "pink noise", "brown noise":
            return "waveform"
        case "ocean waves":
            return "water.waves"
        case "rain":
            return "cloud.rain.fill"
        case "forest":
            return "tree.fill"
        case "womb sounds":
            return "heart.fill"
        case "heartbeat":
            return "heart.circle.fill"
        case "fan":
            return "fan.fill"
        case "air conditioner":
            return "snowflake"
        default:
            return "speaker.wave.2.fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TestContentView()
} 