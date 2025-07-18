import Foundation
import AVFoundation

/// Основной аудио движок для BabySounds
/// 
/// Обеспечивает безопасное воспроизведение звуков для детей
/// с автоматическим контролем громкости и фоновым воспроизведением
@MainActor
public class AudioEngineCore: ObservableObject {
    
    // MARK: - Properties
    
    private let engine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode
    private var players: [SoundType: AVAudioPlayerNode] = [:]
    private var buffers: [SoundType: AVAudioPCMBuffer] = [:]
    
    @Published public var isEngineRunning = false
    @Published public var currentlyPlaying: Set<SoundType> = []
    @Published public var volumes: [SoundType: Float] = [:]
    
    // MARK: - Initialization
    
    public init() {
        self.mainMixer = engine.mainMixerNode
        setupAudioSession()
        setupEngine()
    }
    
    deinit {
        stopEngine()
    }
    
    // MARK: - Public API
    
    /// Запуск аудио движка
    public func startEngine() async throws {
        guard !engine.isRunning else { return }
        
        try engine.start()
        isEngineRunning = true
        
        print("✅ AudioEngineCore: Engine started successfully")
    }
    
    /// Остановка аудио движка
    public func stopEngine() {
        guard engine.isRunning else { return }
        
        // Останавливаем все звуки
        for soundType in currentlyPlaying {
            stopSound(soundType)
        }
        
        engine.stop()
        isEngineRunning = false
        
        print("🛑 AudioEngineCore: Engine stopped")
    }
    
    /// Воспроизведение звука
    public func playSound(_ soundType: SoundType, volume: Float = 0.5, loop: Bool = true) async -> AudioResult {
        // Проверяем безопасный уровень громкости
        let safeVolume = min(volume, AppConstants.safeVolumeLimit)
        
        // Загружаем буфер если нужно
        await loadBufferIfNeeded(for: soundType)
        
        guard let buffer = buffers[soundType] else {
            return .failure(.fileNotFound(soundType.filename))
        }
        
        // Создаем плеер если нужно
        let player = getOrCreatePlayer(for: soundType)
        
        // Настраиваем громкость
        player.volume = safeVolume
        volumes[soundType] = safeVolume
        
        // Планируем воспроизведение
        if loop {
            player.scheduleBuffer(buffer, at: nil, options: [.loops])
        } else {
            player.scheduleBuffer(buffer, at: nil)
        }
        
        // Запускаем воспроизведение
        player.play()
        currentlyPlaying.insert(soundType)
        
        print("🔊 AudioEngineCore: Playing \(soundType.displayName) at volume \(safeVolume)")
        
        return .success
    }
    
    /// Остановка звука
    public func stopSound(_ soundType: SoundType) {
        guard let player = players[soundType] else { return }
        
        player.stop()
        currentlyPlaying.remove(soundType)
        volumes.removeValue(forKey: soundType)
        
        print("⏹️ AudioEngineCore: Stopped \(soundType.displayName)")
    }
    
    /// Изменение громкости
    public func setVolume(_ volume: Float, for soundType: SoundType) {
        let safeVolume = min(volume, AppConstants.safeVolumeLimit)
        
        guard let player = players[soundType] else { return }
        
        player.volume = safeVolume
        volumes[soundType] = safeVolume
        
        print("🔈 AudioEngineCore: Set volume for \(soundType.displayName) to \(safeVolume)")
    }
    
    /// Плавное изменение громкости
    public func fadeVolume(for soundType: SoundType, to targetVolume: Float, duration: TimeInterval = 1.0) {
        let safeTargetVolume = min(targetVolume, AppConstants.safeVolumeLimit)
        
        guard let player = players[soundType] else { return }
        
        let currentVolume = player.volume
        let steps = 50
        let volumeStep = (safeTargetVolume - currentVolume) / Float(steps)
        let timeStep = duration / Double(steps)
        
        var step = 0
        
        Timer.scheduledTimer(withTimeInterval: timeStep, repeats: true) { timer in
            step += 1
            
            let newVolume = currentVolume + (volumeStep * Float(step))
            player.volume = newVolume
            
            if step >= steps {
                timer.invalidate()
                self.volumes[soundType] = safeTargetVolume
                print("🎵 AudioEngineCore: Fade complete for \(soundType.displayName)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            
            print("🎵 AudioEngineCore: Audio session configured")
        } catch {
            print("❌ AudioEngineCore: Failed to setup audio session: \(error)")
        }
    }
    
    private func setupEngine() {
        // Основной микшер уже настроен через mainMixer
        print("🔧 AudioEngineCore: Engine setup complete")
    }
    
    private func getOrCreatePlayer(for soundType: SoundType) -> AVAudioPlayerNode {
        if let existingPlayer = players[soundType] {
            return existingPlayer
        }
        
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: mainMixer, format: nil)
        
        players[soundType] = player
        
        print("🎮 AudioEngineCore: Created player for \(soundType.displayName)")
        
        return player
    }
    
    private func loadBufferIfNeeded(for soundType: SoundType) async {
        guard buffers[soundType] == nil else { return }
        
        await loadAudioBuffer(for: soundType)
    }
    
    private func loadAudioBuffer(for soundType: SoundType) async {
        guard let url = Bundle.main.url(forResource: soundType.rawValue, withExtension: "mp3") else {
            print("❌ AudioEngineCore: File not found: \(soundType.filename)")
            return
        }
        
        do {
            let file = try AVAudioFile(forReading: url)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
                print("❌ AudioEngineCore: Failed to create buffer for \(soundType.filename)")
                return
            }
            
            try file.read(into: buffer)
            buffers[soundType] = buffer
            
            print("📂 AudioEngineCore: Loaded buffer for \(soundType.displayName)")
        } catch {
            print("❌ AudioEngineCore: Failed to load \(soundType.filename): \(error)")
        }
    }
} 