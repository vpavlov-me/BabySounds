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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if scheduleManager.isLoadingSchedules {
                    ProgressView("Загрузка расписаний...")
                } else {
                    mainContent
                }
            }
            .navigationTitle("Расписания сна")
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
            .alert("Разрешение на уведомления", isPresented: $showingPermissionAlert) {
                Button("Настройки") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Для работы расписаний сна необходимо разрешение на уведомления. Перейдите в Настройки → BabySounds → Уведомления и включите их.")
            }
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                if let error = scheduleManager.lastError {
                    Text(error.localizedDescription)
                }
            }
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
                Text("Нет расписаний сна")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Создайте расписание для автоматического запуска убаюкивающих звуков в нужное время")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: addScheduleAction) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Создать расписание")
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
            // Уведомления секция
            if !scheduleManager.isNotificationPermissionGranted {
                notificationPermissionSection
            }
            
            // Следующее событие
            if let nextEvent = scheduleManager.nextScheduledEvent {
                nextEventSection(nextEvent)
            }
            
            // Premium баннер для бесплатных пользователей
            if !premiumManager.hasFeature(.sleepSchedules) {
                premiumSection
            }
            
            // Список расписаний
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
                    Text("Уведомления отключены")
                        .font(.headline)
                    
                    Text("Включите уведомления для работы расписаний")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Включить") {
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
        Section("Следующее событие") {
            HStack {
                Image(systemName: event.type == "reminder" ? "bell" : "moon.zzz")
                    .foregroundColor(event.type == "reminder" ? .orange : .blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.schedule.name)
                        .font(.headline)
                    
                    HStack {
                        Text(event.type == "reminder" ? "Напоминание" : "Время сна")
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
                title: "Безлимитные расписания",
                description: "Создавайте неограниченное количество расписаний сна с гибкими настройками",
                icon: "moon.zzz",
                action: {
                    parentGateManager.requestAccess(.paywall) { granted in
                        if granted {
                            // Show Paywall
                            // TODO: Integration with PaywallView
                        }
                    }
                }
            )
        }
    }
    
    // MARK: - Schedules Section
    
    private var schedulesSection: some View {
        Section("Мои расписания") {
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
            parentGateManager.requestAccess(.paywall) { granted in
                if granted {
                    // TODO: Show Paywall
                }
            }
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
            return "сейчас"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "через \(minutes) мин"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "через \(hours) ч"
        } else {
            let days = Int(timeInterval / 86400)
            return "через \(days) д"
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
                        
                        Text("\(schedule.selectedSounds.count) звук(ов)")
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
            Button("Удалить", role: .destructive) {
                onDelete()
            }
            
            Button("Изменить") {
                onEdit()
            }
            .tint(.blue)
        }
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)
        
        if timeInterval < 60 {
            return "сейчас"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)м"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)ч"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)д"
        }
    }
}

// MARK: - Preview

struct SleepSchedulesView_Previews: PreviewProvider {
    static var previews: some View {
        SleepSchedulesView()
    }
} 