import SwiftUI

// MARK: - SleepSchedulesView

struct SleepSchedulesView: View {
    @StateObject private var scheduleManager = SleepScheduleManager.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var parentGateManager = ParentGateManager.shared
    
    @State private var showingAddSchedule = false
    @State private var editingSchedule: SleepSchedule?
    @State private var showingPermissionAlert = false
    @State private var showingError = false
    @State private var showPaywall = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if scheduleManager.isLoadingSchedules {
                    ProgressView("Loading schedules...")
                } else {
                    mainContent
                }
            }
            .navigationTitle("Sleep Schedules")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .sheet(isPresented: $showingAddSchedule) {
                SleepScheduleEditView(schedule: nil)
            }
            .sheet(item: $editingSchedule) { schedule in
                SleepScheduleEditView(schedule: schedule)
            }
            .alert("Notification Permission", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Sleep schedules require notification permission. Go to Settings → BabySounds → Notifications and enable them.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                if let error = scheduleManager.lastError {
                    Text(error.localizedDescription)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(isPresented: $showPaywall)
            }
            .premiumGateAlert(premiumManager: premiumManager, showPaywall: $showPaywall)
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        if scheduleManager.schedules.isEmpty {
            emptyState
        } else {
            schedulesList
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: View {
        VStack(spacing: 24) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Sleep Schedules")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create a schedule to automatically play soothing sounds at bedtime")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: addScheduleAction) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Schedule")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .opacity(scheduleManager.canAddMoreSchedules ? 1.0 : 0.6)
            .disabled(!scheduleManager.canAddMoreSchedules)
        }
        .padding()
    }
    
    // MARK: - Schedules List
    
    private var schedulesList: View {
        List {
            // Notifications section
            if !scheduleManager.isNotificationPermissionGranted {
                notificationPermissionSection
            }

            // Next event
            if let nextEvent = scheduleManager.nextScheduledEvent {
                nextEventSection(nextEvent)
            }

            // Premium banner for free users
            if !premiumManager.hasFeature(.sleepSchedules) {
                premiumSection
            }

            // Schedules list
            schedulesSection
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Notification Permission Section
    
    private var notificationPermissionSection: some View {
        Section {
            HStack {
                Image(systemName: "bell.slash")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications Disabled")
                        .font(.headline)

                    Text("Enable notifications for schedules to work")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Enable") {
                    Task {
                        let granted = await scheduleManager.requestNotificationPermission()
                        if !granted {
                            showingPermissionAlert = true
                        }
                    }
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .controlSize(.small)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Next Event Section
    
    private func nextEventSection(_ event: (schedule: SleepSchedule, time: Date, type: String)) -> some View {
        Section("Next Event") {
            HStack {
                Image(systemName: event.type == "reminder" ? "bell" : "moon.zzz")
                    .foregroundColor(event.type == "reminder" ? .orange : .blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.schedule.name)
                        .font(.headline)

                    HStack {
                        Text(event.type == "reminder" ? "Reminder" : "Bedtime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(formatRelativeTime(event.time))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(formatTime(event.time))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Premium Section
    
    private var premiumSection: some View {
        Section {
            PremiumGateView(
                feature: .sleepSchedules,
                title: "Unlimited Schedules",
                description: "Create unlimited sleep schedules with flexible settings",
                icon: "moon.zzz"
            )                {
                    premiumManager.requestAccess(to: .sleepSchedules)
                }
        }
    }
    
    // MARK: - Schedules Section
    
    private var schedulesSection: some View {
        Section("My Schedules") {
            ForEach(scheduleManager.schedules) { schedule in
                SleepScheduleRow(
                    schedule: schedule,
                    onEdit: { editingSchedule = schedule },
                    onToggle: {
                        Task {
                            do {
                                try await scheduleManager.toggleSchedule(schedule)
                            } catch {
                                scheduleManager.lastError = error
                                showingError = true
                            }
                        }
                    },
                    onDelete: {
                        Task {
                            await scheduleManager.deleteSchedule(schedule)
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Add Button
    
    private var addButton: some View {
        Button(action: addScheduleAction) {
            Image(systemName: "plus")
                .font(.title2)
        }
        .opacity(scheduleManager.canAddMoreSchedules ? 1.0 : 0.3)
        .disabled(!scheduleManager.canAddMoreSchedules)
    }
    
    // MARK: - Actions
    
    private func addScheduleAction() {
        guard scheduleManager.canAddMoreSchedules else {
            // Show premium gate
            premiumManager.requestAccess(to: .sleepSchedules)
            return
        }

        showingAddSchedule = true
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)

        if timeInterval < 60 {
            return "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "in \(minutes) min"
        } else if timeInterval < 86_400 {
            let hours = Int(timeInterval / 3600)
            return "in \(hours) h"
        } else {
            let days = Int(timeInterval / 86_400)
            return "in \(days) d"
        }
    }
}

// MARK: - SleepScheduleRow

struct SleepScheduleRow: View {
    let schedule: SleepSchedule
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(schedule.isEnabled ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.name)
                    .font(.headline)
                    .foregroundColor(schedule.isEnabled ? .primary : .secondary)
                
                HStack {
                    Image(systemName: "moon.zzz")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(schedule.formattedBedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(schedule.selectedDaysText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !schedule.selectedSounds.isEmpty {
                    HStack {
                        Image(systemName: "speaker.wave.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(schedule.selectedSounds.count) sound(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack {
                Toggle("", isOn: .constant(schedule.isEnabled))
                    .labelsHidden()
                    .onChange(of: schedule.isEnabled) { _ in
                        onToggle()
                    }
                
                if let nextBedTime = schedule.nextBedTime {
                    Text(formatRelativeTime(nextBedTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                onDelete()
            }

            Button("Edit") {
                onEdit()
            }
            .tint(.blue)
        }
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)

        if timeInterval < 60 {
            return "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else if timeInterval < 86_400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(timeInterval / 86_400)
            return "\(days)d"
        }
    }
}

// MARK: - Preview

struct SleepSchedulesView_Previews: PreviewProvider {
    static var previews: some View {
        SleepSchedulesView()
    }
}
