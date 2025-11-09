import SwiftUI

// MARK: - Safety Settings View

struct SafetySettingsView: View {
    @StateObject private var safeVolumeManager = SafeVolumeManager.shared
    @StateObject private var parentGate = ParentGateManager.shared
    
    @State private var showParentGate = false
    @State private var showVolumeInfo = false
    @State private var showTimeInfo = false
    @State private var tempVolumeLevel: Float = 0.7
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    SafetyHeaderView()
                    
                    // Volume Safety Settings
                    VolumeSafetySection(
                        safeVolumeManager: safeVolumeManager,
                        tempVolumeLevel: $tempVolumeLevel,
                        showVolumeInfo: $showVolumeInfo
                    )
                    
                    // Listening Time Settings
                    ListeningTimeSection(
                        safeVolumeManager: safeVolumeManager,
                        showTimeInfo: $showTimeInfo
                    )
                    
                    // Parental Controls
                    ParentalControlsSection(
                        safeVolumeManager: safeVolumeManager,
                        parentGate: parentGate,
                        showParentGate: $showParentGate
                    )
                    
                    // Safety Information
                    SafetyInformationSection()
                    
                    // Reset Button
                    ResetSafetyButton(safeVolumeManager: safeVolumeManager)
                }
                .padding()
            }
            .navigationTitle("Child Safety")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            tempVolumeLevel = safeVolumeManager.safeVolumeMultiplier
        }
        .sheet(isPresented: $showParentGate) {
            ParentGateView(
                isPresented: $showParentGate,
                context: .settings
            )                {
                    // Parent gate passed, allow changes
                }
        }
        .sheet(isPresented: $showVolumeInfo) {
            VolumeInfoSheet(isPresented: $showVolumeInfo)
        }
        .sheet(isPresented: $showTimeInfo) {
            ListeningTimeInfoSheet(isPresented: $showTimeInfo)
        }
    }
}

// MARK: - Safety Header View

struct SafetyHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.checkerboard")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Child Safety Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Protect your child's hearing with safe volume limits and listening time controls")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Volume Safety Section

