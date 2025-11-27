import SwiftUI

// MARK: - SleepScheduleEditView

struct SleepScheduleEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scheduleManager = SleepScheduleManager.shared
    @StateObject private var soundCatalog = SoundCatalog.shared

    let originalSchedule: SleepSchedule?

    @State private var name: String
    @State private var isEnabled: Bool
    @State private var bedTime: Date
    @State private var wakeTime: Date
    @State private var selectedDays: Set<Weekday>
    @State private var reminderMinutes: Int
    @State private var selectedSounds: [String]
    @State private var autoFadeMinutes: Int

    @State private var showingSoundSelection = false
    @State private var isSaving = false
    @State private var showingError = false
    @State private var lastError: Error?

    // MARK: - Initialization

    init(schedule: SleepSchedule?) {
        originalSchedule = schedule

        if let schedule = schedule {
            _name = State(initialValue: schedule.name)
            _isEnabled = State(initialValue: schedule.isEnabled)
            _bedTime = State(initialValue: schedule.bedTime)
            _wakeTime = State(initialValue: schedule.wakeTime)
            _selectedDays = State(initialValue: schedule.selectedDays)
            _reminderMinutes = State(initialValue: schedule.reminderMinutes)
            _selectedSounds = State(initialValue: schedule.selectedSounds)
            _autoFadeMinutes = State(initialValue: schedule.autoFadeMinutes)
        } else {
            _name = State(initialValue: "My Sleep Schedule")
            _isEnabled = State(initialValue: true)
            _bedTime = State(initialValue: Calendar.current
                .date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date())
            _wakeTime = State(initialValue: Calendar.current
                .date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date())
            _selectedDays = State(initialValue: Set(Weekday.allCases))
            _reminderMinutes = State(initialValue: 30)
            _selectedSounds = State(initialValue: [])
            _autoFadeMinutes = State(initialValue: 45)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                basicSettingsSection
                timeSettingsSection
                daysSection
                soundsSection
                advancedSection
            }
            .navigationTitle(originalSchedule == nil ? "New Schedule" : "Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSchedule()
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingSoundSelection) {
                SoundSelectionView(selectedSounds: $selectedSounds)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                if let error = lastError {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Basic Settings Section

    private var basicSettingsSection: some View {
        Section("Basic Settings") {
            HStack {
                Text("Name")
                Spacer()
                TextField("Schedule name", text: $name)
                    .multilineTextAlignment(.trailing)
            }

            Toggle("Enabled", isOn: $isEnabled)
        }
    }

    // MARK: - Time Settings Section

    private var timeSettingsSection: some View {
        Section("Time") {
            DatePicker("Bedtime", selection: $bedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(CompactDatePickerStyle())

            DatePicker("Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(CompactDatePickerStyle())

            HStack {
                Text("Reminder")
                Spacer()
                Picker("", selection: $reminderMinutes) {
                    Text("5 min").tag(5)
                    Text("10 min").tag(10)
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                    Text("45 min").tag(45)
                    Text("60 min").tag(60)
                }
                .pickerStyle(MenuPickerStyle())
            }
        } footer: {
            Text("A reminder notification will be sent before bedtime")
        }
    }

    // MARK: - Days Section

    private var daysSection: some View {
        Section("Weekdays") {
            VStack(spacing: 12) {
                // Quick selection buttons
                HStack {
                    quickSelectButton("All Days", days: Set(Weekday.allCases))
                    quickSelectButton("Weekdays", days: [.monday, .tuesday, .wednesday, .thursday, .friday])
                    quickSelectButton("Weekends", days: [.saturday, .sunday])
                }

                // Individual day toggles
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(Weekday.allCases.sorted(), id: \.self) { day in
                        Toggle(day.name, isOn: Binding(
                            get: { selectedDays.contains(day) },
                            set: { isSelected in
                                if isSelected {
                                    selectedDays.insert(day)
                                } else {
                                    selectedDays.remove(day)
                                }
                            }
                        ))
                        .toggleStyle(CheckboxToggleStyle())
                    }
                }
            }
            .padding(.vertical, 4)
        } footer: {
            Text("Select the days when the schedule should be active")
        }
    }

    // MARK: - Sounds Section

    private var soundsSection: some View {
        Section("Sounds") {
            Button(action: { showingSoundSelection = true }) {
                HStack {
                    Text("Select Sounds")
                    Spacer()

                    if selectedSounds.isEmpty {
                        Text("None selected")
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(selectedSounds.count) sound(s)")
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if !selectedSounds.isEmpty {
                ForEach(selectedSounds.prefix(3), id: \.self) { soundId in
                    if let sound = soundCatalog.sounds.first(where: { $0.id == soundId }) {
                        HStack {
                            Circle()
                                .fill(Color(sound.color))
                                .frame(width: 12, height: 12)

                            Text(sound.name)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()
                        }
                        .padding(.leading, 16)
                    }
                }

                if selectedSounds.count > 3 {
                    Text("... and \(selectedSounds.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 16)
                }
            }
        } footer: {
            Text("Selected sounds will play automatically at the scheduled time")
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        Section("Advanced") {
            HStack {
                Text("Auto Fade")
                Spacer()
                Picker("", selection: $autoFadeMinutes) {
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                    Text("45 min").tag(45)
                    Text("60 min").tag(60)
                    Text("90 min").tag(90)
                    Text("120 min").tag(120)
                }
                .pickerStyle(MenuPickerStyle())
            }
        } footer: {
            Text("Sounds will automatically fade out after the selected time")
        }
    }

    // MARK: - Quick Select Button

    private func quickSelectButton(_ title: String, days: Set<Weekday>) -> some View {
        Button(title) {
            selectedDays = days
        }
        .buttonStyle(BorderedButtonStyle())
        .controlSize(.small)
        .tint(selectedDays == days ? .blue : .gray)
    }

    // MARK: - Save Action

    private func saveSchedule() {
        isSaving = true

        Task {
            do {
                let schedule = SleepSchedule(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    isEnabled: isEnabled,
                    bedTime: bedTime,
                    wakeTime: wakeTime,
                    selectedDays: selectedDays,
                    reminderMinutes: reminderMinutes,
                    selectedSounds: selectedSounds,
                    autoFadeMinutes: autoFadeMinutes
                )

                if let originalSchedule = originalSchedule {
                    // Create updated schedule preserving the original ID and creation date
                    let updatedSchedule = SleepSchedule(
                        id: originalSchedule.id,
                        name: schedule.name,
                        isEnabled: schedule.isEnabled,
                        bedTime: schedule.bedTime,
                        wakeTime: schedule.wakeTime,
                        selectedDays: schedule.selectedDays,
                        reminderMinutes: schedule.reminderMinutes,
                        selectedSounds: schedule.selectedSounds,
                        autoFadeMinutes: schedule.autoFadeMinutes,
                        dateCreated: originalSchedule.dateCreated
                    )

                    try await scheduleManager.updateSchedule(updatedSchedule)
                } else {
                    try await scheduleManager.addSchedule(schedule)
                }

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    lastError = error
                    showingError = true
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - CheckboxToggleStyle

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }

            configuration.label
                .onTapGesture {
                    configuration.isOn.toggle()
                }

            Spacer()
        }
    }
}

// MARK: - SoundSelectionView

struct SoundSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var soundCatalog = SoundCatalog.shared
    @StateObject private var premiumManager = PremiumManager.shared

    @Binding var selectedSounds: [String]
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredSounds, id: \.id) { sound in
                    SoundSelectionRow(
                        sound: sound,
                        isSelected: selectedSounds.contains(sound.id)
                    ) { isSelected in
                        if isSelected {
                            selectedSounds.append(sound.id)
                        } else {
                            selectedSounds.removeAll { $0 == sound.id }
                        }
                    }
                }
            }
            .navigationTitle("Select Sounds")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search sounds...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var filteredSounds: [Sound] {
        let sounds = soundCatalog.sounds

        if searchText.isEmpty {
            return sounds
        } else {
            return sounds.filter { sound in
                sound.name.localizedCaseInsensitiveContains(searchText) ||
                    sound.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - SoundSelectionRow

struct SoundSelectionRow: View {
    let sound: Sound
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    @StateObject private var premiumManager = PremiumManager.shared

    var body: some View {
        HStack {
            // Color indicator
            Circle()
                .fill(Color(sound.color))
                .frame(width: 16, height: 16)

            // Sound info
            VStack(alignment: .leading, spacing: 2) {
                Text(sound.name)
                    .font(.headline)

                Text(sound.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Premium badge
            if sound.isPremium && !premiumManager.hasSubscription {
                Image(systemName: "crown.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }

            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title2)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Premium check
            if sound.isPremium && !premiumManager.hasSubscription {
                premiumManager.requestAccess(to: .premiumSounds)
                return
            }

            onToggle(!isSelected)
        }
        .opacity(sound.isPremium && !premiumManager.hasSubscription ? 0.6 : 1.0)
    }
}

// MARK: - SleepScheduleEditView_Previews

struct SleepScheduleEditView_Previews: PreviewProvider {
    static var previews: some View {
        SleepScheduleEditView(schedule: nil)
    }
}
