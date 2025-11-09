import SwiftUI

// MARK: - SearchView

struct SearchView: View {
    @EnvironmentObject var soundCatalog: SoundCatalog
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var premiumManager: PremiumManager

    @State private var searchText = ""
    @State private var selectedCategory: SoundCategory = .all
    @Environment(\.dismiss) private var dismiss

    var filteredSounds: [Sound] {
        var sounds = soundCatalog.sounds

        // Filter by category
        if selectedCategory != .all {
            sounds = sounds.filter { $0.category == selectedCategory }
        }

        // Filter by search text
        if !searchText.isEmpty {
            sounds = sounds.filter { sound in
                sound.name.localizedCaseInsensitiveContains(searchText) ||
                    sound.category.localizedName.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return sounds.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(SoundCategory.allCases, id: \.self) { category in
                            CategoryFilterChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation(.spring()) {
                                    selectedCategory = category
                                }
                                HapticManager.shared.selection()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))

                Divider()

                // Results
                if filteredSounds.isEmpty {
                    emptyState
                } else {
                    List(filteredSounds) { sound in
                        NavigationLink(destination: SoundPlayerView(sound: sound)) {
                            EnhancedSoundListRow(sound: sound)
                        }
                        .disabled(sound.premium && !premiumManager.canPlayPremiumSound())
                        .opacity(sound.premium && !premiumManager.canPlayPremiumSound() ? 0.6 : 1.0)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search Sounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search sounds...")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text(searchText.isEmpty ? "Start Searching" : "No Sounds Found")
                .font(.title2)
                .fontWeight(.medium)

            if !searchText.isEmpty {
                Text("Try different keywords or categories")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Search for sounds by name or category")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - CategoryFilterChip

struct CategoryFilterChip: View {
    let category: SoundCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.emoji)
                    .font(.caption)

                Text(category.localizedName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SearchView()
        .environmentObject(SoundCatalog())
        .environmentObject(AudioEngineManager.shared)
        .environmentObject(PremiumManager.shared)
}
