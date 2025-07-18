import SwiftUI

@main
struct MinimalBabySoundsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            // Sleep Tab
            VStack {
                Text("🌙 Sleep Sounds")
                    .font(.largeTitle)
                    .padding()
                
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        SoundCard(emoji: "🌧️", title: "Rain")
                        SoundCard(emoji: "🌊", title: "Ocean")
                    }
                    HStack(spacing: 20) {
                        SoundCard(emoji: "🔥", title: "Fire")
                        SoundCard(emoji: "🎵", title: "Lullaby")
                    }
                }
                .padding()
                
                Spacer()
            }
            .tabItem {
                Image(systemName: "moon.zzz")
                Text("Sleep")
            }
            
            // Playroom Tab
            VStack {
                Text("🎮 Playroom")
                    .font(.largeTitle)
                    .padding()
                
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        AnimalCard(emoji: "🐶", title: "Dog")
                        AnimalCard(emoji: "🐱", title: "Cat")
                    }
                    HStack(spacing: 20) {
                        AnimalCard(emoji: "🐄", title: "Cow")
                        AnimalCard(emoji: "🦁", title: "Lion")
                    }
                }
                .padding()
                
                Spacer()
            }
            .tabItem {
                Image(systemName: "gamecontroller")
                Text("Playroom")
            }
            
            // Favorites Tab
            VStack {
                Spacer()
                Image(systemName: "heart")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                Text("No Favorites")
                    .font(.title2)
                    .padding()
                Spacer()
            }
            .tabItem {
                Image(systemName: "heart")
                Text("Favorites")
            }
            
            // Settings Tab
            VStack {
                Text("⚙️ Settings")
                    .font(.largeTitle)
                    .padding()
                
                VStack(spacing: 15) {
                    SettingsRow(title: "Premium Upgrade", icon: "crown.fill")
                    SettingsRow(title: "Notifications", icon: "bell.fill")
                    SettingsRow(title: "Child Safety", icon: "shield.fill")
                    SettingsRow(title: "Help & Support", icon: "questionmark.circle.fill")
                }
                .padding()
                
                Spacer()
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
        }
    }
}

struct SoundCard: View {
    let emoji: String
    let title: String
    
    var body: some View {
        VStack {
            Text(emoji)
                .font(.system(size: 40))
            Text(title)
                .font(.headline)
        }
        .frame(width: 120, height: 100)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
        .onTapGesture {
            // Play sound action
        }
    }
}

struct AnimalCard: View {
    let emoji: String
    let title: String
    
    var body: some View {
        Button(action: {
            // Play animal sound
        }) {
            VStack {
                Text(emoji)
                    .font(.system(size: 50))
                Text(title)
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .frame(width: 120, height: 120)
            .background(Color.green.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(title)
                .font(.body)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
} 