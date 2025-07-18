import SwiftUI
import BabySoundsCore

/// Карточка звука для BabySounds
/// 
/// Отображает звук с кнопкой воспроизведения, регулятором громкости
/// и индикатором состояния воспроизведения
public struct SoundCard: View {
    let soundType: SoundType
    let isPlaying: Bool
    let volume: Float
    let onPlayToggle: () -> Void
    let onVolumeChange: (Float) -> Void
    
    public init(
        soundType: SoundType,
        isPlaying: Bool,
        volume: Float,
        onPlayToggle: @escaping () -> Void,
        onVolumeChange: @escaping (Float) -> Void
    ) {
        self.soundType = soundType
        self.isPlaying = isPlaying
        self.volume = volume
        self.onPlayToggle = onPlayToggle
        self.onVolumeChange = onVolumeChange
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header с иконкой и названием
            HStack {
                // Иконка звука
                ZStack {
                    Circle()
                        .fill(soundType.accentColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(soundType.emoji)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(soundType.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(soundType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Индикатор воспроизведения
                if isPlaying {
                    HStack(spacing: 2) {
                        ForEach(0..<3) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(soundType.accentColor)
                                .frame(width: 3, height: 12)
                                .animation(
                                    .easeInOut(duration: 0.5)
                                        .repeatForever()
                                        .delay(Double(index) * 0.1),
                                    value: isPlaying
                                )
                        }
                    }
                }
            }
            
            // Элементы управления
            HStack(spacing: 16) {
                // Кнопка воспроизведения
                Button(action: onPlayToggle) {
                    ZStack {
                        Circle()
                            .fill(isPlaying ? Color.red.opacity(0.1) : soundType.accentColor.opacity(0.1))
                            .frame(width: BabyDesign.minimumTouchTarget, height: BabyDesign.minimumTouchTarget)
                        
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(isPlaying ? .red : soundType.accentColor)
                    }
                }
                .accessibilityLabel(isPlaying ? "Stop \(soundType.displayName)" : "Play \(soundType.displayName)")
                
                // Регулятор громкости
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "speaker.1")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(Int(volume * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { volume },
                            set: onVolumeChange
                        ),
                        in: 0...1
                    )
                    .tint(soundType.accentColor)
                    .disabled(!isPlaying)
                }
            }
        }
        .padding(BabyDesign.padding)
        .background(Color.softGray)
        .cornerRadius(BabyDesign.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: BabyDesign.cornerRadius)
                .strokeBorder(
                    isPlaying ? soundType.accentColor.opacity(0.3) : Color.clear,
                    lineWidth: 2
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
    }
}

// MARK: - SoundType Extensions

extension SoundType {
    /// Эмодзи иконка для звука
    var emoji: String {
        switch self {
        case .whiteNoise: return "🌫️"
        case .pinkNoise: return "🌸"
        case .brownNoise: return "🤎"
        case .rainForest: return "🌳"
        case .oceanWaves: return "🌊"
        case .heartbeat: return "❤️"
        case .wombSounds: return "🤱"
        case .airConditioner: return "❄️"
        case .fan: return "💨"
        case .rain: return "🌧️"
        }
    }
    
    /// Описание звука
    var description: String {
        switch self {
        case .whiteNoise: return "Consistent background noise"
        case .pinkNoise: return "Gentle balanced frequencies"
        case .brownNoise: return "Deep, soothing rumble"
        case .rainForest: return "Nature's peaceful sounds"
        case .oceanWaves: return "Rhythmic water sounds"
        case .heartbeat: return "Familiar maternal rhythm"
        case .wombSounds: return "Comforting womb environment"
        case .airConditioner: return "Steady mechanical hum"
        case .fan: return "Gentle air circulation"
        case .rain: return "Relaxing rainfall"
        }
    }
    
    /// Акцентный цвет для звука
    var accentColor: Color {
        switch self {
        case .whiteNoise, .pinkNoise, .brownNoise: return .purple
        case .rainForest, .rain: return .green
        case .oceanWaves: return .blue
        case .heartbeat, .wombSounds: return .pink
        case .airConditioner, .fan: return .cyan
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SoundCard(
            soundType: .whiteNoise,
            isPlaying: false,
            volume: 0.5,
            onPlayToggle: {},
            onVolumeChange: { _ in }
        )
        
        SoundCard(
            soundType: .oceanWaves,
            isPlaying: true,
            volume: 0.7,
            onPlayToggle: {},
            onVolumeChange: { _ in }
        )
    }
    .padding()
} 