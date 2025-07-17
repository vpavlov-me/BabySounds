import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    @EnvironmentObject var soundCatalog: SoundCatalog
    @EnvironmentObject var premiumManager: PremiumManager
    
    @State private var selectedTab = 0
    @State private var showParentGate = false
    @State private var showPaywall = false
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
            
            #if DEBUG
            DataDebugView()
                .tabItem {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("Debug")
                }
                .tag(4)
            #endif
        }
        .onChange(of: selectedTab) { newTab in
            // Require parent gate for Settings tab (but not Debug in development)
            if newTab == 3 && !isParentGateValid() {
                showParentGate = true
                selectedTab = 0 // Reset to first tab
            }
        }
        .sheet(isPresented: $showParentGate) {
            ParentGateView(
                isPresented: $showParentGate,
                context: .settings,
                onSuccess: {
                    hasPassedParentGate = true
                    parentGateTimeout = Date().timeIntervalSince1970 + 300 // 5 minutes
                    selectedTab = 3 // Navigate to Settings
                }
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall)
        }
        .premiumGateAlert(premiumManager: premiumManager, showPaywall: $showPaywall)
        .overlay(
            // Safety notice overlay
            SafetyNoticeView()
                .allowsHitTesting(false) // Allow touches to pass through to main content
        )
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
    @EnvironmentObject var audioManager: AudioEngineManager
    
    private var categorySounds: [Sound] {
        soundCatalog.sounds.filter { $0.category == category }
    }
    
    var body: some View {
        Group {
            if categorySounds.isEmpty {
                // Show loading or empty state
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Loading sounds...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Total sounds available: \(soundCatalog.sounds.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(categorySounds) { sound in
                    NavigationLink(destination: SoundPlayerView(sound: sound)) {
                        EnhancedSoundListRow(sound: sound)
                    }
                    .disabled(sound.premium && !premiumManager.canPlayPremiumSound())
                    .opacity(sound.premium && !premiumManager.canPlayPremiumSound() ? 0.6 : 1.0)
                }
                .refreshable {
                    // Reload sounds from JSON
                    Task {
                        try? await soundCatalog.loadSoundsFromJSON()
                    }
                }
            }
        }
        .navigationTitle(category.localizedName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reload") {
                    Task {
                        try? await soundCatalog.loadSoundsFromJSON()
                    }
                }
                .font(.caption)
            }
        }
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

struct EnhancedSoundListRow: View {
    let sound: Sound
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var audioManager: AudioEngineManager
    @EnvironmentObject var soundCatalog: SoundCatalog
    
    private var isCurrentlyPlaying: Bool {
        audioManager.currentlyPlaying.values.contains { $0.soundId == sound.id }
    }
    
    private var isFavorite: Bool {
        soundCatalog.isFavorite(sound.id)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Color indicator
            Circle()
                .fill(sound.color.color)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            // Emoji and title
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sound.displayEmoji)
                        .font(.title2)
                    
