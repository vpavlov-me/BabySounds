import SwiftUI

// MARK: - Data Debug View

/// Debug view to demonstrate JSON data loading and binding to UI
struct DataDebugView: View {
    @EnvironmentObject var soundCatalog: SoundCatalog
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var audioManager: AudioEngineManager
    @StateObject var safeVolumeManager = SafeVolumeManager.shared
    @StateObject var sleepScheduleManager = SleepScheduleManager.shared
    
    @State private var isLoading = false
    @State private var selectedCategory: SoundCategory = .white
    
    private var subscriptionStatusText: String {
        switch subscriptionService.subscriptionStatus {
        case .notSubscribed:
            return "Free"
        case .subscribed:
            return "Premium"
        case .inTrialPeriod:
            return "Trial"
        case .expired:
            return "Expired"
        case .pending:
            return "Pending"
        case .inGracePeriod:
            return "Grace Period"
        }
    }
    
    private var warningLevelText: String {
        switch safeVolumeManager.volumeWarningLevel {
        case .safe:
            return "SAFE"
        case .caution:
            return "CAUTION"
        case .warning:
            return "WARNING"
        case .danger:
            return "DANGER"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header with stats
                VStack(spacing: 8) {
                    Text("Data Wiring Demo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Demonstrating JSON → UI data flow")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Stats cards
                HStack(spacing: 16) {
                    StatCard(
                        title: "Total Sounds",
                        value: "\(soundCatalog.sounds.count)",
                        icon: "music.note.list",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Favorites",
                        value: "\(soundCatalog.favorites.count)",
                        icon: "heart.fill",
                        color: .red
                    )
                    
                    StatCard(
                        title: "Playing",
                        value: "\(audioManager.currentlyPlaying.count)",
                        icon: "speaker.wave.2.fill",
                        color: .green
                    )
                }
                .padding(.horizontal)
                
                // Premium Stats Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Premium Status")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        PremiumStatsCard(
                            title: "Subscription",
                            value: subscriptionStatusText,
                            color: subscriptionService.hasActiveSubscription ? .green : .orange
                        )
                        
                        PremiumStatsCard(
                            title: "Favorites",
                            value: "\(soundCatalog.favorites.count)/\(premiumManager.hasAccess(to: .unlimitedFavorites) ? "∞" : "\(PremiumManager.Limits.maxFavoritesForFree)")",
                            color: .blue
                        )
                        
                        PremiumStatsCard(
                            title: "Features",
                            value: "\(PremiumManager.PremiumFeature.allCases.filter { premiumManager.hasAccess(to: $0) }.count)/\(PremiumManager.PremiumFeature.allCases.count)",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Safe Volume Stats Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Safe Volume Status")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        PremiumStatsCard(
                            title: "Safe Volume",
                            value: safeVolumeManager.isSafeVolumeEnabled ? "ON" : "OFF",
                            color: safeVolumeManager.isSafeVolumeEnabled ? .green : .red
                        )
                        
                        PremiumStatsCard(
                            title: "Max Volume",
                            value: "\(Int(safeVolumeManager.safeVolumeMultiplier * 100))%",
                            color: safeVolumeManager.safeVolumeMultiplier <= 0.5 ? .green : safeVolumeManager.safeVolumeMultiplier <= 0.7 ? .orange : .red
                        )
                        
                        PremiumStatsCard(
                            title: "Warning Level",
                            value: warningLevelText,
                            color: Color(safeVolumeManager.volumeWarningLevel.color)
                        )
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        PremiumStatsCard(
                            title: "Session Time",
                            value: formatDuration(safeVolumeManager.currentListeningDuration),
                            color: safeVolumeManager.currentListeningDuration > SafeVolumeManager.SafetyLimits.breakReminderInterval ? .orange : .green
                        )
                        
                        PremiumStatsCard(
                            title: "Parent Override",
                            value: safeVolumeManager.isParentalOverrideActive ? "ACTIVE" : "OFF",
                            color: safeVolumeManager.isParentalOverrideActive ? .orange : .gray
                        )
                        
                        PremiumStatsCard(
                            title: "Break Needed",
                            value: safeVolumeManager.needsBreakReminder ? "YES" : "NO",
                            color: safeVolumeManager.needsBreakReminder ? .red : .green
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Parent Gate Stats Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Parent Gate Status")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        PremiumStatsCard(
                            title: "Settings",
                            value: ParentGateManager.isRecentlyPassed(for: .settings, within: 300) ? "✓" : "⏳",
                            color: ParentGateManager.isRecentlyPassed(for: .settings, within: 300) ? .green : .orange
                        )
                        
                        PremiumStatsCard(
                            title: "Paywall",
                            value: ParentGateManager.isRecentlyPassed(for: .paywall, within: 300) ? "✓" : "⏳",
                            color: ParentGateManager.isRecentlyPassed(for: .paywall, within: 300) ? .green : .orange
                        )
                        
                        PremiumStatsCard(
                            title: "Failed",
                            value: "\(ParentGateManager.getFailedAttemptCount(for: .settings) + ParentGateManager.getFailedAttemptCount(for: .paywall))",
                            color: .red
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Sleep Schedules Stats Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sleep Schedules Status")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        PremiumStatsCard(
                            title: "Total",
                            value: "\(sleepScheduleManager.schedules.count)",
                            color: .blue
                        )
                        
                        PremiumStatsCard(
                            title: "Active",
                            value: "\(sleepScheduleManager.activeSchedules.count)",
                            color: .green
                        )
                        
                        PremiumStatsCard(
                            title: "Notifications",
                            value: sleepScheduleManager.isNotificationPermissionGranted ? "✓" : "✗",
                            color: sleepScheduleManager.isNotificationPermissionGranted ? .green : .red
                        )
                        
                        PremiumStatsCard(
                            title: "Can Add More",
                            value: sleepScheduleManager.canAddMoreSchedules ? "YES" : "NO",
                            color: sleepScheduleManager.canAddMoreSchedules ? .green : .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Next event info
                    if let nextEvent = sleepScheduleManager.nextScheduledEvent {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Next Event: \(nextEvent.schedule.name)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(nextEvent.type == "reminder" ? "Reminder" : "Bedtime") at \(formatTime(nextEvent.time))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    // Test buttons
                    HStack(spacing: 12) {
                        Button("Test Reminder") {
                            testScheduleReminder()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .controlSize(.small)
                        
                        Button("Test Bedtime") {
                            testScheduleBedtime()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .controlSize(.small)
                        
                        Button("Add Test Schedule") {
                            addTestSchedule()
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        .controlSize(.small)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Category breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sounds by Category")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SoundCategory.allCases, id: \.self) { category in
                                CategoryStatsCard(
                                    category: category,
                                    soundCount: soundCatalog.sounds(for: category).count,
                                    isSelected: selectedCategory == category
                                )
                                .onTapGesture {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Selected category sounds
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(selectedCategory.localizedName) Sounds")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(soundCatalog.sounds(for: selectedCategory).count) sounds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    List(soundCatalog.sounds(for: selectedCategory)) { sound in
                        CompactSoundRow(sound: sound)
                    }
                    .frame(height: 200)
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        reloadData()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Reload from JSON")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    
                    Button(action: {
                        testAudioLoading()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Test Audio Loading")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    
                    // Safe Volume Test Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            testVolumeWarning()
                        }) {
                            VStack {
                                Image(systemName: "speaker.wave.3")
                                Text("Test Volume Warning")
                                    .font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        
                        Button(action: {
                            testBreakReminder()
                        }) {
                            VStack {
                                Image(systemName: "clock")
                                Text("Test Break Reminder")
                                    .font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            safeVolumeManager.resetToChildSafeDefaults()
                        }) {
                            VStack {
                                Image(systemName: "shield.checkerboard")
                                Text("Reset to Safe Defaults")
                                    .font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        
                        Button(action: {
                            toggleSafeVolume()
                        }) {
                            VStack {
                                Image(systemName: safeVolumeManager.isSafeVolumeEnabled ? "speaker.slash" : "speaker.wave.2")
                                Text(safeVolumeManager.isSafeVolumeEnabled ? "Disable Safe Volume" : "Enable Safe Volume")
                                    .font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(safeVolumeManager.isSafeVolumeEnabled ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func reloadData() {
        isLoading = true
        Task {
            do {
                try await soundCatalog.loadSoundsFromJSON()
                print("DataDebugView: Successfully reloaded \(soundCatalog.sounds.count) sounds")
            } catch {
                print("DataDebugView: Failed to reload: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func testAudioLoading() {
        guard let firstSound = soundCatalog.sounds.first else { return }
        
        Task {
            do {
                try await audioManager.preload(sound: firstSound)
                print("DataDebugView: Successfully preloaded \(firstSound.fileName)")
                
                let handle = try await audioManager.play(sound: firstSound, loop: true)
                print("DataDebugView: Started playing \(firstSound.fileName) with handle \(handle.id)")
                
                // Stop after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    audioManager.stop(id: handle.id, fade: 1.0)
                    print("DataDebugView: Stopped playback with fade")
                }
            } catch {
                print("DataDebugView: Audio test failed: \(error)")
            }
        }
    }
    
    private func testVolumeWarning() {
        // Simulate a volume warning by posting notification
        NotificationCenter.default.post(
            name: .volumeWarningTriggered,
            object: nil,
            userInfo: [
                "volume": Float(0.8),
                "level": SafeVolumeManager.VolumeWarningLevel.warning
            ]
        )
        print("DataDebugView: Triggered test volume warning")
    }
    
    private func testBreakReminder() {
        // Simulate a break reminder by posting notification
        NotificationCenter.default.post(
            name: .breakRecommendationTriggered,
            object: nil,
            userInfo: [
                "duration": TimeInterval(2700) // 45 minutes
            ]
        )
        print("DataDebugView: Triggered test break reminder")
    }
    
    private func toggleSafeVolume() {
        safeVolumeManager.setSafeVolumeEnabled(!safeVolumeManager.isSafeVolumeEnabled)
        print("DataDebugView: Toggled safe volume to \(safeVolumeManager.isSafeVolumeEnabled)")
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CategoryStatsCard: View {
    let category: SoundCategory
    let soundCount: Int
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(category.emoji)
                .font(.title)
            
            Text("\(soundCount)")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(String(describing: category).capitalized)
                .font(.caption2)
                .lineLimit(1)
        }
        .frame(width: 80, height: 80)
        .background(isSelected ? category.emoji.isEmpty ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct CompactSoundRow: View {
    let sound: Sound
    @EnvironmentObject var soundCatalog: SoundCatalog
    @EnvironmentObject var audioManager: AudioEngineManager
    
    private var isCurrentlyPlaying: Bool {
        audioManager.currentlyPlaying.values.contains { $0.soundId == sound.id }
    }
    
    private var audioFileExists: Bool {
        Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExt) != nil
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicators
            HStack(spacing: 4) {
                Circle()
                    .fill(sound.color.color)
                    .frame(width: 8, height: 8)
                
                if isCurrentlyPlaying {
                    Image(systemName: "speaker.wave.1.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                if !audioFileExists {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            // Sound info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(sound.displayEmoji)
                        .font(.body)
                    
                    Text(sound.titleKey)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 8) {
                    Text(sound.fileName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if sound.premium {
                        Text("Premium")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    if sound.loop {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Quick play button
            Button(action: {
                if isCurrentlyPlaying {
                    // Stop if currently playing
                    if let playingInfo = audioManager.currentlyPlaying.values.first(where: { $0.soundId == sound.id }) {
                        audioManager.stop(id: playingInfo.id, fade: 0.5)
                    }
                } else {
                    // Start playing
                    audioManager.playSound(sound)
                }
            }) {
                Image(systemName: isCurrentlyPlaying ? "stop.fill" : "play.fill")
                    .font(.caption)
                    .foregroundColor(isCurrentlyPlaying ? .red : .blue)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!audioFileExists)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Sleep Schedule Test Functions
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func testScheduleReminder() {
        print("🧪 [DataDebugView] Тестирование напоминания расписания сна")
        
        // Simulate reminder notification
        let testSchedule = SleepSchedule(
            name: "Тестовое расписание", 
            selectedSounds: ["white_noise_ocean", "lullaby_brahms"]
        )
        
        sleepScheduleManager.handleBedtimeNotification(
            scheduleId: testSchedule.id.uuidString,
            selectedSounds: testSchedule.selectedSounds
        )
    }
    
    private func testScheduleBedtime() {
        print("🧪 [DataDebugView] Тестирование времени сна")
        
        // Test bedtime with sample sounds
        let testSounds = ["white_noise_rain", "nature_forest_birds"]
        
        Task {
            await audioManager.startSleepSchedule(sounds: testSounds, fadeMinutes: 2)
        }
    }
    
    private func addTestSchedule() {
        print("🧪 [DataDebugView] Добавление тестового расписания")
        
        let testSchedule = SleepSchedule(
            name: "Тестовое расписание \(Date().timeIntervalSince1970)",
            isEnabled: true,
            bedTime: Calendar.current.date(byAdding: .minute, value: 2, to: Date()) ?? Date(),
            selectedDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            reminderMinutes: 1,
            selectedSounds: ["white_noise_ocean", "lullaby_twinkle"],
            autoFadeMinutes: 30
        )
        
        Task {
            do {
                try await sleepScheduleManager.addSchedule(testSchedule)
                print("✅ Тестовое расписание добавлено")
            } catch {
                print("❌ Ошибка добавления тестового расписания: \(error)")
            }
        }
    }
}

// MARK: - Preview

struct DataDebugView_Previews: PreviewProvider {
    static var previews: some View {
        DataDebugView()
            .environmentObject(SoundCatalog())
            .environmentObject(SubscriptionServiceSK2.shared)
            .environmentObject(PremiumManager.shared)
            .environmentObject(AudioEngineManager.shared)
    }
}

// MARK: - Premium Stats Card

struct PremiumStatsCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
} 