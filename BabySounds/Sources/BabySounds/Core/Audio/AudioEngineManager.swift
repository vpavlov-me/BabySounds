import Foundation
import AVFoundation
import MediaPlayer
import SwiftUI

// MARK: - Track Handle

/// Represents a playing audio track with its associated controls
public struct TrackHandle: Identifiable, Hashable {
    public let id: UUID
    public let soundId: UUID
    public let startTime: Date
    
    public init(id: UUID = UUID(), soundId: UUID, startTime: Date = Date()) {
        self.id = id
        self.soundId = soundId
        self.startTime = startTime
    }
}

// MARK: - Playing Info

/// Information about currently playing tracks
public struct PlayingInfo: Identifiable {
    public let id: UUID
    public let soundId: UUID
    public let sound: Sound
    public let startTime: Date
    public let isLooping: Bool
    public let gainDb: Float
    public let pan: Float
    
    public init(
        id: UUID,
        soundId: UUID,
        sound: Sound,
        startTime: Date,
        isLooping: Bool,
        gainDb: Float,
        pan: Float
    ) {
        self.id = id
        self.soundId = soundId
        self.sound = sound
        self.startTime = startTime
        self.isLooping = isLooping
        self.gainDb = gainDb
        self.pan = pan
    }
}

// MARK: - Audio Track

/// Internal representation of an audio track
private class AudioTrack {
    let id: UUID
    let sound: Sound
    let playerNode: AVAudioPlayerNode
    let audioFile: AVAudioFile
    let isLooping: Bool
    let gainDb: Float
    let pan: Float
    let startTime: Date
    
    var isScheduled = false
    var isLocked = false // For mix tracks that shouldn't be auto-removed
    
    init(
        id: UUID,
        sound: Sound,
        playerNode: AVAudioPlayerNode,
        audioFile: AVAudioFile,
        isLooping: Bool,
        gainDb: Float,
        pan: Float
    ) {
        self.id = id
        self.sound = sound
        self.playerNode = playerNode
        self.audioFile = audioFile
        self.isLooping = isLooping
        self.gainDb = gainDb
        self.pan = pan
        self.startTime = Date()
    }
}

// MARK: - Audio Engine Manager

