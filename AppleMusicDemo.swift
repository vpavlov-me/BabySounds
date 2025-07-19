import SwiftUI

// MARK: - Demo App

@main
struct AppleMusicDemoApp: App {
    var body: some Scene {
        WindowGroup {
            AppleMusicDemoView()
        }
    }
}

// MARK: - Main Demo View

struct AppleMusicDemoView: View {
    @State private var selectedTab = 0
    @State private var showNowPlaying = false
    @State private var currentlyPlaying: DemoSound? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main TabView
            TabView(selection: $selectedTab) {
                // Sleep Tab
                NavigationView {
                    DemoSleepView(currentlyPlaying: $currentlyPlaying)
                }
                .tabItem {
                    Image(systemName: "moon.zzz.fill")
                    Text("Sleep")
                }
                .tag(0)
                
                // Playroom Tab
                DemoPlayroomView(currentlyPlaying: $currentlyPlaying)
                    .tabItem {
                        Image(systemName: "gamecontroller.fill")
                        Text("Playroom")
                    }
                    .tag(1)
                
                // Favorites Tab
                NavigationView {
                    DemoFavoritesView()
                }
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
                .tag(2)
                
                // Schedules Tab
                NavigationView {
                    DemoSchedulesView()
                }
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Schedules")
                }
                .tag(3)
                
                // Settings Tab
                NavigationView {
                    DemoSettingsView()
                }
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
            }
            .tint(.pink)
            
            // Mini Player
            if let sound = currentlyPlaying {
                DemoMiniPlayer(sound: sound, showNowPlaying: $showNowPlaying, currentlyPlaying: $currentlyPlaying)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentlyPlaying != nil)
        .fullScreenCover(isPresented: $showNowPlaying) {
            if let sound = currentlyPlaying {
                DemoNowPlayingView(sound: sound, isPresented: $showNowPlaying, currentlyPlaying: $currentlyPlaying)
            }
        }
    }
}

// MARK: - Demo Models

struct DemoSound: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let category: String
    let emoji: String
    let colors: [Color]
    let isPremium: Bool
    
    static let samples = [
        DemoSound(title: "White Noise", category: "White Noise", emoji: "🌬️", colors: [.gray.opacity(0.8), .white], isPremium: false),
        DemoSound(title: "Ocean Waves", category: "Nature", emoji: "🌊", colors: [.blue.opacity(0.8), .cyan.opacity(0.6)], isPremium: false),
        DemoSound(title: "Forest Rain", category: "Nature", emoji: "🌲", colors: [.green.opacity(0.8), .blue.opacity(0.6)], isPremium: true),
        DemoSound(title: "Pink Noise", category: "Pink Noise", emoji: "🌸", colors: [.pink.opacity(0.8), .purple.opacity(0.6)], isPremium: true),
        DemoSound(title: "Heartbeat", category: "Womb Sounds", emoji: "❤️", colors: [.red.opacity(0.6), .pink.opacity(0.8)], isPremium: false),
        DemoSound(title: "Fan", category: "Fan Sounds", emoji: "💨", colors: [.blue.opacity(0.6), .cyan.opacity(0.8)], isPremium: false)
    ]
}

// MARK: - Sleep View

struct DemoSleepView: View {
    @Binding var currentlyPlaying: DemoSound?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // Hero section
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Sleep Sounds")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Peaceful sounds to help you relax and fall asleep")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 16)
                    
                    // Quick access
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(DemoSound.samples.prefix(3)), id: \.id) { sound in
                                DemoQuickAccessButton(sound: sound, currentlyPlaying: $currentlyPlaying)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 24)
                
                // Categories
                let categories = Dictionary(grouping: DemoSound.samples, by: \.category)
                ForEach(Array(categories.keys.sorted()), id: \.self) { category in
                    Section {
                        ForEach(categories[category] ?? [], id: \.id) { sound in
                            DemoSoundCell(sound: sound, currentlyPlaying: $currentlyPlaying)
                        }
                    } header: {
                        HStack {
                            Text(category)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                    }
                }
                
                Spacer().frame(height: 100)
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Sleep")
    }
}

// MARK: - Sound Cell

struct DemoSoundCell: View {
    let sound: DemoSound
    @Binding var currentlyPlaying: DemoSound?
    
    var isPlaying: Bool {
        currentlyPlaying?.id == sound.id
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: sound.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text(sound.emoji)
                    .font(.title2)
            }
            .frame(width: 44, height: 44)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sound.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if sound.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("Premium")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                    }
                }
                
                Text(sound.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Playing indicator
            if isPlaying {
                DemoPlayingIndicator()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if isPlaying {
                    currentlyPlaying = nil
                } else {
                    currentlyPlaying = sound
                }
            }
        }
    }
}

