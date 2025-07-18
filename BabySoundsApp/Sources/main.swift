import SwiftUI
import BabySoundsCore
import BabySoundsUI

/// Entry point для BabySounds iOS приложения
/// 
/// Современное приложение для детского сна с безопасным звуковым сопровождением
@main
struct BabySoundsAppMain {
    static func main() {
        BabySoundsApp.main()
    }
}

/// Основное приложение BabySounds
struct BabySoundsApp: App {
    /// Состояние приложения
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    setupApplication()
                }
        }
    }
    
    /// Инициализация приложения
    private func setupApplication() {
        print("🍼 BabySounds v\(BabySoundsCore.version) starting...")
        print("🎨 UI Framework v\(BabySoundsUI.version) loaded")
        
        // Настройка аудио сессии при запуске
        Task {
            await appState.initializeAudioSystem()
        }
    }
}

/// Основное содержимое приложения
struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Заголовок
                headerView
                
                // Основной контент
                mainContent
                
                Spacer()
                
                // Footer с версией
                footerView
            }
            .padding()
            .navigationTitle("Baby Sounds")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("🍼")
                .font(.system(size: 60))
            
            Text("Baby Sounds")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Peaceful sleep for your little one")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 16) {
            // Демонстрация UI компонента из BabySoundsUI
            BabyButton(title: "Play Sample Sound") {
                playDemoSound()
            }
            
            // Статус аудио системы
            VStack(spacing: 8) {
                Text("Audio System Status")
                    .font(.headline)
                
                HStack {
                    Circle()
                        .fill(appState.isAudioReady ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Text(appState.isAudioReady ? "Ready" : "Initializing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.softGray)
            .cornerRadius(BabyDesign.cornerRadius)
        }
    }
    
    private var footerView: some View {
        VStack(spacing: 4) {
            Text("BabySounds v\(BabySoundsCore.version)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("Designed for children's safety")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func playDemoSound() {
        print("🔊 Playing demo sound...")
        // Здесь будет реализация воспроизведения звука
        // через BabySoundsCore
    }
}

/// Состояние приложения
@MainActor
class AppState: ObservableObject {
    @Published var isAudioReady = false
    @Published var currentlyPlaying: [String] = []
    
    /// Инициализация аудио системы
    func initializeAudioSystem() async {
        print("🎵 Initializing audio system...")
        
        // Симуляция инициализации аудио
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
        
        isAudioReady = true
        print("✅ Audio system ready")
    }
} 