/// Main audio engine manager using AVAudioEngine for high-quality multi-track playback
@MainActor
public final class AudioEngineManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = AudioEngineManager()
    
    // MARK: - Properties
    
    private let engine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode
    
    /// Maximum concurrent tracks (prevents resource exhaustion)
    private let maxConcurrentTracks = 4
    
    /// Currently playing tracks
    private var tracks: [UUID: AudioTrack] = [:]
    
    /// Preloaded audio files cache
    private var audioFileCache: [String: AVAudioFile] = [:]
    
    /// Scheduled stop tasks
    private var scheduledStops: [UUID: Task<Void, Never>] = [:]
    
    /// Safe volume manager integration
    private let safeVolumeManager = SafeVolumeManager.shared
    
    /// Currently playing tracks info
    @Published public private(set) var currentlyPlaying: [UUID: PlayingInfo] = [:]
    
    /// Engine state
    @Published public private(set) var isEngineRunning = false
    
    // MARK: - Initialization
    
    private init() {
        mainMixer = engine.mainMixerNode
        setupEngine()
        setupSafeVolumeIntegration()
    }
    
    // MARK: - Engine Setup
    
    /// Configure the audio engine with optimal settings for baby sounds
    private func setupEngine() {
        
        // Configure main mixer for stereo output
        let outputFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        guard let format = outputFormat else {
            print("AudioEngineManager: Failed to create output format")
            return
        }
        
        // Set mixer output format
        engine.connect(mainMixer, to: engine.outputNode, format: format)
        
        // Start engine
        startEngine()
    }
    
    /// Setup safe volume integration
    private func setupSafeVolumeIntegration() {
        // Listen for safety notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChangedForSafety),
            name: .audioRouteChangedForSafety,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleVolumeWarning),
            name: .volumeWarningTriggered,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBreakRecommendation),
            name: .breakRecommendationTriggered,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMaxListeningTimeReached),
            name: .maxListeningTimeReached,
            object: nil
        )
    }
    
    /// Start the audio engine
    private func startEngine() {
        guard !engine.isRunning else { return }
        
        do {
            try engine.start()
            isEngineRunning = true
            print("AudioEngineManager: Engine started successfully")
        } catch {
            print("AudioEngineManager: Failed to start engine: \(error)")
            isEngineRunning = false
        }
    }
    
    /// Stop the audio engine
    private func stopEngine() {
        guard engine.isRunning else { return }
        
        engine.stop()
        isEngineRunning = false
        print("AudioEngineManager: Engine stopped")
    }
    
    // MARK: - Audio File Loading
    
    /// Preload a sound file into memory for fast playback
    public func preload(sound: Sound) async throws {
        
        let cacheKey = "\(sound.fileName).\(sound.fileExt)"
        
        // Check if already cached
        if audioFileCache[cacheKey] != nil {
            return
        }
        
        // Load from bundle
        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExt) else {
            throw AudioEngineError.fileNotFound(sound.fileName)
        }
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            audioFileCache[cacheKey] = audioFile
            print("AudioEngineManager: Preloaded \(sound.fileName)")
        } catch {
            throw AudioEngineError.fileLoadError(error)
        }
    }
    
    /// Get cached audio file or load it
    private func getAudioFile(for sound: Sound) throws -> AVAudioFile {
        let cacheKey = "\(sound.fileName).\(sound.fileExt)"
        
        if let cachedFile = audioFileCache[cacheKey] {
            return cachedFile
        }
        
        // Load synchronously if not cached
        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExt) else {
            throw AudioEngineError.fileNotFound(sound.fileName)
        }
        
        let audioFile = try AVAudioFile(forReading: url)
        audioFileCache[cacheKey] = audioFile
        return audioFile
    }
    
    // MARK: - Playback Control
    
    /// Play a sound with specified parameters
    public func play(
        sound: Sound,
        loop: Bool = true,
        gainDb: Float? = nil,
        pan: Float = 0.0
    ) async throws -> TrackHandle {
        
        // Ensure engine is running
        if !engine.isRunning {
            startEngine()
        }
        
        // Load audio file
        let audioFile = try getAudioFile(for: sound)
        
        // Create player node
        let playerNode = AVAudioPlayerNode()
        
        // Calculate gain with safe volume integration
        let finalGain = gainDb ?? sound.defaultGainDb
        let linearVolume = convertFromDb(finalGain)
        let safeLinearVolume = safeVolumeManager.applySafeVolume(to: linearVolume)
        let safeGain = convertToDb(safeLinearVolume)
        
        // Create track
        let trackHandle = TrackHandle(soundId: sound.id)
        let track = AudioTrack(
            id: trackHandle.id,
            sound: sound,
            playerNode: playerNode,
            audioFile: audioFile,
            isLooping: loop,
            gainDb: safeGain,
            pan: pan
        )
        
        // Check track limit and remove oldest if needed
        if tracks.count >= maxConcurrentTracks {
            removeOldestUnlockedTrack()
        }
        
        // Add to engine and tracks
        engine.attach(playerNode)
        tracks[trackHandle.id] = track
        
        // Configure audio processing chain
        try setupAudioChain(for: track)
        
        // Schedule audio playback
        scheduleAudio(for: track)
        
        // Start playback
        playerNode.play()
        
        // Start listening session if this is the first track
        if tracks.count == 1 {
            safeVolumeManager.startListeningSession()
        }
        
        // Update published state
        updateCurrentlyPlaying()
        
        print("AudioEngineManager: Started playing \(sound.fileName) (loop: \(loop))")
        
        return trackHandle
    }
    
    /// Stop a specific track with optional fade-out
    public func stop(id: UUID, fade: TimeInterval? = nil) {
        
        guard let track = tracks[id] else {
            print("AudioEngineManager: Track \(id) not found for stopping")
            return
        }
        
        if let fadeTime = fade, fadeTime > 0 {
            // Fade out gradually
            fadeOutTrack(track, duration: fadeTime) { [weak self] in
                self?.removeTrack(id)
            }
        } else {
            // Stop immediately
            removeTrack(id)
        }
    }
    
    /// Stop all currently playing tracks
    public func stopAll(fade: TimeInterval? = nil) {
        let trackIds = Array(tracks.keys)
        
        for trackId in trackIds {
            stop(id: trackId, fade: fade)
        }
        
        // End listening session when all tracks stop
        if !trackIds.isEmpty {
            safeVolumeManager.endListeningSession()
        }
    }
    
    /// Schedule a track to stop at a specific date
    public func scheduleStop(at date: Date) {
        let delay = date.timeIntervalSinceNow
        guard delay > 0 else {
            stopAll(fade: 2.0) // Immediate fade-out if date is in the past
            return
        }
        
        scheduleStop(after: delay)
    }
    
    /// Schedule a track to stop after a specific duration
    public func scheduleStop(after seconds: TimeInterval) {
        guard seconds > 0 else { return }
        
        // Cancel any existing scheduled stop
        cancelScheduledStops()
        
        let task = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                await self?.stopAll(fade: 2.0)
            } catch {
                // Task was cancelled
            }
        }
        
        scheduledStops[UUID()] = task
        print("AudioEngineManager: Scheduled stop in \(seconds) seconds")
    }
    
    /// Cancel all scheduled stops
    public func cancelScheduledStops() {
        for task in scheduledStops.values {
            task.cancel()
        }
        scheduledStops.removeAll()
    }
    
    // MARK: - Volume Control
    
    /// Set safe volume level (0.0 to 1.0)
    public func setSafeVolumeLevel(_ level: Float) {
        safeVolumeLevel = max(0.0, min(1.0, level))
        
        // Update all playing tracks
        for track in tracks.values {
            updateTrackVolume(track)
        }
    }
    
    /// Enable or disable safe volume
    public func setSafeVolumeEnabled(_ enabled: Bool) {
        safeVolumeEnabled = enabled
        
        // Update all playing tracks
        for track in tracks.values {
            updateTrackVolume(track)
        }
    }
    
    // MARK: - Private Implementation
    
    /// Setup audio processing chain for a track
    private func setupAudioChain(for track: AudioTrack) throws {
        let audioFile = track.audioFile
        let playerNode = track.playerNode
        
        // Create format for connections
        let format = audioFile.processingFormat
        
        // Connect player to main mixer with volume and pan controls
        engine.connect(
            playerNode,
            to: mainMixer,
            format: format
        )
        
        // Apply initial volume and pan
        updateTrackVolume(track)
        updateTrackPan(track)
    }
    
    /// Schedule audio buffer for playback
    private func scheduleAudio(for track: AudioTrack) {
        let audioFile = track.audioFile
        let playerNode = track.playerNode
        
        guard let buffer = createBuffer(from: audioFile) else {
            print("AudioEngineManager: Failed to create buffer for \(track.sound.fileName)")
            return
        }
        
        if track.isLooping {
            // Schedule buffer with looping
            playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        } else {
            // Schedule buffer once with completion handler
            playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
                DispatchQueue.main.async {
                    self?.removeTrack(track.id)
                }
            })
        }
        
        track.isScheduled = true
    }
    
    /// Create audio buffer from file
    private func createBuffer(from audioFile: AVAudioFile) -> AVAudioPCMBuffer? {
        let frameCount = UInt32(audioFile.length)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: frameCount
        ) else {
            return nil
        }
        
        do {
            try audioFile.read(into: buffer)
            return buffer
        } catch {
            print("AudioEngineManager: Failed to read audio file into buffer: \(error)")
            return nil
        }
    }
    
    /// Update track volume based on gain and safe volume settings
    private func updateTrackVolume(_ track: AudioTrack) {
        let linearGain = convertFromDb(track.gainDb)
        let safeMultiplier = safeVolumeEnabled ? safeVolumeLevel : 1.0
        let finalVolume = linearGain * safeMultiplier
        
        track.playerNode.volume = finalVolume
    }
    
    /// Update track pan (-1.0 to 1.0)
    private func updateTrackPan(_ track: AudioTrack) {
        track.playerNode.pan = track.pan
    }
    
    /// Fade out a track over specified duration
    private func fadeOutTrack(_ track: AudioTrack, duration: TimeInterval, completion: @escaping () -> Void) {
        let playerNode = track.playerNode
        let startVolume = playerNode.volume
        let steps = 20
        let stepDuration = duration / Double(steps)
        
        var currentStep = 0
        
        let timer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            let newVolume = startVolume * (1.0 - progress)
            
            playerNode.volume = newVolume
            
            if currentStep >= steps {
                timer.invalidate()
                completion()
            }
        }
        
        timer.fire()
    }
    
    /// Remove oldest unlocked track to make room for new tracks
    private func removeOldestUnlockedTrack() {
        let unlockedTracks = tracks.values.filter { !$0.isLocked }
        guard let oldestTrack = unlockedTracks.min(by: { $0.startTime < $1.startTime }) else {
            return
        }
        
        removeTrack(oldestTrack.id)
        print("AudioEngineManager: Removed oldest track to make room")
    }
    
    /// Remove a track from the engine
    private func removeTrack(_ trackId: UUID) {
        guard let track = tracks[trackId] else { return }
        
        // Stop and detach player node
        track.playerNode.stop()
        engine.detach(track.playerNode)
        
        // Remove from tracks
        tracks.removeValue(forKey: trackId)
        
        // Update published state
        updateCurrentlyPlaying()
        
        print("AudioEngineManager: Removed track \(track.sound.fileName)")
    }
    
    /// Update the published currently playing state
    private func updateCurrentlyPlaying() {
        currentlyPlaying = tracks.mapValues { track in
            PlayingInfo(
                id: track.id,
                soundId: track.sound.id,
                sound: track.sound,
                startTime: track.startTime,
                isLooping: track.isLooping,
                gainDb: track.gainDb,
                pan: track.pan
            )
        }
        
        // Update Now Playing Info when tracks change (defined in BackgroundAudioManager.swift)
        DispatchQueue.main.async { [weak self] in
            self?.updateNowPlayingInfo()
        }
    }
    
    /// Stub method - actual implementation in BackgroundAudioManager.swift extension
    private func updateNowPlayingInfo() {
        // Will be overridden by extension
    }
    
    // MARK: - Utility Functions
    
    /// Convert linear gain (0.0-1.0) to decibels
    private func convertToDb(_ linear: Float) -> Float {
        guard linear > 0 else { return -80.0 } // Silence
        return 20.0 * log10(linear)
    }
    
    /// Convert decibels to linear gain (0.0-1.0)
    private func convertFromDb(_ db: Float) -> Float {
        guard db > -80.0 else { return 0.0 } // Silence
        return pow(10.0, db / 20.0)
    }
}

