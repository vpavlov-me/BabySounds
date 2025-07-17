import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    @EnvironmentObject var soundCatalog: SoundCatalog
    
    @State private var selectedTab = 0
    @State private var showParentGate = false
    @AppStorage("hasPassedParentGate") private var hasPassedParentGate = false
    @AppStorage("parentGateTimeout") private var parentGateTimeout: Double = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SleepView()
                .tabItem {
                    Image(systemName: "moon.zzz")
                    Text("Sleep")
                }
                .tag(0)
            
            PlayroomView()
                .tabItem {
                    Image(systemName: "gamecontroller")
                    Text("Playroom")
                }
                .tag(1)
            
            FavoritesView()
                .tabItem {
                    Image(systemName: "heart")
                    Text("Favorites")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .onChange(of: selectedTab) { newTab in
            // Require parent gate for Settings tab
            if newTab == 3 && !isParentGateValid() {
                showParentGate = true
                selectedTab = 0 // Reset to first tab
            }
        }
        .sheet(isPresented: $showParentGate) {
            ParentGateView(
                isPresented: $showParentGate,
                onSuccess: {
                    hasPassedParentGate = true
                    parentGateTimeout = Date().timeIntervalSince1970 + 300 // 5 minutes
                    selectedTab = 3 // Navigate to Settings
                }
            )
        }
    }
    
    private func isParentGateValid() -> Bool {
        hasPassedParentGate && Date().timeIntervalSince1970 < parentGateTimeout
    }
}

// MARK: - Sleep View

struct SleepView: View {
    @EnvironmentObject var soundCatalog: SoundCatalog
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(SoundCategory.allCases, id: \.self) { category in
                        NavigationLink(destination: CategorySoundsView(category: category)) {
                            CategoryCard(category: category)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Sleep Sounds")
        }
    }
}

struct CategoryCard: View {
    let category: SoundCategory
    
    var body: some View {
        VStack(spacing: 12) {
            Text(category.emoji)
                .font(.system(size: 48))
            
            Text(category.localizedName)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .frame(minHeight: 120)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct CategorySoundsView: View {
    let category: SoundCategory
    @EnvironmentObject var soundCatalog: SoundCatalog
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    
    private var categorySounds: [Sound] {
        soundCatalog.sounds.filter { $0.category == category }
    }
    
    var body: some View {
        List(categorySounds) { sound in
            NavigationLink(destination: SoundPlayerView(sound: sound)) {
                SoundListRow(sound: sound)
            }
            .disabled(sound.premium && !subscriptionService.isPremium)
            .opacity(sound.premium && !subscriptionService.isPremium ? 0.6 : 1.0)
        }
        .navigationTitle(category.localizedName)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct SoundListRow: View {
    let sound: Sound
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    
    var body: some View {
        HStack {
            Text(sound.displayEmoji)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(sound.titleKey)
                    .font(.headline)
                
                if sound.premium {
                    Text("Premium")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if sound.premium && !subscriptionService.isPremium {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Playroom View

struct PlayroomView: View {
    @EnvironmentObject var soundCatalog: SoundCatalog
    @State private var showParentGate = false
    
    private let playgroundSounds: [Sound] = [
        // TODO: Filter sounds appropriate for children's playroom
    ]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // Parent Gate Button
                HStack {
                    Spacer()
                    Button("👨‍👩‍👧‍👦 Exit") {
                        showParentGate = true
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                .padding()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(soundCatalog.sounds.prefix(6), id: \.id) { sound in
                            PlayroomSoundButton(sound: sound)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showParentGate) {
            ParentGateView(isPresented: $showParentGate) {}
        }
    }
}

struct PlayroomSoundButton: View {
    let sound: Sound
    @EnvironmentObject var audioManager: AudioEngineManager
    
    var body: some View {
        Button(action: {
            audioManager.playSound(sound)
        }) {
            VStack(spacing: 16) {
                Text(sound.displayEmoji)
                    .font(.system(size: 64))
                
                Text(sound.titleKey)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(sound.color.color.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(sound.color.color, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Favorites View

struct FavoritesView: View {
    @EnvironmentObject var soundCatalog: SoundCatalog
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    
    private var favoriteSounds: [Sound] {
        soundCatalog.sounds.filter { soundCatalog.favorites.contains($0.id) }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if favoriteSounds.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        
                        Text("No Favorite Sounds")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Add sounds to favorites by tapping the heart icon")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List(favoriteSounds) { sound in
                        NavigationLink(destination: SoundPlayerView(sound: sound)) {
                            SoundListRow(sound: sound)
                        }
                        .disabled(sound.premium && !subscriptionService.isPremium)
                        .opacity(sound.premium && !subscriptionService.isPremium ? 0.6 : 1.0)
                    }
                }
            }
            .navigationTitle("Favorites")
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    @State private var showPaywall = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Subscription") {
                    if subscriptionService.isPremium {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                            Text("Premium Active")
                            Spacer()
                            Text("✓")
                                .foregroundColor(.green)
                        }
                    } else {
                        Button("Upgrade to Premium") {
                            showPaywall = true
                        }
                        .foregroundColor(.orange)
                    }
                    
                    Button("Restore Purchases") {
                        Task {
                            try? await subscriptionService.restorePurchases()
                        }
                    }
                }
                
                Section("App") {
                    NavigationLink("Theme", destination: ThemeSettingsView())
                    NavigationLink("Notifications", destination: NotificationSettingsView())
                    
                    if subscriptionService.isPremium {
                        NavigationLink("Schedules", destination: ScheduleSettingsView())
                        NavigationLink("Offline Packs", destination: OfflinePacksView())
                    }
                }
                
                Section("Support") {
                    NavigationLink("Help & FAQ", destination: HelpView())
                    NavigationLink("Privacy Policy", destination: PrivacyPolicyView())
                    NavigationLink("Terms of Service", destination: TermsOfServiceView())
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall)
        }
    }
}

// MARK: - Placeholder Views

struct ThemeSettingsView: View {
    var body: some View {
        List {
            Text("Theme settings coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Theme")
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        List {
            Text("Notification settings coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Notifications")
    }
}

struct ScheduleSettingsView: View {
    var body: some View {
        List {
            Text("Schedule settings coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Schedules")
    }
}

struct OfflinePacksView: View {
    var body: some View {
        List {
            Text("Offline packs coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Offline Packs")
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Text("Help & FAQ coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Help")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy content will be loaded here...")
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            Text("Terms of Service content will be loaded here...")
                .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

#Preview {
    ContentView()
        .environmentObject(AudioEngineManager.shared)
        .environmentObject(SubscriptionServiceSK2())
        .environmentObject(SoundCatalog())
} 