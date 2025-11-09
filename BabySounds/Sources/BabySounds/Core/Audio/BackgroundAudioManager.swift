import Foundation
import AVFoundation
import MediaPlayer
import SwiftUI

// MARK: - Background Audio Management

/// Extension to AudioEngineManager for background audio support and Now Playing Info
extension AudioEngineManager {
    
    // MARK: - Audio Session Management
    
    /// Setup audio session for background playback
    public func setupBackgroundAudioSession() {
        
        do {
            let session = AVAudioSession.sharedInstance()
            
            // Configure for playback with mixing capability
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
            
            // Activate the session
            try session.setActive(true)
            
            print("BackgroundAudioManager: Audio session configured for background playback")
            
            // Register for interruption notifications
            setupInterruptionHandling()
            
            // Setup remote control events
            setupRemoteControlEvents()
            
        } catch {
            print("BackgroundAudioManager: Failed to setup audio session: \(error)")
        }
    }
    
    /// Handle audio session interruptions (calls, other apps, etc.)
    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioSessionInterruption(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioRouteChange(notification)
        }
    }
    
    /// Handle audio session interruption events
    private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Interruption began (e.g., phone call)
            print("BackgroundAudioManager: Audio interruption began")
            
            // AudioEngine automatically pauses, but we should update UI state
            for track in tracks.values {
                track.playerNode.pause()
            }
            
            updateCurrentlyPlaying()
            
        case .ended:
            // Interruption ended
            print("BackgroundAudioManager: Audio interruption ended")
            
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                
                if options.contains(.shouldResume) {
                    // Resume playback
                    print("BackgroundAudioManager: Resuming playback after interruption")
                    
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        
                        // Restart engine if needed
                        if !engine.isRunning {
                            try engine.start()
                        }
                        
                        // Resume all tracks
                        for track in tracks.values {
                            track.playerNode.play()
                        }
                        
                        updateCurrentlyPlaying()
                        
                    } catch {
                        print("BackgroundAudioManager: Failed to resume after interruption: \(error)")
                    }
                }
            }
            
        @unknown default:
            break
        }
    }
    
    /// Handle audio route changes (headphones disconnected, etc.)
    private func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Handle headphones disconnection
            print("BackgroundAudioManager: Audio device disconnected")
            
            // For baby sounds, we might want to pause when headphones are disconnected
            // to prevent loud sounds from speakers
            DispatchQueue.main.async { [weak self] in
                self?.pauseAllTracksForSafety()
            }
            
        case .newDeviceAvailable:
            print("BackgroundAudioManager: New audio device connected")
            
        default:
            break
        }
    }
    
    /// Pause all tracks for safety (e.g., when headphones disconnected)
    private func pauseAllTracksForSafety() {
        print("BackgroundAudioManager: Pausing all tracks for safety")
        
        for track in tracks.values {
            track.playerNode.pause()
        }
        
        updateCurrentlyPlaying()
        updateNowPlayingInfo()
    }
    
    // MARK: - Remote Control Events
    
    /// Setup remote control events (control center, lock screen, headphones)
    private func setupRemoteControlEvents() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.handleRemotePlayCommand()
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.handleRemotePauseCommand()
            return .success
        }
        
        // Stop command
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.handleRemoteStopCommand()
            return .success
        }
        
        // Disable skip commands (not applicable for ambient sounds)
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        
        // Disable seeking (not applicable for looping sounds)
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        
        print("BackgroundAudioManager: Remote control events configured")
    }
    
    /// Handle remote play command
    private func handleRemotePlayCommand() {
        print("BackgroundAudioManager: Remote play command received")

        Task { @MainActor in
            // Resume all paused tracks
            for track in tracks.values {
                track.playerNode.play()
            }

            updateCurrentlyPlaying()
            updateNowPlayingInfo()
        }
    }
    
    /// Handle remote pause command
    private func handleRemotePauseCommand() {
        print("BackgroundAudioManager: Remote pause command received")
        
        Task { @MainActor in
            // Pause all tracks
            for track in tracks.values {
                track.playerNode.pause()
            }
            
            updateCurrentlyPlaying()
            updateNowPlayingInfo()
        }
    }
    
    /// Handle remote stop command
    private func handleRemoteStopCommand() {
        print("BackgroundAudioManager: Remote stop command received")
        
        Task { @MainActor in
            stopAll(fade: 1.0)
        }
    }
    
    // MARK: - Now Playing Info
    
    /// Update Now Playing Info Center with current track information
    public func updateNowPlayingInfo() {
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        
        if currentlyPlaying.isEmpty {
            // Clear Now Playing info when nothing is playing
            nowPlayingInfoCenter.nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo: [String: Any] = [:]
        
        // Determine primary sound info
        let primaryTrackInfo = currentlyPlaying.values.first!
        let sound = primaryTrackInfo.sound
        
        // Basic track information
        nowPlayingInfo[MPMediaItemPropertyTitle] = String(localized: sound.titleKey)
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Baby Sounds"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = sound.category.localizedName
        
        // Playback information
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        
        // Duration information
        if primaryTrackInfo.isLooping {
            // For looping sounds, show as indeterminate
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        } else {
            // For non-looping sounds, calculate duration
            let elapsed = Date().timeIntervalSince(primaryTrackInfo.startTime)
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
            
            // Estimate duration (we could load this from audio file if needed)
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 300 // 5 minutes default
        }
        
        // Track count information
        if currentlyPlaying.count > 1 {
            nowPlayingInfo[MPMediaItemPropertyTitle] = "\(currentlyPlaying.count) Sounds Playing"
            nowPlayingInfo[MPMediaItemPropertyArtist] = "Baby Sounds Mix"
        }
        
        // Genre and metadata
        nowPlayingInfo[MPMediaItemPropertyGenre] = "Ambient"
        nowPlayingInfo[MPMediaItemPropertyMediaType] = MPMediaType.anyAudio.rawValue
        
        // Set the info
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        
        print("BackgroundAudioManager: Updated Now Playing info for \(currentlyPlaying.count) track(s)")
    }
    
    /// Generate artwork for Now Playing display
    private func generateNowPlayingArtwork() -> MPMediaItemArtwork? {
        
        let artworkSize = CGSize(width: 512, height: 512)
        
        let artwork = MPMediaItemArtwork(boundsSize: artworkSize) { size in
            // Create a simple gradient artwork
            let renderer = UIGraphicsImageRenderer(size: size)
            
            return renderer.image { context in
                let bounds = CGRect(origin: .zero, size: size)
                
                // Background gradient
                let colors = [
                    UIColor.systemBlue.cgColor,
                    UIColor.systemPurple.cgColor
                ]
                
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colors as CFArray,
                                        locations: nil)!
                
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
                
                // Add app icon or sound category icon
                let iconSize: CGFloat = size.width * 0.6
                let iconRect = CGRect(
                    x: (size.width - iconSize) / 2,
                    y: (size.height - iconSize) / 2,
                    width: iconSize,
                    height: iconSize
                )
                
                // Draw a simple sound wave pattern
                UIColor.white.setStroke()
                let path = UIBezierPath()
                path.lineWidth = 4
                
                let centerY = iconRect.midY
                let startX = iconRect.minX
                let endX = iconRect.maxX
                let amplitude: CGFloat = iconSize * 0.1
                
                path.move(to: CGPoint(x: startX, y: centerY))
                
                for x in stride(from: startX, through: endX, by: 2) {
                    let progress = (x - startX) / (endX - startX)
                    let wave = sin(progress * .pi * 4) * amplitude
                    path.addLine(to: CGPoint(x: x, y: centerY + wave))
                }
                
                path.stroke()
            }
        }
        
        return artwork
    }
    
    // MARK: - Background Task Management
    
    /// Begin background task to ensure playback continuation
    public func beginBackgroundTask() -> UIBackgroundTaskIdentifier {
        let taskId = UIApplication.shared.beginBackgroundTask(withName: "BabySounds Audio Playback") {
            // Task expiration handler
            print("BackgroundAudioManager: Background task expired")
        }
        
        print("BackgroundAudioManager: Background task started: \(taskId.rawValue)")
        return taskId
    }
    
    /// End background task
    public func endBackgroundTask(_ taskId: UIBackgroundTaskIdentifier) {
        if taskId != .invalid {
            UIApplication.shared.endBackgroundTask(taskId)
            print("BackgroundAudioManager: Background task ended: \(taskId.rawValue)")
        }
    }
    
    // MARK: - App Lifecycle Integration
    
    /// Handle app entering background
    public func handleAppDidEnterBackground() {
        print("BackgroundAudioManager: App entered background")
        
        // Update Now Playing info to reflect current state
        updateNowPlayingInfo()
        
        // Ensure audio session remains active
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("BackgroundAudioManager: Audio session kept active in background")
        } catch {
            print("BackgroundAudioManager: Failed to keep audio session active: \(error)")
        }
    }
    
    /// Handle app entering foreground
    public func handleAppWillEnterForeground() {
        print("BackgroundAudioManager: App entering foreground")
        
        // Refresh audio session
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Restart engine if needed
            if !engine.isRunning && !currentlyPlaying.isEmpty {
                try engine.start()
                print("BackgroundAudioManager: Restarted audio engine")
            }
        } catch {
            print("BackgroundAudioManager: Failed to refresh audio session: \(error)")
        }
        
        // Update UI state
        updateCurrentlyPlaying()
    }
    
    /// Handle app termination
    public func handleAppWillTerminate() {
        print("BackgroundAudioManager: App terminating")
        
        // Clean up resources
        stopAll(fade: nil) // Immediate stop
        
        // Clear Now Playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("BackgroundAudioManager: Failed to deactivate audio session: \(error)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let backgroundAudioStateChanged = Notification.Name("backgroundAudioStateChanged")
    static let nowPlayingInfoUpdated = Notification.Name("nowPlayingInfoUpdated")
}