// MARK: - Audio Engine Errors

public enum AudioEngineError: Error, LocalizedError {
    case fileNotFound(String)
    case fileLoadError(Error)
    case engineNotRunning
    case trackNotFound(UUID)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let fileName):
            return "Audio file not found: \(fileName)"
        case .fileLoadError(let error):
            return "Failed to load audio file: \(error.localizedDescription)"
        case .engineNotRunning:
            return "Audio engine is not running"
        case .trackNotFound(let id):
            return "Audio track not found: \(id)"
        }
    }
    
    // MARK: - Safe Volume Notification Handlers
    
    @objc private func handleAudioRouteChangedForSafety() {
        // Pause all audio when headphones are unplugged for safety
        stopAll(fade: 0.5)
        safeVolumeManager.endListeningSession()
        
        print("[AudioEngineManager] Audio paused due to route change for safety")
    }
    
    @objc private func handleVolumeWarning(notification: Notification) {
        guard let volume = notification.userInfo?["volume"] as? Float,
              let level = notification.userInfo?["level"] as? SafeVolumeManager.VolumeWarningLevel else {
            return
        }
        
        print("[AudioEngineManager] Volume warning: \(volume) at level \(level)")
        
        // Optionally reduce volume automatically for high warning levels
        if level == .danger {
            // Auto-reduce to safe level
            let safeVolume = SafeVolumeManager.SafetyLimits.maxChildSafeVolume
            updateAllTracksVolume(to: safeVolume)
        }
    }
    
    @objc private func handleBreakRecommendation(notification: Notification) {
        guard let duration = notification.userInfo?["duration"] as? TimeInterval else {
            return
        }
        
        print("[AudioEngineManager] Break recommendation after \(duration) seconds")
        
        // Gradually fade volume to encourage break
        fadeAllTracks(to: 0.3, duration: 10.0)
    }
    
    @objc private func handleMaxListeningTimeReached(notification: Notification) {
        guard let duration = notification.userInfo?["duration"] as? TimeInterval else {
            return
        }
        
        print("[AudioEngineManager] Maximum listening time reached: \(duration) seconds")
        
        // Auto-pause after maximum listening time
        stopAll(fade: 2.0)
        safeVolumeManager.endListeningSession()
    }
    
    // MARK: - Safe Volume Helpers
    
    private func updateAllTracksVolume(to volume: Float) {
        for track in tracks.values {
            // Update track volume through mixer node
            if let mixerNode = getTrackMixerNode(for: track.id) {
                mixerNode.outputVolume = volume
            }
        }
    }
    
    private func fadeAllTracks(to targetVolume: Float, duration: TimeInterval) {
        for track in tracks.values {
            if let mixerNode = getTrackMixerNode(for: track.id) {
                let currentVolume = mixerNode.outputVolume
                
                // Create fade animation
                let steps = Int(duration * 10) // 10 steps per second
                let volumeStep = (targetVolume - currentVolume) / Float(steps)
                
                for step in 1...steps {
                    let delay = Double(step) * (duration / Double(steps))
                    let newVolume = currentVolume + (volumeStep * Float(step))
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        mixerNode.outputVolume = newVolume
                    }
                }
            }
        }
    }
    
    private func getTrackMixerNode(for trackId: UUID) -> AVAudioMixerNode? {
        // This would return the mixer node for a specific track
        // Implementation depends on the audio chain setup
        // For now, return nil as this requires more complex audio graph setup
        return nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Legacy Compatibility

extension AudioEngineManager {
    /// Legacy method for simple sound playback
    public func playSound(_ sound: Sound, loop: Bool = true) {
        Task {
            do {
                _ = try await play(sound: sound, loop: loop)
            } catch {
                print("AudioEngineManager: Failed to play sound: \(error)")
            }
        }
    }
    
    /// Legacy method for stopping all sounds
    public func stopSound(fadeOut: Bool = false, duration: TimeInterval = 1.0) {
        let fadeTime = fadeOut ? duration : nil
        stopAll(fade: fadeTime)
    }
    
    /// Legacy volume setter
    public func setVolume(_ volume: Float) {
        setSafeVolumeLevel(volume)
    }
    
    /// Legacy timer setter (converted to scheduled stop)
    public func setTimer(minutes: Int) {
        guard minutes > 0 else {
            cancelScheduledStops()
            return
        }
        
        let seconds = TimeInterval(minutes * 60)
        scheduleStop(after: seconds)
    }
    
    // Legacy published properties for existing UI
    public var isPlaying: Bool {
        !currentlyPlaying.isEmpty
    }
    
    public var currentVolume: Float {
        safeVolumeLevel
    }
    
    public var timerRemaining: TimeInterval {
        // This would need to be computed from scheduled stops
        // For now, return 0 to maintain compatibility
        return 0
    }
    
    // MARK: - Sleep Schedule Integration
    
    func startSleepSchedule(sounds: [String], fadeMinutes: Int) async {
        print("🌙 [AudioEngineManager] Starting sleep schedule with \(sounds.count) sound(s)")

        // Stop current playback
        stopAll(fade: 0.5)

        // Start selected sounds
        for soundId in sounds {
            do {
                let handle = try await play(
                    soundId: soundId,
                    loop: true,
                    fadeInDuration: 2.0,
                    gain: safeVolumeManager.currentSafeVolume
                )

                // Schedule auto fade
                if fadeMinutes > 0 {
                    scheduleAutoFade(handle: handle, fadeMinutes: fadeMinutes)
                }
            } catch {
                print("❌ [AudioEngineManager] Error starting sound \(soundId): \(error)")
            }
        }
    }

    private func scheduleAutoFade(handle: TrackHandle, fadeMinutes: Int) {
        Task {
            // Wait for specified time
            try? await Task.sleep(nanoseconds: UInt64(fadeMinutes * 60 * 1_000_000_000))

            // Check if track is still playing
            guard tracks[handle.id] != nil else { return }

            print("🌙 [AudioEngineManager] Auto fade after \(fadeMinutes) min for track \(handle.id)")

            // Fade out smoothly
            fadeOutTrack(tracks[handle.id]!, duration: 30.0) { [weak self] in
                self?.removeTrack(handle.id)
            }
        }
    }
} 