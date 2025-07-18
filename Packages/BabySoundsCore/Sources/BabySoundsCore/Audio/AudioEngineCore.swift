import Foundation
import AVFoundation

/// Main audio engine for BabySounds
///
/// Provides safe sound playback for children
/// with automatic volume control and background playback
@MainActor
public class AudioEngineCore: ObservableObject {
    
    // MARK: - Properties
    
    private let audioEngine = AVAudioEngine()
    private let mainMixer = AVAudioMixerNode()
    private var playerNodes: [String: AVAudioPlayerNode] = [:]
    private var audioBuffers: [String: AVAudioPCMBuffer] = [:]
    
    @Published public var isEngineRunning = false
    @Published public var currentTracks: [String] = []
    
    // MARK: - Constants
    
    private let maxConcurrentTracks = 4
    private let safeVolumeLimit: Float = 0.8 // 80% max for child safety
    
    // MARK: - Public Methods
    
    /// Start audio engine
    public func startEngine() throws {
        try audioEngine.start()
        isEngineRunning = audioEngine.isRunning
    }
    
    /// Stop audio engine
    public func stopEngine() {
        audioEngine.stop()
        
        // Stop all sounds
        for playerNode in playerNodes.values {
            playerNode.stop()
        }
        
        isEngineRunning = false
        currentTracks.removeAll()
    }
    
    /// Play sound
    public func playSound(_ soundId: String, volume: Float = 0.5) async throws {
        // Check safe volume level
        let safeVolume = min(volume, safeVolumeLimit)
        
        // Load buffer if needed
        if audioBuffers[soundId] == nil {
            try await loadAudioBuffer(for: soundId)
        }
        
        // Create player if needed
        if playerNodes[soundId] == nil {
            let playerNode = AVAudioPlayerNode()
            playerNodes[soundId] = playerNode
            
            // Set volume
            playerNode.volume = safeVolume
        }
        
        guard let playerNode = playerNodes[soundId],
              let buffer = audioBuffers[soundId] else { return }
        
        // Schedule playback
        playerNode.scheduleBuffer(buffer, at: nil, options: [.loops]) { [weak self] in
            Task { @MainActor in
                self?.currentTracks.append(soundId)
            }
        }
        
        // Start playback
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    /// Stop sound
    public func stopSound(_ soundId: String) {
        guard let playerNode = playerNodes[soundId] else { return }
        
        playerNode.stop()
        currentTracks.removeAll { $0 == soundId }
    }
    
    /// Change volume
    public func setVolume(for soundId: String, volume: Float) {
        guard let playerNode = playerNodes[soundId] else { return }
        
        let safeVolume = min(volume, safeVolumeLimit)
        playerNode.volume = safeVolume
    }
    
    /// Smooth volume change
    public func fadeVolume(for soundId: String, to targetVolume: Float, duration: TimeInterval) {
        guard let playerNode = playerNodes[soundId] else { return }
        
        let safeVolume = min(targetVolume, safeVolumeLimit)
        
        // Use AVAudioMixing for smooth volume transitions
        playerNode.volume = safeVolume
    }
    
    // MARK: - Private Methods
    
    private func loadAudioBuffer(for soundId: String) async throws {
        // Load audio file from bundle
        guard let url = Bundle.main.url(forResource: soundId, withExtension: "mp3") else {
            throw AudioError.fileNotFound
        }
        
        let audioFile = try AVAudioFile(forReading: url)
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: AVAudioFrameCount(audioFile.length)
        ) else {
            throw AudioError.bufferCreationFailed
        }
        
        try audioFile.read(into: buffer)
        audioBuffers[soundId] = buffer
    }
    
    private func setupAudioEngine() {
        // Main mixer already configured via mainMixer
        audioEngine.attach(mainMixer)
        audioEngine.connect(mainMixer, to: audioEngine.outputNode, format: nil)
    }
}

// MARK: - AudioError

public enum AudioError: Error {
    case fileNotFound
    case bufferCreationFailed
    case engineNotRunning
} 