// MARK: - Background Audio State

/// Background audio state information
public struct BackgroundAudioState {
    public let isBackgroundCapable: Bool
    public let isCurrentlyInBackground: Bool
    public let activeTracksCount: Int
    public let audioSessionActive: Bool
    
    public init(
        isBackgroundCapable: Bool,
        isCurrentlyInBackground: Bool,
        activeTracksCount: Int,
        audioSessionActive: Bool
    ) {
        self.isBackgroundCapable = isBackgroundCapable
        self.isCurrentlyInBackground = isCurrentlyInBackground
        self.activeTracksCount = activeTracksCount
        self.audioSessionActive = audioSessionActive
    }
}

// MARK: - Background Audio Extensions

extension AudioEngineManager {
    
    /// Get current background audio state
    public var backgroundAudioState: BackgroundAudioState {
        let isBackgroundCapable = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
            .contains("audio")
        
        let isInBackground = UIApplication.shared.applicationState == .background
        let sessionActive = AVAudioSession.sharedInstance().isOtherAudioPlaying
        
        return BackgroundAudioState(
            isBackgroundCapable: isBackgroundCapable,
            isCurrentlyInBackground: isInBackground,
            activeTracksCount: currentlyPlaying.count,
            audioSessionActive: sessionActive
        )
    }
    
    /// Test background audio capabilities
    public func testBackgroundAudioSupport() -> Bool {
        let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        let hasAudioMode = backgroundModes.contains("audio")
        
        print("BackgroundAudioManager: Background audio support: \(hasAudioMode)")
        print("BackgroundAudioManager: Background modes: \(backgroundModes)")
        
        return hasAudioMode
    }
}

// MARK: - Private Extensions

private extension AVAudioPlayerNode {
    var isCurrentlyPlaying: Bool {
        return self.isPlaying
    }
} 