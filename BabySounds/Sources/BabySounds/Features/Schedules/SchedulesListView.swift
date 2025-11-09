import SwiftUI

// MARK: - Schedules List View

struct SchedulesListView: View {
    @EnvironmentObject var scheduleManager: SleepScheduleManager
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var premiumManager: PremiumManager
    
    @State private var showingAddSheet = false
    @State private var showNowPlaying = false
    @State private var selectedSchedule: SleepSchedule?
    
    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                Group {
                    if scheduleManager.schedules.isEmpty {
                        emptyStateView
                    } else {
                        schedulesList
                    }
                }
                
                // Mini Player
                MiniPlayerView(showNowPlaying: $showNowPlaying)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Schedules")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                    HapticManager.shared.impact(.light)
                } label: {
                    Image(systemName: "plus")
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            SleepScheduleEditView(schedule: nil, isPresented: $showingAddSheet)
        }
        .sheet(item: $selectedSchedule) { schedule in
            SleepScheduleEditView(schedule: schedule, isPresented: .constant(true))
        }
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView(isPresented: $showNowPlaying)
        }
    }
    
    // MARK: - Schedules List
    
    private var schedulesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(scheduleManager.schedules, id: \.id) { schedule in
                    ScheduleCard(
                        schedule: schedule,
                        onTap: { selectedSchedule = schedule },
                        onToggle: { scheduleManager.toggleSchedule(schedule) }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
                
                // Bottom spacing for mini player
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Illustration
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.6))
                }
                
                VStack(spacing: 8) {
                    Text("No Schedules Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Create sleep schedules to automatically play sounds at specific times")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            // Quick action button
            Button {
                showingAddSheet = true
                HapticManager.shared.impact(.medium)
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.headline)
                    Text("Create Schedule")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(25)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Schedule Card

struct ScheduleCard: View {
    let schedule: SleepSchedule
    let onTap: () -> Void
    let onToggle: () -> Void
    
    @EnvironmentObject var soundCatalog: SoundCatalog
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(schedule.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(timeDisplayText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Toggle switch
                    Toggle("", isOn: .constant(schedule.isEnabled))
                        .labelsHidden()
                        .scaleEffect(0.9)
                        .onTapGesture {
                            onToggle()
                            HapticManager.shared.impact(.light)
                        }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Days and Sound info
                VStack(spacing: 12) {
                    // Days of week
                    HStack(spacing: 8) {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day.prefix(1))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(schedule.daysOfWeek.contains(day) ? .white : .secondary)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(schedule.daysOfWeek.contains(day) ? .pink : Color.clear)
                                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        Spacer()
                    }
                    
                    // Sound preview
                    if let sound = associatedSound {
                        HStack(spacing: 12) {
                            // Sound artwork
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(
                                        colors: sound.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                
                                Text(sound.displayEmoji)
                                    .font(.caption)
                            }
                            .frame(width: 32, height: 32)
                            
                            // Sound info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sound.titleKey)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Text("Duration: \(schedule.duration / 60) min")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Premium badge
                            if sound.premium {
                                Image(systemName: "crown.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            // Status indicator
            RoundedRectangle(cornerRadius: 16)
                .stroke(schedule.isEnabled ? .pink : Color.clear, lineWidth: 2)
        )
    }
    
    // MARK: - Computed Properties
    
    private var timeDisplayText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: schedule.startTime)
    }
    
    private var daysOfWeek: [String] {
        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    }
    
    private var associatedSound: Sound? {
        soundCatalog.allSounds.first { $0.id == schedule.soundId }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SchedulesListView()
            .environmentObject(SleepScheduleManager.shared)
            .environmentObject(AudioEngineManager.shared)
            .environmentObject(PremiumManager.shared)
            .environmentObject(SoundCatalog())
    }
}