// MARK: - Mini Player

struct DemoMiniPlayer: View {
    let sound: DemoSound
    @Binding var showNowPlaying: Bool
    @Binding var currentlyPlaying: DemoSound?
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: 0.3, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .pink))
                .scaleEffect(y: 0.5)
            
            // Mini player content
            HStack(spacing: 12) {
                // Artwork
                Button {
                    showNowPlaying = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: sound.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        
                        Text(sound.emoji)
                            .font(.title2)
                    }
                    .frame(width: 44, height: 44)
                }
                
                // Sound info
                Button {
                    showNowPlaying = true
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sound.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(sound.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Play/Pause button
                Button {
                    currentlyPlaying = nil
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.regularMaterial)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.y < -50 {
                        showNowPlaying = true
                    } else if value.translation.x < -100 {
                        currentlyPlaying = nil
                    }
                }
        )
    }
}

// MARK: - Helper Views

struct DemoPlayingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(.pink)
                    .frame(width: 3, height: isAnimating ? CGFloat.random(in: 8...16) : 8)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever()
                        .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .frame(width: 16, height: 16)
        .onAppear { isAnimating = true }
    }
}

struct DemoQuickAccessButton: View {
    let sound: DemoSound
    @Binding var currentlyPlaying: DemoSound?
    
    var body: some View {
        Button {
            currentlyPlaying = sound
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: sound.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    Text(sound.emoji)
                        .font(.title2)
                }
                
                Text(sound.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
    }
}

// MARK: - Placeholder Views

struct DemoPlayroomView: View {
    @Binding var currentlyPlaying: DemoSound?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("🎪")
                        .font(.system(size: 60))
                    
                    Text("Playroom")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Fun sounds for little ones")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(DemoSound.samples.filter { $0.category == "Nature" }, id: \.id) { sound in
                        DemoPlayroomTile(sound: sound, currentlyPlaying: $currentlyPlaying)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer(minLength: 100)
            }
        }
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.1), .pink.opacity(0.1), .orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct DemoPlayroomTile: View {
    let sound: DemoSound
    @Binding var currentlyPlaying: DemoSound?
    
    var body: some View {
        Button {
            currentlyPlaying = sound
        } label: {
            VStack(spacing: 16) {
                Text(sound.emoji)
                    .font(.system(size: 64))
                
                Text(sound.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .padding(20)
            .frame(width: 160, height: 160)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(colors: sound.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            )
        }
    }
}

struct DemoFavoritesView: View {
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.pink.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "heart")
                        .font(.system(size: 40))
                        .foregroundColor(.pink.opacity(0.6))
                }
                
                VStack(spacing: 8) {
                    Text("No Favorites Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Swipe right on sounds to add them to your favorites")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Favorites")
    }
}

struct DemoSchedulesView: View {
    var body: some View {
        VStack(spacing: 24) {
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
                    
                    Text("Create sleep schedules to automatically play sounds at specific times")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Schedules")
    }
}

struct DemoSettingsView: View {
    var body: some View {
        List {
            Section("Account") {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.orange)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upgrade to Premium")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text("Unlock all sounds and features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section("Audio") {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.pink)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Safe Volume")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text("WHO-compliant hearing protection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Settings")
    }
}

struct DemoNowPlayingView: View {
    let sound: DemoSound
    @Binding var isPresented: Bool
    @Binding var currentlyPlaying: DemoSound?
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: sound.colors + [Color.black.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button { } label: {
                            Image(systemName: "airplayaudio")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Artwork
                    VStack(spacing: 24) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(colors: sound.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Text(sound.emoji)
                                .font(.system(size: min(geometry.size.width * 0.3, 120)))
                        }
                        .frame(width: 300, height: 300)
                        .scaleEffect(1.0 - abs(dragOffset.height) / 1000)
                        
                        VStack(spacing: 8) {
                            Text(sound.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(sound.category)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    // Controls
                    VStack(spacing: 32) {
                        HStack(spacing: 60) {
                            Button { } label: {
                                Image(systemName: "heart")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                            }
                            
                            Button {
                                currentlyPlaying = nil
                                isPresented = false
                            } label: {
                                Image(systemName: "pause.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            
                            Button { } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .font(.title)
                                        .foregroundColor(.white)
                                    
                                    Text("∞")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .frame(width: 44, height: 44)
                            }
                        }
                        
                        // Volume control
                        HStack {
                            Image(systemName: "speaker.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Slider(value: .constant(0.7), in: 0...1)
                                .accentColor(.white)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer(minLength: 32)
                }
                .offset(y: dragOffset.height)
            }
        }
        .preferredColorScheme(.dark)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.y > 0 {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    if value.translation.y > 200 {
                        isPresented = false
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }
} 