                    Text(sound.titleKey)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if isCurrentlyPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                HStack(spacing: 8) {
                    // Category badge
                    Text(sound.category.localizedName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                    
                    // Premium badge
                    if sound.premium {
                        HStack(spacing: 2) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                            Text("Premium")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                    }
                    
                    // Loop indicator
                    if sound.loop {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                // Favorite button
                Button(action: {
                    toggleFavorite(sound: sound)
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .gray)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Premium badge for premium content
                if sound.premium {
                    PremiumBadge(isLocked: !premiumManager.canPlayPremiumSound())
                }
                
                // File status indicator
                Group {
                    if Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExt) != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private func toggleFavorite(sound: Sound) {
        if soundCatalog.isFavorite(sound.id) {
            soundCatalog.favorites.remove(sound.id)
        } else {
            // Check if user can add more favorites
            if !premiumManager.canAddFavorite(currentCount: soundCatalog.favorites.count) {
                premiumManager.requestAccess(to: .unlimitedFavorites)
                return
            }
            soundCatalog.favorites.insert(sound.id)
        }
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
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var audioManager: AudioEngineManager
    @State private var showPaywall = false
    
    private var favoriteSounds: [Sound] {
        soundCatalog.favoriteSounds
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
                        
                        Text("Add sounds to favorites by tapping the heart icon in sound lists")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Free user limitations info
                        if !subscriptionService.isPremium {
                            VStack(spacing: 8) {
                                Text("Free Plan: \(favoriteSounds.count)/\(maxFreeFavorites) favorites")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if favoriteSounds.count >= maxFreeFavorites {
                                    Text("Upgrade to Premium for unlimited favorites")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.top)
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        // Favorites limit info for free users
                        if !premiumManager.hasAccess(to: .unlimitedFavorites) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text("Favorites: \(favoriteSounds.count)/\(PremiumManager.Limits.maxFavoritesForFree)")
                                    .font(.caption)
                                
                                Spacer()
                                
                                if favoriteSounds.count >= PremiumManager.Limits.maxFavoritesForFree {
                                    Button("Upgrade for unlimited") {
                                        premiumManager.requestAccess(to: .unlimitedFavorites)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                        }
                        
                        List {
                            ForEach(favoriteSounds) { sound in
                                NavigationLink(destination: SoundPlayerView(sound: sound)) {
                                    FavoriteSoundRow(sound: sound)
                                }
                                .disabled(sound.premium && !premiumManager.canPlayPremiumSound())
                                .opacity(sound.premium && !premiumManager.canPlayPremiumSound() ? 0.6 : 1.0)
                            }
                            .onDelete(perform: removeFavorites)
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .toolbar {
                if !favoriteSounds.isEmpty {
                    EditButton()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(isPresented: $showPaywall)
            }
            .premiumGateAlert(premiumManager: premiumManager, showPaywall: $showPaywall)
        }
    }
    
    private func removeFavorites(at offsets: IndexSet) {
        for index in offsets {
            let sound = favoriteSounds[index]
            soundCatalog.toggleFavorite(sound.id)
        }
    }
}

struct FavoriteSoundRow: View {
    let sound: Sound
    @EnvironmentObject var soundCatalog: SoundCatalog
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var audioManager: AudioEngineManager
    
    var body: some View {
        HStack {
            EnhancedSoundListRow(sound: sound)
            
            Button(action: {
                soundCatalog.favorites.remove(sound.id) // Direct removal in favorites view
            }) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    @EnvironmentObject var premiumManager: PremiumManager
    @State private var showPaywall = false
    @State private var showParentGateForRestore = false
    
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
                        if ParentGateManager.isRecentlyPassed(for: .restore, within: 300) {
                            // Recently passed, proceed directly
                            Task {
                                try? await subscriptionService.restorePurchases()
                            }
                        } else {
                            // Require parent gate
                            showParentGateForRestore = true
                        }
                    }
                }
                
                // Premium Features Status
                if subscriptionService.isPremium {
                    Section("Premium Features") {
                        ForEach(PremiumManager.PremiumFeature.allCases, id: \.self) { feature in
                            PremiumFeatureCard(
                                feature: feature, 
                                isUnlocked: premiumManager.hasAccess(to: feature)
                            )
                        }
                    }
                }
                
                Section("Safety") {
                    NavigationLink("Child Safety", destination: SafetySettingsView())
                }
                
                Section("App") {
                    NavigationLink("Theme", destination: ThemeSettingsView())
                    NavigationLink("Notifications", destination: NotificationSettingsView())
                    
                    NavigationLink("Sleep Schedules", destination: SleepSchedulesView())
                    
                    if premiumManager.hasAccess(to: .offlinePacks) {
                        NavigationLink("Offline Packs", destination: OfflinePacksView())
                    }
                }
                
                Section("Support") {
                    NavigationLink("Help & FAQ", destination: EnhancedHelpView())
                    NavigationLink("Privacy Policy", destination: PrivacyPolicyView())
                    NavigationLink("Terms of Service", destination: TermsOfServiceView())
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall)
        }
        .sheet(isPresented: $showParentGateForRestore) {
            ParentGateView(
                isPresented: $showParentGateForRestore,
                context: .restore,
                onSuccess: {
                    Task {
                        try? await subscriptionService.restorePurchases()
                    }
                }
            )
        }
        .premiumGateAlert(premiumManager: premiumManager, showPaywall: $showPaywall)
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

// NotificationSettingsView is now implemented in NotificationPermissionManager.swift

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

// HelpView is now implemented in SafeLinkWrapper.swift as EnhancedHelpView

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
        .environmentObject(PremiumManager(subscriptionService: SubscriptionServiceSK2()))
} 