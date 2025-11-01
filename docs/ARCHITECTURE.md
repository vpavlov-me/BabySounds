---
layout: default
title: Architecture Guide
---

# BabySounds Architecture Guide

This document describes the technical architecture of the BabySounds iOS application.

## Table of Contents

- [Overview](#overview)
- [Architecture Pattern](#architecture-pattern)
- [Project Structure](#project-structure)
- [Core Systems](#core-systems)
- [Data Flow](#data-flow)
- [Threading Model](#threading-model)
- [Audio Architecture](#audio-architecture)
- [State Management](#state-management)
- [Dependencies](#dependencies)

## Overview

BabySounds is built using modern iOS development practices with SwiftUI, Swift 6, and a modular architecture using Swift Package Manager.

### Key Characteristics
- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Concurrency**: Swift Concurrency (async/await)
- **Minimum iOS**: 17.0+
- **Package Manager**: Swift Package Manager (SPM)

### Code Statistics
- **12,907 lines** of Swift code
- **48 source files**
- **3 SPM packages** (BabySounds, BabySoundsCore, BabySoundsUI)

## Architecture Pattern

### MVVM (Model-View-ViewModel)

```
┌─────────────┐
│    View     │ ← SwiftUI Views
│  (SwiftUI)  │   User interface components
└──────┬──────┘
       │
       ↓
┌─────────────┐
│  ViewModel  │ ← ObservableObject
│ (@Published) │   Business logic, state
└──────┬──────┘
       │
       ↓
┌─────────────┐
│    Model    │ ← Structs/Classes
│   (Data)    │   Data structures
└─────────────┘
```

### Environment Objects

We use SwiftUI's environment system for dependency injection:

```swift
@main
struct BabySoundsApp: App {
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var premiumManager = PremiumManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioPlayer)
                .environmentObject(premiumManager)
        }
    }
}
```

## Project Structure

### Directory Layout

```
BabySounds/
├── BabySounds/Sources/BabySounds/
│   ├── App/
│   │   ├── BabySoundsApp.swift         # App entry point
│   │   └── ContentView.swift           # Root navigation
│   │
│   ├── Core/
│   │   ├── Audio/
│   │   │   ├── AudioEngineManager.swift    # (799 LOC)
│   │   │   ├── SafeVolumeManager.swift     # (477 LOC)
│   │   │   └── BackgroundAudioManager.swift # (504 LOC)
│   │   ├── Data/
│   │   │   ├── PremiumManager.swift
│   │   │   ├── ParentGateManager.swift
│   │   │   └── SleepScheduleManager.swift
│   │   └── Models/
│   │       ├── Sound.swift
│   │       ├── SoundCategory.swift
│   │       └── SleepSchedule.swift
│   │
│   ├── Features/
│   │   ├── Sleep/              # Sound library browsing
│   │   ├── Playroom/           # Child-friendly interface
│   │   ├── Favorites/          # Saved sounds
│   │   ├── Schedules/          # Sleep schedules
│   │   ├── Settings/           # App settings
│   │   ├── ParentalControls/   # Parent gate
│   │   └── Subscription/       # Paywall & purchases
│   │
│   ├── Services/
│   │   └── SubscriptionServiceSK2.swift
│   │
│   ├── UI/
│   │   ├── Components/
│   │   │   ├── SoundCard.swift
│   │   │   ├── SoundCell.swift
│   │   │   └── SafetyBadge.swift
│   │   └── Player/
│   │       ├── MiniPlayerView.swift
│   │       └── NowPlayingView.swift
│   │
│   └── Resources/
│       ├── Audio/              # MP3 files
│       └── sounds.json         # Sound catalog
│
├── Packages/
│   ├── BabySoundsCore/         # Core logic library
│   ├── BabySoundsUI/           # Reusable UI library
│   └── Tests/
└── Tests/
```

### Module Responsibilities

#### BabySounds (Main App)
- App entry point and lifecycle
- Feature implementations
- Audio playback
- User interface

#### BabySoundsCore (Library)
- Shared business logic
- Data models
- Utilities
- Reusable managers

#### BabySoundsUI (Library)
- Reusable UI components
- Design system
- Custom controls

## Core Systems

### 1. Audio System (1,780 LOC)

The audio system is the heart of the app, consisting of three main components:

#### AudioEngineManager.swift (799 LOC)
Manages multi-track audio playback using AVAudioEngine.

**Capabilities**:
- Up to 4 simultaneous audio tracks
- Individual volume control per track
- Pan control (stereo positioning)
- Fade-in/fade-out effects
- Gapless looping
- Audio file caching

**Key Methods**:
```swift
class AudioEngineManager: ObservableObject {
    func play(sound: Sound, track: Int = 0) async throws
    func stop(track: Int) async
    func setVolume(_ volume: Float, for track: Int)
    func setPan(_ pan: Float, for track: Int)
    func fadeOut(track: Int, duration: TimeInterval)
}
```

**Architecture**:
```
AVAudioEngine
├── Mixer Node
│   ├── Player Node 1 ──► Volume Node 1 ──► Pan Node 1
│   ├── Player Node 2 ──► Volume Node 2 ──► Pan Node 2
│   ├── Player Node 3 ──► Volume Node 3 ──► Pan Node 3
│   └── Player Node 4 ──► Volume Node 4 ──► Pan Node 4
└── Output Node (Hardware)
```

#### SafeVolumeManager.swift (477 LOC)
Implements WHO hearing safety guidelines.

**Features**:
- Real-time volume monitoring
- Automatic volume limits
- Audio route detection (headphones/speakers)
- Listening time tracking
- Break recommendations
- Parental override with verification

**WHO Guidelines**:
- Maximum 85 dB for children
- Different limits for headphones vs speakers
- Listening time tracking (recommend breaks after 60 min)
- Volume warnings and automatic limiting

#### BackgroundAudioManager.swift (504 LOC)
Handles background playback and system integration.

**Capabilities**:
- Background audio session management
- Now Playing info center updates
- Lock screen controls
- Remote command handling (play, pause, skip)
- Audio interruption handling (phone calls, etc.)

### 2. Premium System

#### PremiumManager.swift
Manages premium feature access and subscription state.

**Premium Features**:
- Unlimited favorites (free: 5)
- Extended timer (free: 30 min)
- Custom mixes (4 tracks)
- Offline downloads (planned v1.1)
- Advanced controls

**Feature Gating**:
```swift
enum PremiumFeature {
    case unlimitedFavorites
    case extendedTimer
    case customMixes
    case offlineDownloads
    case advancedControls
}

func canAccess(_ feature: PremiumFeature) -> Bool
func showPaywallIfNeeded(for feature: PremiumFeature)
```

#### SubscriptionServiceSK2.swift
StoreKit 2 integration for in-app purchases.

**Plans**:
- Monthly: $4.99/month
- Annual: $29.99/year (save 50%)

**Implementation**:
```swift
class SubscriptionService: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []

    func loadProducts() async throws
    func purchase(_ product: Product) async throws
    func restorePurchases() async throws
}
```

### 3. Safety Systems

#### ParentGateManager.swift
Implements parental controls to prevent unauthorized actions.

**Challenge Types**:
- Math problems (addition, subtraction)
- Memory tests (number sequences)
- Pattern recognition

**Features**:
- 5-minute timeout after successful verification
- Rate limiting (max 5 attempts)
- Analytics tracking
- Customizable difficulty

#### SafeLinkWrapper.swift
Protects external link navigation with parent gate.

### 4. Schedule System

#### SleepScheduleManager.swift
Manages automated sound playback schedules.

**Features**:
- Multiple schedules
- Repeat patterns (daily, specific weekdays)
- Sound selection
- Volume presets
- Notification integration

**Data Model**:
```swift
struct SleepSchedule: Identifiable, Codable {
    let id: UUID
    var name: String
    var time: Date
    var sound: Sound
    var volume: Float
    var repeatDays: Set<Weekday>
    var isEnabled: Bool
}
```

## Data Flow

### Audio Playback Flow

```
User Action
    ↓
View (Button tap)
    ↓
ViewModel (@Published state update)
    ↓
AudioEngineManager
    ↓
SafeVolumeManager (volume check)
    ↓
AVAudioEngine (playback)
    ↓
BackgroundAudioManager (system integration)
    ↓
Now Playing Center (lock screen)
```

### Purchase Flow

```
User Taps "Subscribe"
    ↓
PaywallView
    ↓
SubscriptionService.purchase()
    ↓
StoreKit 2 (Apple)
    ↓
Transaction Observer
    ↓
PremiumManager (update state)
    ↓
UI Updates (@Published)
```

### Parent Gate Flow

```
Protected Action Attempt
    ↓
ParentGateView appears
    ↓
Challenge displayed
    ↓
User solves challenge
    ↓
ParentGateManager validates
    ↓
5-minute timeout starts
    ↓
Action proceeds
```

## Threading Model

### Main Actor

All UI updates and user interactions happen on the main thread:

```swift
@MainActor
class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentSound: Sound?
}
```

### Background Processing

Audio processing and file loading happen off the main thread:

```swift
func loadAudioFile(_ sound: Sound) async throws -> AVAudioFile {
    try await Task.detached(priority: .userInitiated) {
        // Load file on background thread
    }.value
}
```

### Concurrency Architecture

```
Main Thread (MainActor)
├── UI Updates
├── User Interactions
└── Published Property Changes

Background Queues
├── Audio File Loading
├── Buffer Processing
└── Network Requests (future)
```

## Audio Architecture

### AVAudioEngine Setup

```
┌──────────────────────────────────────────────────┐
│                  AVAudioEngine                    │
│                                                   │
│  ┌────────────┐      ┌──────────┐               │
│  │  Player 1  │─────►│ Volume 1 │───┐           │
│  └────────────┘      └──────────┘   │           │
│                                      │           │
│  ┌────────────┐      ┌──────────┐   │           │
│  │  Player 2  │─────►│ Volume 2 │───┤           │
│  └────────────┘      └──────────┘   │           │
│                                      ├──► Mixer  │
│  ┌────────────┐      ┌──────────┐   │           │
│  │  Player 3  │─────►│ Volume 3 │───┤           │
│  └────────────┘      └──────────┘   │           │
│                                      │           │
│  ┌────────────┐      ┌──────────┐   │           │
│  │  Player 4  │─────►│ Volume 4 │───┘           │
│  └────────────┘      └──────────┘               │
│                                                   │
│                      Mixer ─────► Output         │
└──────────────────────────────────────────────────┘
                           │
                           ▼
                   Hardware (Speakers)
```

### Audio Session Configuration

```swift
let audioSession = AVAudioSession.sharedInstance()
try audioSession.setCategory(.playback, mode: .default)
try audioSession.setActive(true)
```

**Session Options**:
- Category: `.playback` (allows background playback)
- Mode: `.default` (no special processing)
- Options: `.mixWithOthers` (optional, for playing with other apps)

## State Management

### Observable Objects

State is managed using `@StateObject` and `@ObservableObject`:

```swift
class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentSound: Sound?
    @Published var volume: Float = 0.7
    @Published var tracks: [Int: Sound] = [:]
}
```

### Environment Injection

Dependencies are injected via SwiftUI environment:

```swift
struct SleepView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var premiumManager: PremiumManager

    var body: some View {
        // Use injected dependencies
    }
}
```

### Persistence

Local data is persisted using:

- **UserDefaults**: Simple preferences, favorites list
- **Keychain**: Sensitive data (future: user credentials)
- **File System**: Audio files, cached data
- **iCloud**: Optional preference syncing

```swift
@AppStorage("favorites") var favoritesData: Data = Data()
```

## Dependencies

### Apple Frameworks

- **SwiftUI**: UI framework
- **AVFoundation**: Audio playback
- **StoreKit 2**: In-app purchases
- **UserNotifications**: Schedule reminders
- **Foundation**: Core utilities

### Third-Party (Future)

- **TelemetryDeck**: Privacy-focused analytics (planned)
- **Firebase**: Analytics & Crashlytics (optional alternative)

### No External Dependencies

Current implementation uses **zero external dependencies** for:
- Faster compilation
- Reduced app size
- Better security
- Easier maintenance

## Performance Considerations

### Memory Management

- Audio files are loaded on-demand
- Unused buffers are released immediately
- File cache with size limits

### CPU Usage

- Audio processing on dedicated queue
- Efficient buffer scheduling
- Minimal main thread work

### Battery Life

- Background audio optimized
- No unnecessary processing when paused
- Efficient timer usage

## Security & Privacy

### Data Protection

- No server communication (all local)
- No personal data collection
- Parent gate for sensitive actions
- Secure purchase handling via Apple

### COPPA Compliance

- No data collection from children
- Parental consent for purchases
- No third-party advertising
- No social features

## Testing Strategy

### Unit Tests
- Core business logic
- Managers and services
- Data models

### Integration Tests
- Audio playback flows
- Purchase flows
- Schedule system

### UI Tests (Future)
- Critical user journeys
- Accessibility verification

## Future Architecture Plans

### v1.1
- Offline download system
- Custom mix persistence
- Enhanced analytics

### v2.0
- Audio effects engine
- Cloud sync (optional)
- Community features
- Advanced DSP processing

---

## Additional Resources

- [Development Setup](SETUP.md)
- [API Reference](https://github.com/vpavlov-me/BabySounds/wiki)
- [Contributing Guide](../CONTRIBUTING.md)

[Back to Home](index)