struct VolumeSafetySection: View {
    @ObservedObject var safeVolumeManager: SafeVolumeManager
    @Binding var tempVolumeLevel: Float
    @Binding var showVolumeInfo: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Volume Safety",
                icon: "speaker.wave.2"
            )                { showVolumeInfo = true }
            
            VStack(spacing: 20) {
                // Safe Volume Toggle
                SettingRow(
                    icon: "shield",
                    title: "Safe Volume Protection",
                    subtitle: safeVolumeManager.isSafeVolumeEnabled ? "Active" : "Disabled"
                ) {
                    Toggle("", isOn: Binding(
                        get: { safeVolumeManager.isSafeVolumeEnabled },
                        set: { newValue in
                            safeVolumeManager.setSafeVolumeEnabled(newValue)
                        }
                    ))
                    .labelsHidden()
                }
                
                if safeVolumeManager.isSafeVolumeEnabled {
                    // Volume Level Slider
                    VStack(spacing: 12) {
                        HStack {
                            Text("Maximum Volume")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(Int(tempVolumeLevel * 100))%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(colorForVolumeLevel(tempVolumeLevel))
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "speaker.wave.1")
                                    .foregroundColor(.secondary)
                                
                                Slider(
                                    value: $tempVolumeLevel,
                                    in: 0.1...SafeVolumeManager.SafetyLimits.maxChildSafeVolume,
                                    step: 0.05
                                ) { editing in
                                    if !editing {
                                        safeVolumeManager.setSafeVolumeMultiplier(tempVolumeLevel)
                                    }
                                }
                                .accentColor(colorForVolumeLevel(tempVolumeLevel))
                                
                                Image(systemName: "speaker.wave.3")
                                    .foregroundColor(.secondary)
                            }
                            
                            // Volume level indicator
                            Text(volumeLevelDescription(tempVolumeLevel))
                                .font(.caption)
                                .foregroundColor(colorForVolumeLevel(tempVolumeLevel))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Current Volume Warning Level
                    VolumeWarningLevelView(level: safeVolumeManager.volumeWarningLevel)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
    
    private func colorForVolumeLevel(_ level: Float) -> Color {
        if level <= 0.3 {
            return .green
        } else if level <= 0.5 {
            return .yellow
        } else if level <= 0.7 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func volumeLevelDescription(_ level: Float) -> String {
        if level <= 0.3 {
            return "Very Safe - Perfect for young children"
        } else if level <= 0.5 {
            return "Safe - Good for extended listening"
        } else if level <= 0.7 {
            return "Moderate - Use with caution"
        } else {
            return "High - Not recommended for children"
        }
    }
}

// MARK: - Listening Time Section

struct ListeningTimeSection: View {
    @ObservedObject var safeVolumeManager: SafeVolumeManager
    @Binding var showTimeInfo: Bool
    
    private var currentSessionDuration: String {
        let minutes = Int(safeVolumeManager.currentListeningDuration) / 60
        return "\(minutes) min"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Listening Time",
                icon: "clock"
            )                { showTimeInfo = true }
            
            VStack(spacing: 16) {
                // Current Session
                SettingRow(
                    icon: "play.circle",
                    title: "Current Session",
                    subtitle: safeVolumeManager.currentListeningDuration > 0 ? currentSessionDuration : "Not active"
                ) {
                    if safeVolumeManager.currentListeningDuration > 0 {
                        Button("End Session") {
                            safeVolumeManager.endListeningSession()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                
                // Break Reminder Status
                SettingRow(
                    icon: "bell",
                    title: "Break Reminder",
                    subtitle: safeVolumeManager.needsBreakReminder ? "Break recommended" : "45 min intervals"
                ) {
                    Image(systemName: safeVolumeManager.needsBreakReminder ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(safeVolumeManager.needsBreakReminder ? .orange : .green)
                }
                
                // Safety Recommendation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Safety Recommendation")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(safeVolumeManager.getSafetyRecommendation())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Parental Controls Section

struct ParentalControlsSection: View {
    @ObservedObject var safeVolumeManager: SafeVolumeManager
    @ObservedObject var parentGate: ParentGateManager
    @Binding var showParentGate: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Parental Controls",
                icon: "person.2.fill",
                infoAction: nil
            )
            
            VStack(spacing: 16) {
                // Parental Override Status
                SettingRow(
                    icon: "lock.open",
                    title: "Parental Override",
                    subtitle: safeVolumeManager.isParentalOverrideActive ? "Active (30 min)" : "Disabled"
                ) {
                    if safeVolumeManager.isParentalOverrideActive {
                        Button("Deactivate") {
                            safeVolumeManager.deactivateParentalOverride()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Button("Activate") {
                            showParentGate = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                
                // Parent Gate Status
                SettingRow(
                    icon: "shield.checkered",
                    title: "Parent Gate",
                    subtitle: "Required for volume changes"
                ) {
                    Button("Test Gate") {
                        showParentGate = true
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
        )
    }
}

// MARK: - Safety Information Section

struct SafetyInformationSection: View {
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Safety Guidelines",
                icon: "info.circle",
                infoAction: nil
            )
            
            VStack(spacing: 12) {
                SafetyInfoRow(
                    icon: "ear",
                    title: "WHO Guidelines",
                    description: "Maximum 85dB for extended listening"
                )
                
                SafetyInfoRow(
                    icon: "clock",
                    title: "Recommended Breaks",
                    description: "15 minutes every 45 minutes of listening"
                )
                
                SafetyInfoRow(
                    icon: "headphones",
                    title: "Headphone Safety",
                    description: "Audio pauses when headphones disconnected"
                )
                
                SafetyInfoRow(
                    icon: "house",
                    title: "Safe Environment",
                    description: "Use in quiet environment for lower volumes"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    let infoAction: (() -> Void)?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            if let infoAction = infoAction {
                Button(action: infoAction) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct SettingRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let content: Content
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct SafetyInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct VolumeWarningLevelView: View {
    let level: SafeVolumeManager.VolumeWarningLevel
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(level.color))
            
            Text("Current Level: \(level.message)")
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(level.color).opacity(0.1))
        )
    }
}

struct ResetSafetyButton: View {
    @ObservedObject var safeVolumeManager: SafeVolumeManager
    
    var body: some View {
        Button("Reset to Child-Safe Defaults") {
            safeVolumeManager.resetToChildSafeDefaults()
        }
        .buttonStyle(.bordered)
        .foregroundColor(.red)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Info Sheets

struct VolumeInfoSheet: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Volume Safety Information")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(
                            title: "Safe Volume Levels",
                            content: "According to WHO guidelines, prolonged exposure above 85dB can cause hearing damage. Our app limits volume to 70% of maximum (approximately 85dB) by default."
                        )
                        
                        InfoSection(
                            title: "Volume Colors",
                            content: "Green (0-30%): Very safe for all ages\nYellow (30-50%): Safe for extended use\nOrange (50-70%): Moderate, use with caution\nRed (70%+): High volume, not recommended"
                        )
                        
                        InfoSection(
                            title: "Automatic Protection",
                            content: "When headphones are unplugged, audio automatically pauses to prevent loud speaker volume. Volume warnings appear when levels become unsafe."
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Volume Safety")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct ListeningTimeInfoSheet: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Listening Time Guidelines")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(
                            title: "Recommended Breaks",
                            content: "Take a 15-minute break every 45 minutes of listening. This helps prevent ear fatigue and maintains healthy hearing habits."
                        )
                        
                        InfoSection(
                            title: "Maximum Session Time",
                            content: "After 1 hour of continuous listening, the app recommends ending the session. Extended listening requires parental permission."
                        )
                        
                        InfoSection(
                            title: "Session Tracking",
                            content: "The app automatically tracks listening time and provides gentle reminders. Sessions reset when audio is paused for more than 10 minutes."
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Listening Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct InfoSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Preview

#if DEBUG
struct SafetySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SafetySettingsView()
    }
}
#endif
