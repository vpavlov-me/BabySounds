import SwiftUI
import PlaygroundSupport

struct ContentView: View {
    @State private var selectedTab = 0
    
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
    }
}

struct SleepView: View {
    let categories = [
        ("🌧️", "Rain"),
        ("🌊", "Ocean"),
        ("🔥", "Fire"),
        ("🎵", "Lullabies"),
        ("🌸", "Nature"),
        ("🚂", "Transport")
    ]
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                        CategoryCard(emoji: category.0, title: category.1)
                    }
                }
                .padding()
            }
            .navigationTitle("Sleep Sounds")
        }
    }
}

struct CategoryCard: View {
    let emoji: String
    let title: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 48))
            
            Text(title)
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

struct PlayroomView: View {
    let animals = [
        ("🐶", "Dog"),
        ("🐱", "Cat"),
        ("🐄", "Cow"),
        ("🦁", "Lion"),
        ("🐸", "Frog"),
        ("🐘", "Elephant")
    ]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    Button("👨‍👩‍👧‍👦 Exit") {
                        // Parent gate action
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
                        ForEach(Array(animals.enumerated()), id: \.offset) { index, animal in
                            AnimalButton(emoji: animal.0, title: animal.1)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

struct AnimalButton: View {
    let emoji: String
    let title: String
    
    var body: some View {
        Button(action: {
            // Play sound
        }) {
            VStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 64))
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blue, lineWidth: 2)
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

struct FavoritesView: View {
    var body: some View {
        NavigationView {
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
            .navigationTitle("Favorites")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Subscription") {
                    Button("Upgrade to Premium") {
                        // Show paywall
                    }
                    .foregroundColor(.orange)
                    
                    Button("Restore Purchases") {
                        // Restore purchases
                    }
                }
                
                Section("Safety") {
                    NavigationLink("Child Safety", destination: Text("Child Safety Settings"))
                }
                
                Section("App") {
                    NavigationLink("Theme", destination: Text("Theme Settings"))
                    NavigationLink("Notifications", destination: Text("Notification Settings"))
                }
                
                Section("Support") {
                    NavigationLink("Help & FAQ", destination: Text("Help & FAQ"))
                    NavigationLink("Privacy Policy", destination: Text("Privacy Policy"))
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// Set up the live view
PlaygroundPage.current.setLiveView(ContentView()) 