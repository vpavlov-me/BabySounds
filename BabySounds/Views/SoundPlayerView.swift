import SwiftUI

struct SoundPlayerView: View {
    let sound: Sound
    
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    @EnvironmentObject var soundCatalog: SoundCatalog
    @EnvironmentObject var premiumManager: PremiumManager
    
    @State private var selectedTimerMinutes = 0 // 0 = infinite
    @State private var showPaywall = false
    @State private var fadeOutEnabled = true
    
    private let timerOptions = [0, 15, 30, 45, 60, 90, 120] // 0 = infinite
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 20)
                    
                    // Sound Card
                    VStack(spacing: 24) {
                        // Sound Emoji/Icon
                        Text(sound.displayEmoji)
                            .font(.system(size: 120))
                        
                        // Sound Title
                        Text(sound.titleKey)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        // Premium Badge
                        if sound.premium {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.orange)
                                Text("Premium")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(sound.color.color.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(sound.color.color.opacity(0.3), lineWidth: 2)
                            )
                    )
                    .padding(.horizontal)
                    
                    // Play Controls
                    VStack(spacing: 24) {
                        // Play/Pause Button
                        Button(action: togglePlayback) {
                            HStack(spacing: 12) {
                                Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title2)
                                Text(audioManager.isPlaying ? "Pause" : "Play")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(sound.color.color)
                            )
                        }
                        .disabled(sound.premium && !premiumManager.canPlayPremiumSound())
                        .opacity(sound.premium && !premiumManager.canPlayPremiumSound() ? 0.6 : 1.0)
                        
                        // Premium Unlock Message
                        if sound.premium && !premiumManager.canPlayPremiumSound() {
                            Button("Unlock Premium to Play") {
                                premiumManager.requestAccess(to: .premiumSounds)
                            }
                            .foregroundColor(.orange)
                            .font(.headline)
                        }
                    }
                    .padding(.horizontal)
                    
                    if subscriptionService.isPremium || !sound.premium {
                        // Volume Control
                        VStack(spacing: 16) {
                            HStack {
                                Text("Volume")
                                    .font(.headline)
                                Spacer()
                                Text("\(Int(audioManager.currentVolume * 100))%")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 16) {
                                Image(systemName: "speaker.fill")
                                    .foregroundColor(.secondary)
                                
                                Slider(
                                    value: Binding(
                                        get: { audioManager.currentVolume },
                                        set: { audioManager.setVolume($0) }
                                    ),
                                    in: 0...1
                                )
                                .accentColor(sound.color.color)
                                
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                        
                        // Timer Control
                        VStack(spacing: 16) {
                            HStack {
                                Text("Sleep Timer")
                                    .font(.headline)
                                Spacer()
                                if audioManager.timerRemaining > 0 {
                                    Text(formatTime(audioManager.timerRemaining))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(timerOptions, id: \.self) { minutes in
                                        TimerButton(
                                            minutes: minutes,
                                            isSelected: selectedTimerMinutes == minutes,
                                            color: sound.color.color
                                        ) {
                                            selectTimer(minutes)
                                        }
                                        .disabled(minutes > 30 && !subscriptionService.isPremium)
                                        .opacity(minutes > 30 && !subscriptionService.isPremium ? 0.5 : 1.0)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Fade Out Toggle
                            Toggle("Fade out when timer ends", isOn: $fadeOutEnabled)
                                .font(.subheadline)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .gray)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall)
        }
        .premiumGateAlert(premiumManager: premiumManager, showPaywall: $showPaywall)
        .onDisappear {
            if audioManager.isPlaying {
                audioManager.stopSound()
            }
        }
    }
    
    private var isFavorite: Bool {
        soundCatalog.favorites.contains(sound.id)
    }
    
    private func togglePlayback() {
        if sound.premium && !premiumManager.canPlayPremiumSound() {
            premiumManager.requestAccess(to: .premiumSounds)
            return
        }
        
        if audioManager.isPlaying {
            audioManager.stopSound(fadeOut: fadeOutEnabled)
        } else {
            audioManager.playSound(sound, loop: sound.loop)
            if selectedTimerMinutes > 0 {
                audioManager.setTimer(minutes: selectedTimerMinutes)
            }
        }
    }
    
    private func selectTimer(_ minutes: Int) {
        if !premiumManager.canSetTimer(minutes: minutes) {
            premiumManager.requestAccess(to: .extendedTimer)
            return
        }
        
        selectedTimerMinutes = minutes
        
        if audioManager.isPlaying && minutes > 0 {
            audioManager.setTimer(minutes: minutes)
        }
    }
    
    private func toggleFavorite() {
        if isFavorite {
            soundCatalog.favorites.remove(sound.id)
        } else {
            // Check if user can add more favorites
            if !premiumManager.canAddFavorite(currentCount: soundCatalog.favorites.count) {
                premiumManager.requestAccess(to: .unlimitedFavorites)
                return
            }
            soundCatalog.favorites.insert(sound.id)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct TimerButton: View {
    let minutes: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(timerText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? color : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var timerText: String {
        if minutes == 0 {
            return "∞"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            return "\(hours)h"
        }
    }
}

#Preview {
    NavigationView {
        SoundPlayerView(
            sound: Sound(
                titleKey: "White Noise",
                category: .white,
                fileName: "white_noise",
                color: .gray,
                emoji: "🌬️"
            )
        )
    }
    .environmentObject(AudioEngineManager.shared)
    .environmentObject(SubscriptionServiceSK2())
    .environmentObject(SoundCatalog())
} 