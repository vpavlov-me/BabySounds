# BabySoundsCore 🎵

**Core business logic for BabySounds app without UI dependencies**

## 🎯 Overview

BabySoundsCore contains the essential business logic for the BabySounds app:
- Audio engine management (AVAudioEngine)
- Data models and services
- Premium subscription logic
- Child safety systems
- Utilities and extensions

## 🏗 Architecture

The package is organized by functional domains:

```
BabySoundsCore/
├── Audio/              # Audio engine and management
│   ├── AudioEngineCore.swift
│   ├── BackgroundAudioManager.swift
│   └── SafeVolumeManager.swift
├── Data/               # Data services and managers
│   ├── SoundCatalog.swift
│   ├── PremiumManager.swift
│   ├── SleepScheduleManager.swift
│   └── ParentGateManager.swift
├── Models/             # Data models
│   ├── Sound.swift
│   └── SleepSchedule.swift
├── Extensions/         # Swift extensions
└── Utils/             # Utility functions
```

## 🎵 Audio Features

### Safe Audio Engine
- **AVAudioEngine** based architecture
- **Multi-track mixing** (up to 4 concurrent sounds)
- **WHO-compliant volume limits** (85dB/70% maximum)
- **Background playback** support
- **Fade-in/out effects** with configurable duration

### Usage Example
```swift
import BabySoundsCore

// Initialize audio engine
let audioEngine = AudioEngineCore()
try await audioEngine.startEngine()

// Play sound with safety limits
try await audioEngine.playSound("white_noise", volume: 0.5)

// Safe volume management
let volumeManager = SafeVolumeManager()
volumeManager.checkSafetyLimits(volume: 0.8) // Returns safe level
```

## 💎 Premium Features

### StoreKit 2 Integration
- **Monthly/Annual subscriptions** with 7-day free trial
- **Feature gating system** for premium content
- **Receipt validation** and transaction management
- **Real-time status updates**

### Premium Feature Gates
```swift
let premiumManager = PremiumManager()

// Check premium status
if await premiumManager.isPremium {
    // Access premium features
    allowUnlimitedTimers()
    enableAllSounds()
} else {
    // Show premium gate
    showPremiumUpgrade()
}
```

## 🔒 Child Safety

### Parental Gate System
- **Math challenge verification** for adult actions
- **Multiple challenge types** (addition, subtraction, multiplication)
- **Configurable difficulty levels**
- **TTS support** for accessibility

### Volume Safety
- **WHO hearing safety guidelines** compliance
- **Automatic volume limiting** to 85dB equivalent
- **Listening session tracking** with break reminders
- **Parental volume controls**

### Usage Example
```swift
let parentGate = ParentGateManager()

// Show verification for settings access
let challenge = parentGate.generateChallenge(.settings)
let isAuthorized = await parentGate.verifyAnswer(challenge, answer: userAnswer)

if isAuthorized {
    // Allow settings access
    showSettings()
}
```

## 📊 Data Management

### Sound Catalog
- **JSON-driven sound library** with metadata
- **Category organization** (white noise, nature, etc.)
- **Premium content marking**
- **Accessibility information**

### Sleep Schedules
- **Local notification scheduling**
- **Weekday-based recurrence**
- **Premium limits** (1 free, unlimited premium)
- **Sound selection per schedule**

## 🧪 Testing

The package includes comprehensive test coverage:

```bash
# Run tests
swift test

# Test specific modules
swift test --filter AudioEngineTests
swift test --filter PremiumManagerTests
```

### Test Structure
- **Unit tests** for business logic
- **Mock objects** for external dependencies
- **StoreKit testing** with local configuration
- **Audio engine testing** with simulated files

## 📦 Integration

### Adding to Your Project

**Swift Package Manager:**
```swift
dependencies: [
    .package(url: "https://github.com/vpavlov-me/BabySounds", from: "1.0.0")
]
```

**In your target:**
```swift
.target(
    name: "YourApp",
    dependencies: ["BabySoundsCore"]
)
```

### Requirements
- **iOS 17.0+**
- **Swift 6.0+**
- **Xcode 15.4+**

## 🎯 Kids Category Compliance

This package is designed for **Kids Category** apps with strict compliance:

### COPPA Safe
- **No data collection** from children
- **No external analytics** or tracking
- **Local-only data storage**
- **Parental consent flows**

### Accessibility First
- **VoiceOver support** throughout
- **64pt minimum touch targets**
- **High contrast color support**
- **Text-to-speech integration**

### Hearing Safety
- **WHO guidelines** implementation
- **Volume limiting** at system level
- **Break reminders** for extended listening
- **Parental volume controls**

## 🔧 Advanced Usage

### Custom Audio Engine Configuration
```swift
let audioEngine = AudioEngineCore()

// Configure for optimal children's content
audioEngine.configure(
    maxConcurrentTracks: 3,
    safeVolumeLimit: 0.7,
    fadeInDuration: 30.0,
    fadeOutDuration: 15.0
)

// Background audio setup
let backgroundManager = BackgroundAudioManager()
backgroundManager.enableNowPlaying(
    title: "Baby Sleep Sounds",
    artist: "BabySounds"
)
```

### Premium Feature Implementation
```swift
// Define premium features
enum PremiumFeature: String, CaseIterable {
    case unlimitedTimers = "unlimited_timers"
    case allSounds = "all_sounds" 
    case sleepSchedules = "sleep_schedules"
    case backgroundPlay = "background_play"
}

// Check feature access
extension PremiumManager {
    func hasAccess(to feature: PremiumFeature) async -> Bool {
        return await isPremium || feature.isFreeFeature
    }
}
```

## 🚀 Performance

### Optimizations
- **Lazy loading** of audio buffers
- **Memory-efficient** sound caching
- **Background thread** audio processing
- **Minimal main thread** blocking

### Memory Management
- **Automatic cleanup** of unused sounds
- **Buffer pooling** for frequently used sounds
- **Weak references** to prevent retain cycles
- **Proper disposal** of audio resources

## 📱 Platform Support

- **iPhone** (iOS 17.0+)
- **iPad** (iOS 17.0+)
- **Background audio** support
- **CarPlay** ready (future)
- **Apple Watch** compatible (future)

---

**Ready for production Kids Category apps! 🍼** 