import SwiftUI

struct ContentView: View {
    @State private var isAudioReady = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("🍼")
                        .font(.system(size: 60))
                    
                    Text("Baby Sounds")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Peaceful sleep for your little one")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Main Content
                VStack(spacing: 16) {
                    Button(action: playDemoSound) {
                        Text("Play Sample Sound")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(minHeight: 64)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                    
                    // Audio Status
                    VStack(spacing: 8) {
                        Text("Audio System Status")
                            .font(.headline)
                        
                        HStack {
                            Circle()
                                .fill(isAudioReady ? .green : .red)
                                .frame(width: 8, height: 8)
                            
                            Text(isAudioReady ? "Ready" : "Initializing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                }
                
                Spacer()
                
                // Footer
                VStack(spacing: 4) {
                    Text("BabySounds v1.0.0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Designed for children's safety")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("Baby Sounds")
            .onAppear {
                initializeAudio()
            }
        }
    }
    
    private func playDemoSound() {
        print("🔊 Playing demo sound...")
        // Здесь будет реализация воспроизведения звука
    }
    
    private func initializeAudio() {
        print("🎵 Initializing audio system...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isAudioReady = true
            print("✅ Audio system ready")
        }
    }
}

#Preview {
    ContentView()
} 