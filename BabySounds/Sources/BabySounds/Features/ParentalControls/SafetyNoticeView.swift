import SwiftUI

// MARK: - Safety Notice View

struct SafetyNoticeView: View {
    @StateObject private var safeVolumeManager = SafeVolumeManager.shared
    @StateObject private var parentGate = ParentGateManager.shared
    
    @State private var showVolumeWarning = false
    @State private var showBreakReminder = false
    @State private var showMaxTimeReached = false
    @State private var currentWarningLevel: SafeVolumeManager.VolumeWarningLevel = .safe
    @State private var currentListeningDuration: TimeInterval = 0
    
    var body: some View {
        VStack {
            // Main content area
            Spacer()
            
            // Safety notices overlay
            VStack(spacing: 16) {
                // Volume Warning
                if showVolumeWarning {
                    VolumeWarningCard(
                        level: currentWarningLevel,
                        onDismiss: {
                            showVolumeWarning = false
                        },
                        onAdjustVolume: {
                            adjustVolumeToSafe()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
                
                // Break Reminder
                if showBreakReminder {
                    BreakReminderCard(
                        duration: currentListeningDuration,
                        onDismiss: {
                            showBreakReminder = false
                        },
                        onTakeBreak: {
                            takeListeningBreak()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
                
                // Maximum Time Reached
                if showMaxTimeReached {
                    MaxTimeReachedCard(
                        onDismiss: {
                            showMaxTimeReached = false
                        },
                        onContinue: {
                            continueListening()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
            .padding()
            
            Spacer()
        }
        .onReceive(NotificationCenter.default.publisher(for: .volumeWarningTriggered)) { notification in
            handleVolumeWarning(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .breakRecommendationTriggered)) { notification in
            handleBreakRecommendation(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .maxListeningTimeReached)) { notification in
            handleMaxTimeReached(notification)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showVolumeWarning)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showBreakReminder)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showMaxTimeReached)
    }
    
    // MARK: - Notification Handlers
    
    private func handleVolumeWarning(_ notification: Notification) {
        guard let level = notification.userInfo?["level"] as? SafeVolumeManager.VolumeWarningLevel else {
            return
        }
        
        currentWarningLevel = level
        
        // Only show warning for caution level and above
        if level.rawValue >= SafeVolumeManager.VolumeWarningLevel.caution.rawValue {
            showVolumeWarning = true
            
            // Auto-dismiss after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                showVolumeWarning = false
            }
        }
    }
    
    private func handleBreakRecommendation(_ notification: Notification) {
        guard let duration = notification.userInfo?["duration"] as? TimeInterval else {
            return
        }
        
        currentListeningDuration = duration
        showBreakReminder = true
        
        // Auto-dismiss after 15 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            showBreakReminder = false
        }
    }
    
    private func handleMaxTimeReached(_ notification: Notification) {
        showMaxTimeReached = true
        
        // Auto-dismiss after 20 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            showMaxTimeReached = false
        }
    }
    
    // MARK: - Actions
    
    private func adjustVolumeToSafe() {
        let safeLevel = SafeVolumeManager.SafetyLimits.maxChildSafeVolume * 0.8 // 80% of max safe
        safeVolumeManager.setSafeVolumeMultiplier(safeLevel)
        showVolumeWarning = false
        
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func takeListeningBreak() {
        // Stop all audio and end session
        AudioEngineManager.shared.stopAll(fade: 2.0)
        safeVolumeManager.endListeningSession()
        showBreakReminder = false
        
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func continueListening() {
        // Require parent gate for extended listening
        parentGate.requestAccess(
            context: .settings,
            onSuccess: {
                // Reset listening session
                safeVolumeManager.endListeningSession()
                safeVolumeManager.startListeningSession()
                showMaxTimeReached = false
            },
            onFailure: { error in
                // Keep showing the warning
                print("Parent gate failed for extended listening: \(error)")
            }
        )
    }
}

// MARK: - Volume Warning Card

struct VolumeWarningCard: View {
    let level: SafeVolumeManager.VolumeWarningLevel
    let onDismiss: () -> Void
    let onAdjustVolume: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: iconForLevel)
                    .font(.title2)
                    .foregroundColor(Color(level.color))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume Notice")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(level.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            if level.rawValue >= SafeVolumeManager.VolumeWarningLevel.warning.rawValue {
                HStack(spacing: 12) {
                    Button("Auto-Adjust") {
                        onAdjustVolume()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: Color(level.color).opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
    
    private var iconForLevel: String {
        switch level {
        case .safe:
            return "speaker.wave.1"

        case .caution:
            return "speaker.wave.2"

        case .warning:
            return "speaker.wave.2.fill"

        case .danger:
            return "speaker.wave.3.fill"
        }
    }
}

// MARK: - Break Reminder Card

struct BreakReminderCard: View {
    let duration: TimeInterval
    let onDismiss: () -> Void
    let onTakeBreak: () -> Void
    
    private var formattedDuration: String {
        let minutes = Int(duration) / 60
        return "\(minutes) minutes"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time for a Break")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("You've been listening for \(formattedDuration). Consider taking a break to protect your hearing.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Button("Take Break") {
                    onTakeBreak()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Continue") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Maximum Time Reached Card

struct MaxTimeReachedCard: View {
    let onDismiss: () -> Void
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                
                Text("Maximum Listening Time Reached")
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("For hearing safety, it's recommended to take a break after 1 hour of continuous listening.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Continue with Parent Permission") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                
                Button("Take a Break") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .red.opacity(0.3), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Preview

#if DEBUG
struct SafetyNoticeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue.opacity(0.1)
                .ignoresSafeArea()
            
            SafetyNoticeView()
        }
        .previewDisplayName("Safety Notice Overlay")
    }
}

struct VolumeWarningCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            VolumeWarningCard(
                level: .warning,
                onDismiss: {},
                onAdjustVolume: {}
            )
            
            VolumeWarningCard(
                level: .danger,
                onDismiss: {},
                onAdjustVolume: {}
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}

struct BreakReminderCard_Previews: PreviewProvider {
    static var previews: some View {
        BreakReminderCard(
            duration: 2700, // 45 minutes
            onDismiss: {},
            onTakeBreak: {}
        )
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}

struct MaxTimeReachedCard_Previews: PreviewProvider {
    static var previews: some View {
        MaxTimeReachedCard(
            onDismiss: {},
            onContinue: {}
        )
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}
#endif
