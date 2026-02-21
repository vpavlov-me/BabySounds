# BabySounds — Comprehensive Code Audit & Refactoring Plan

**Date**: February 2026
**Codebase**: ~18,800 lines of Swift across 45+ files
**Platform**: iOS 17+, Swift 6.0, SwiftUI, MVVM
**Auditor**: Automated Code Audit

---

## Table of Contents

1. [What Is Done Well ✅](#1-what-is-done-well-)
2. [What Is Done Poorly / Bugs ❌](#2-what-is-done-poorly--bugs-)
3. [What Is Not Finished / Incomplete 🚧](#3-what-is-not-finished--incomplete-)
4. [What Can Be Improved 🔧](#4-what-can-be-improved-)
5. [Refactoring Priority List 📋](#5-refactoring-priority-list-)
6. [Recommended Refactoring Steps 🗺️](#6-recommended-refactoring-steps-)

---

## 1. What Is Done Well ✅

### Architecture Strengths

- **MVVM Separation**: Core business logic is properly separated into Managers/Services (Data layer), Models layer, and SwiftUI Views. The `Core/`, `Features/`, `Services/`, and `UI/` directory structure follows a clean feature-based organization.

- **Module Structure**: The project uses SPM (Swift Package Manager) with a clear `Package.swift` manifest. Sources and tests are properly separated (`BabySounds/Sources/` and `BabySounds/Tests/`).

- **Feature-Based Organization**: Each feature (Sleep, Playroom, Favorites, Schedules, Settings, ParentalControls, Subscription) has its own directory under `Features/`, making the codebase navigable and maintainable.

### Swift 6 Concurrency

- **`@MainActor` Usage**: All ObservableObject managers are correctly annotated with `@MainActor`: `AudioEngineManager`, `SafeVolumeManager`, `PremiumManager`, `SleepScheduleManager`, `NotificationPermissionManager`, `AnalyticsService`, `SubscriptionServiceSK2`.

- **Async/Await**: Modern async/await is used throughout for StoreKit 2 operations, notification permissions, and schedule management (e.g., `SleepScheduleManager.addSchedule()`, `SubscriptionServiceSK2.purchase()`).

- **Task.detached for Transaction Observer**: `SubscriptionServiceSK2` correctly uses `Task.detached` with `[weak self]` for the StoreKit transaction update listener (line 280).

### SwiftUI Patterns

- **`@EnvironmentObject` Injection**: The app properly injects shared state via `.environmentObject()` in `BabySoundsApp.swift` for `audioManager`, `subscriptionService`, `soundCatalog`, `premiumManager`, and `safeVolumeManager`.

- **`@Published` Properties**: All manager classes use `@Published` for reactive UI updates. `PremiumManager` and `SafeVolumeManager` expose read-only published state with `public private(set)`.

### StoreKit 2 Integration

- **Modern StoreKit 2 API**: The `SubscriptionServiceSK2` uses `Product.products(for:)`, `product.purchase()`, `AppStore.sync()`, and `Transaction.currentEntitlements` correctly.

- **Verification Handling**: Both `.verified` and `.unverified` transaction results are handled, with proper `transaction.finish()` calls.

- **Trial Period Detection**: The service correctly detects trial periods by comparing `originalPurchaseDate` with trial end date.

- **Subscription Status Enum**: Well-designed `SubscriptionStatus` enum covers all states: `.notSubscribed`, `.subscribed`, `.expired`, `.inTrialPeriod`, `.inGracePeriod`, `.pending`.

### WHO Volume Safety Implementation

- **SafeVolumeManager**: Comprehensive implementation with:
  - Maximum child-safe volume: 0.7 (70%)
  - Default child volume: 0.4 (40%)
  - Headphone volume reduction (80% of speaker limit)
  - Volume warning levels (safe/caution/warning/danger)
  - Break reminders after 45 minutes
  - Maximum listening time of 60 minutes
  - Listening session tracking

- **Audio Route Change Handling**: Headphone disconnection pauses audio for safety (both in `SafeVolumeManager` and `BackgroundAudioManager`).

### COPPA-Compliant Analytics

- **OSLog Only**: `AnalyticsService` uses Apple's `Logger` (OSLog subsystem) with no third-party analytics SDKs. This is privacy-first and COPPA-compliant.

- **No PII Collection**: Analytics events track only anonymized event names, categories, and non-identifying properties. URL domains are anonymized in `trackExternalLinkOpened`.

- **Parent Gate Protection**: All sensitive actions (settings, purchases, external links, data deletion) require parent gate verification via `ParentGateManager`.

### Test Coverage Quality

- **SafeVolumeManagerTests** (149 LOC): Tests volume limiting, WHO compliance, headphone safety, dB conversion, listening session tracking. Good coverage of safety-critical paths.

- **PremiumManagerTests** (191 LOC): Tests free user limits (favorites, timer, tracks, gain/pan), premium gate actions (paywall/message), and feature metadata validation.

- **SleepScheduleTests** (235 LOC): Tests schedule creation, next bedtime calculation, day formatting, notification ID uniqueness, weekday sorting, and error descriptions.

### Other Strengths

- **Error Enums**: Well-defined error types (`AudioEngineError`, `SoundCatalogError`, `SleepScheduleError`, `SubscriptionError`) with `LocalizedError` conformance.

- **Codable Support**: `Sound`, `SleepSchedule`, `SoundPack`, `MixTrack`, `Mix` all have proper `Codable` conformance with custom coding keys.

- **Audio Engine Design**: Multi-track AVAudioEngine with proper node attachment/detachment, buffer-based gapless looping, and per-track volume/pan control.

- **Parent Gate Variety**: Multiple challenge types (math addition/subtraction, time reading, word recognition, text input) with context-appropriate difficulty levels.

---

## 2. What Is Done Poorly / Bugs ❌

### 2.1 Force Unwraps (Crash Risks)

| # | File | Line | Code | Severity |
|---|------|------|------|----------|
| 1 | `BackgroundAudioManager.swift` | 246 | `let primaryTrackInfo = currentlyPlaying.values.first!` | 🔴 **Critical** — will crash if `currentlyPlaying` is empty despite the guard on line 237 (guard only checks `isEmpty`, but race condition possible) |
| 2 | `BackgroundAudioManager.swift` | 307 | `locations: nil)!` — Force unwrap on `CGGradient` creation | 🟡 Medium — unlikely to fail but violates project rules |
| 3 | `ParentGateManager.swift` | 65 | `challengeTypes.randomElement()!` | 🟢 Low — static array, always non-empty |
| 4 | `ParentGateManager.swift` | 84, 92 | `[0, 15, 30, 45].randomElement()!` | 🟢 Low — static array |
| 5 | `ParentGateManager.swift` | 107 | `words.randomElement()!` | 🟢 Low — static array |
| 6 | `ParentGateManager.swift` | 121 | `words.randomElement()!` | 🟢 Low — static array |
| 7 | `ParentGateManager.swift` | 144 | `questions.randomElement()!` | 🟢 Low — static array |
| 8 | `SoundCatalog.swift` | 143-262 | `UUID(uuidString: "...")!` in sample sounds | 🟡 Medium — hardcoded UUIDs, could use `UUID()` instead |
| 9 | `AudioEngineManager.swift` | 816 | `fadeOutTrack(tracks[handle.id]!, ...)` — Force unwrap after nil check on line 811 | 🟡 Medium — guard check exists but force unwrap is unnecessary |

### 2.2 Duplicate Type Definitions (Compilation Error)

| # | File | Line | Issue |
|---|------|------|-------|
| 1 | `Sound.swift` | 343 | `struct SleepSchedule: Identifiable, Codable` — **Duplicate definition** |
| 2 | `SleepSchedule.swift` | 5 | `struct SleepSchedule: Identifiable, Codable, Equatable` — **Actual definition** |

**Impact**: Two `SleepSchedule` structs with completely different properties. `Sound.swift` defines one with `startTime`, `durationMinutes`, `soundId`, `mixId`, `repeatPattern` (bitmask). `SleepSchedule.swift` defines another with `name`, `bedtimeHour`, `bedtimeMinute`, `weekdays`, `selectedSounds`, `autoFadeMinutes`. The version in `SleepSchedule.swift` is the one actually used by `SleepScheduleManager`, but the duplicate in `Sound.swift` would cause a compilation error.

### 2.3 Duplicate `HapticManager` Class

| # | File | Line | Issue |
|---|------|------|-------|
| 1 | `Core/Utils/HapticManager.swift` | 7 | `final class HapticManager` — Full implementation with `@MainActor` |
| 2 | `UI/Components/MiniPlayerView.swift` | 163 | `class HapticManager` — Simplified duplicate without `@MainActor` |

**Impact**: Two `HapticManager` classes in the same module will cause a compilation error.

### 2.4 Duplicate `gradientColors` Property

| # | File | Line | Issue |
|---|------|------|-------|
| 1 | `Sound.swift` | 120-164 | `var gradientColors: [Color]` — property on `Sound` |
| 2 | `MiniPlayerView.swift` | 187-207 | `var gradientColors: [Color]` — extension on `Sound` |

**Impact**: Duplicate computed property definition on the same type. Will cause a compilation error. Additionally, the MiniPlayerView version only handles 6 categories while Sound.swift handles 14.

### 2.5 Missing Singleton on SoundCatalog

`SoundCatalog` is used as `SoundCatalog.shared` in 4 places but has no `static let shared` property:
- `BabySoundsApp.swift:10` — `@StateObject private var soundCatalog = SoundCatalog.shared`
- `AudioEngineManager.swift:770` — `let catalog = SoundCatalog.shared`
- `SleepScheduleEditView.swift:8,336` — `@StateObject private var soundCatalog = SoundCatalog.shared`

### 2.6 Method Name Mismatch: `hasFeature` vs `hasAccess`

`PremiumManager` defines `hasAccess(to:)` (line 172) but `SleepScheduleManager` calls `premiumManager.hasFeature(.sleepSchedules)` (lines 47, 282, 322) and `SleepSchedulesView` calls it on line 129. **`hasFeature` does not exist** — this is a compilation error.

### 2.7 Missing `currentSound` Property

`AudioEngineManager` does not define a `currentSound` property, but it's referenced in:
- `ContentView.swift:84` — `audioManager.currentSound != nil`
- `PlayroomView.swift:262` — `audioManager.currentSound?.id`
- `FavoritesListView.swift:213, 307, 312` — `audioManager.currentSound?.id`
- `NowPlayingView.swift:256-257` — `audioManager.currentSound`
- `MiniPlayerView.swift:16` — `audioManager.currentSound`

### 2.8 Concurrency Issues

| # | File | Line | Issue |
|---|------|------|-------|
| 1 | `AudioEngineManager.swift` | 453 | `DispatchQueue.main.async` in completion handler — should use `Task { @MainActor in ... }` since class is `@MainActor` |
| 2 | `AudioEngineManager.swift` | 563 | `DispatchQueue.main.async { [weak self] in self?.updateNowPlayingInfo() }` — unnecessary since already `@MainActor` |
| 3 | `AudioEngineManager.swift` | 662 | `DispatchQueue.main.asyncAfter` inside `fadeAllTracks` — mixing GCD with `@MainActor` |
| 4 | `SafeVolumeManager.swift` | 212 | `DispatchQueue.main.asyncAfter` for parental override timeout — should use `Task.sleep` |
| 5 | `PremiumManager.swift` | 230 | `DispatchQueue.main.async` in `requestAccess` — already `@MainActor` |
| 6 | `SafeVolumeManager.swift` | 406 | Timer callback `[weak self]` — Timer runs on main thread but callback may not respect `@MainActor` isolation |
| 7 | `AudioEngineManager.swift` | 504 | `Timer.scheduledTimer` in `fadeOutTrack` — callback closure captures `playerNode` without `@MainActor` annotation |

### 2.9 Hardcoded Strings (Localization Issues)

| # | File | Line | Content |
|---|------|------|---------|
| 1 | `SleepScheduleManager.swift` | 176 | `"Через \(schedule.reminderMinutes) мин. schedule starts..."` — **Russian text mixed with English** ("Через" = "In", "мин." = "min." in Russian) |
| 2 | `SleepScheduleManager.swift` | 175 | `"Bedtime soon"` — not localized |
| 3 | `SleepScheduleManager.swift` | 201 | `"Bedtime!"` — not localized |
| 4 | `BackgroundAudioManager.swift` | 250-251 | `"Baby Sounds"`, `"Baby Sounds Mix"` — hardcoded |
| 5 | `BackgroundAudioManager.swift` | 279 | `"Ambient"` — hardcoded genre |
| 6 | `SettingsView.swift` | 190 | `// TODO: Replace with actual App Store ID when app is published` |
| 7 | `Weekday` names | Multiple | `"Monday"`, `"Tuesday"`, etc. — hardcoded English, not using `NSLocalizedString` |

### 2.10 DispatchQueue Usage in @MainActor Classes

13 instances of `DispatchQueue.main.async/asyncAfter` found in `@MainActor`-annotated classes. These are redundant (already on main actor) and bypass Swift concurrency's actor isolation checking.

### 2.11 Dead Code / Unreachable Code

| # | File | Line | Issue |
|---|------|------|-------|
| 1 | `AudioEngineManager.swift` | 569-571 | `updateNowPlayingInfo()` stub — comment says "Will be overridden by extension" but Swift doesn't support method override in extensions |
| 2 | `SubscriptionServiceSK2.swift` | 206 | `if let subscriptionProduct = SubscriptionProduct(rawValue: product.id)` — result unused, no action taken |
| 3 | `ParentGateManager.swift` | 225-226 | `recordCancellation` — empty body after comment stub |
| 4 | `ParentGateManager.swift` | 233-234 | `recordTimeout` — empty body after comment stub |
| 5 | `SafeVolumeManager.swift` | 451-453 | `checkVolumeLevel()` — empty method body |

### 2.12 Retain Cycle Risks

| # | File | Line | Issue |
|---|------|------|-------|
| 1 | `AudioEngineManager.swift` | 662 | `DispatchQueue.main.asyncAfter` captures `playerNode` strongly — potential retain cycle with engine graph |
| 2 | `SafeVolumeManager.swift` | 406 | Timer callback `[weak self]` is correct, but `updateListeningDuration()` is called without checking `self` exists after weak capture |

---

## 3. What Is Not Finished / Incomplete 🚧

### 3.1 TODO/FIXME Comments

| # | File | Line | Comment |
|---|------|------|---------|
| 1 | `SettingsView.swift` | 190 | `// TODO: Replace with actual App Store ID when app is published` |

### 3.2 Stub Methods / Placeholder Logic

| # | File | Line | Issue |
|---|------|------|-------|
| 1 | `AudioEngineManager.swift` | 569-571 | `updateNowPlayingInfo()` — stub method that does nothing. The real implementation exists in `BackgroundAudioManager.swift` as a `public func`, but the private stub shadows it. |
| 2 | `AudioEngineManager.swift` | 744-748 | `timerRemaining` always returns `0` — incomplete implementation |
| 3 | `ParentGateManager.swift` | 220-226 | `recordCancellation()` — empty implementation |
| 4 | `ParentGateManager.swift` | 229-235 | `recordTimeout()` — empty implementation |
| 5 | `SafeVolumeManager.swift` | 451-453 | `checkVolumeLevel()` — empty method body |
| 6 | `SoundCatalog.swift` | 56-64 | `toggleFavorite` — `#if DEBUG` allows unlimited in debug, production path just prints and returns |

### 3.3 Sound Library Wiring

The `SoundCatalog.createSampleSounds()` provides **10 sample sounds** as a fallback, but the project expects **15 sounds**. JSON loading (`loadSoundsFromJSON`) depends on a bundled `sounds.json` file. The actual sound count depends on this JSON file's content. The sample sounds cover:
1. White Noise, 2. Pink Noise, 3. Brown Noise, 4. Rain, 5. Ocean Waves, 6. Forest, 7. Heartbeat, 8. Womb Sounds, 9. Fan, 10. Air Conditioner

Missing from samples: ~5 additional sounds to reach the stated 15.

### 3.4 Playroom Content Filtering

`PlayroomView` references `audioManager.currentSound` which doesn't exist on `AudioEngineManager`. The Playroom content filtering logic may not be fully wired up — it depends on `SoundCategory` filtering but the actual filtering implementation references undefined properties.

### 3.5 Parental Gate Flows

The parent gate system is mostly complete with:
- ✅ Math challenges (addition/subtraction)
- ✅ Time challenges
- ✅ Reading challenges
- ✅ Text input challenges
- ✅ Context-based difficulty
- ✅ Lockout after max attempts
- ✅ Recent pass caching (5 minutes)
- 🚧 `recordCancellation()` — empty implementation
- 🚧 `recordTimeout()` — empty implementation
- ❌ Memory test — mentioned in requirements but not implemented

### 3.6 StoreKit 2 Completeness

- ✅ Product loading
- ✅ Purchase flow
- ✅ Restore purchases
- ✅ Transaction observer
- ✅ Trial period detection
- 🚧 Pending purchase handling (line 206) — creates status but doesn't handle approval
- 🚧 Grace period detection — `SubscriptionStatus.inGracePeriod` exists but is never set
- 🚧 Subscription renewal notifications — not implemented

### 3.7 Notification Edge Cases

- 🚧 `SleepScheduleManager.scheduleNotifications()` schedules for next 30 days — no re-scheduling mechanism when those 30 days pass
- 🚧 Notification body on line 176 contains **Russian text**: `"Через \(schedule.reminderMinutes) мин. schedule starts"` — mixed language
- 🚧 No handling for notification authorization changes (user revoking permission in Settings)

### 3.8 Error Handling Gaps

| Area | Gap |
|------|-----|
| Audio session interruption (BackgroundAudioManager) | Interruption-ended handler resumes all tracks without checking which ones were playing |
| `SoundCatalog.loadSounds()` | Falls back to sample data silently — no user notification of load failure |
| `SleepScheduleManager.handleBedtimeNotification()` | `do {}` block on line 345-350 has no catch — error swallowed silently |
| `AudioEngineManager.play()` | No recovery if `engine.start()` fails after being stopped |
| Network errors | No retry logic for StoreKit product loading |

---

## 4. What Can Be Improved 🔧

### 4.1 Architecture

#### Remove Singletons / Improve DI

The codebase has **9 singletons**: `AudioEngineManager.shared`, `SafeVolumeManager.shared`, `PremiumManager.shared`, `SleepScheduleManager.shared`, `SoundCatalog.shared` (missing), `SubscriptionServiceSK2.shared`, `AnalyticsService.shared`, `HapticManager.shared` (×2), `FavoritesManager.shared` (in NowPlayingView).

**Recommendation**: Use protocol-based dependency injection. Create protocols for each manager and inject via `@EnvironmentObject` or constructor injection:

```swift
protocol AudioPlayable: ObservableObject {
    var currentlyPlaying: [UUID: PlayingInfo] { get }
    func play(sound: Sound, loop: Bool) async throws -> TrackHandle
    func stop(id: UUID, fade: TimeInterval?)
}
```

#### Extract ViewModels from Views

Several views contain business logic that should be in ViewModels:
- `ContentView.swift` (806 LOC) — parent gate validation logic
- `SleepScheduleEditView.swift` (452 LOC) — schedule creation/validation
- `SafetySettingsView.swift` (669 LOC) — safety configuration logic
- `PaywallView.swift` (411 LOC) — purchase flow logic

#### Consolidate FavoritesManager

`FavoritesManager` is defined inside `NowPlayingView.swift` (line 312) as a local class. This should be extracted to `Core/Data/` or merged with `SoundCatalog`'s favorites functionality.

### 4.2 Swift 6 / Concurrency

#### Replace DispatchQueue with @MainActor/Task

All 13 `DispatchQueue.main.async/asyncAfter` calls should be replaced:

```swift
// ❌ Current (AudioEngineManager.swift:453)
DispatchQueue.main.async {
    self?.removeTrack(track.id)
}

// ✅ Recommended
Task { @MainActor [weak self] in
    self?.removeTrack(track.id)
}
```

For delayed execution:
```swift
// ❌ Current (SafeVolumeManager.swift:212)
DispatchQueue.main.asyncAfter(deadline: .now() + 1800) { [weak self] in
    self?.deactivateParentalOverride()
}

// ✅ Recommended
Task { [weak self] in
    try? await Task.sleep(for: .seconds(1800))
    await self?.deactivateParentalOverride()
}
```

#### Actor-Isolate Audio Operations

`AudioTrack` is a `private class` accessed from `@MainActor`-annotated `AudioEngineManager`. Since AVAudioPlayerNode operations can be called from background threads (e.g., buffer completion handlers), consider making audio operations explicitly synchronized.

### 4.3 SwiftUI

#### Massive Views

| File | LOC | Recommendation |
|------|-----|----------------|
| `ContentView.swift` (App) | 806 | Extract tab views into separate files, move parent gate logic to ViewModel |
| `DataDebugView.swift` | 752 | Extract sections into subviews |
| `SafetySettingsView.swift` | 669 | Extract setting rows into reusable components |
| `ParentGateView.swift` | 533 | Extract challenge views into separate ViewBuilders |
| `BackgroundAudioManager.swift` | 495 | Not a view, but the extension is too large; split into smaller focused extensions |

#### NavigationView vs NavigationStack

The app uses deprecated `NavigationView` (lines 23, 42, 52, 62 in ContentView.swift). iOS 17+ should use `NavigationStack`:

```swift
// ❌ Current
NavigationView {
    SleepListView()
}

// ✅ Recommended (iOS 17+)
NavigationStack {
    SleepListView()
}
```

### 4.4 Audio Engine

#### Now Playing Artwork

`generateNowPlayingArtwork()` (BackgroundAudioManager.swift:289-348) generates a gradient with a wave pattern programmatically but is **never called** — `updateNowPlayingInfo()` doesn't use it. The artwork property should be set in the Now Playing info dictionary.

#### Stub Method Shadowing

The private `updateNowPlayingInfo()` stub in `AudioEngineManager.swift:569` shadows the `public func updateNowPlayingInfo()` in `BackgroundAudioManager.swift:234`. Since both are in the same class (extension), the private one takes precedence from within the main file, preventing the real implementation from being called during `updateCurrentlyPlaying()`.

#### Fade-Out Implementation

The `fadeOutTrack()` method uses `Timer.scheduledTimer` with linear volume interpolation. This produces audible stepping. Consider:
1. Using `AVAudioUnitEQ` with automated parameters
2. Using exponential/logarithmic curves for more natural fading
3. Using `CADisplayLink` for smoother updates

### 4.5 Performance

#### Synchronous File Loading

`getAudioFile(for:)` (AudioEngineManager.swift:236-251) reads audio files synchronously on `@MainActor`. For large audio files, this blocks the main thread:

```swift
// Line 248 - synchronous file read on main thread
let audioFile = try AVAudioFile(forReading: url)
```

**Recommendation**: Always use the async `preload(sound:)` method, or move file loading off the main actor.

#### Buffer Creation

`createBuffer(from:)` (line 463) reads the entire audio file into a PCM buffer. For long audio files, this allocates significant memory. Consider streaming or using shorter buffer segments with re-scheduling.

### 4.6 Testing

#### Missing Test Coverage

| Area | Current Coverage | Recommended Tests |
|------|-----------------|-------------------|
| AudioEngineManager | ❌ None | Track management, play/stop, volume control, concurrent track limits |
| BackgroundAudioManager | ❌ None | Audio session setup, interruption handling, Now Playing info |
| ParentGateManager | ❌ None | Challenge generation, answer validation, lockout logic, timeout |
| SoundCatalog | ❌ None | Sound loading, favorites management, JSON parsing |
| NotificationPermissionManager | ❌ None | Permission states, parent gate integration |
| AnalyticsService | ❌ None | Event tracking, privacy compliance |
| SubscriptionServiceSK2 | ❌ None | Product loading, purchase flow, status updates |

#### Test Infrastructure Issues

- Tests use `sut = PremiumManager.shared` — singleton state leaks between tests
- No mock/stub protocols for dependency injection in tests
- No UI tests for critical flows

### 4.7 Accessibility

#### Missing Labels

Many interactive elements in view files lack `accessibilityLabel` and `accessibilityHint`. A thorough accessibility audit of all views is needed, especially:
- Mini player controls
- Sound cells in the library
- Playroom buttons
- Parent gate challenge options
- Timer controls in NowPlayingView

#### Dynamic Type

Views using fixed font sizes (`.font(.system(size:))`) should use Dynamic Type sizes (`.font(.title)`, `.font(.body)`) to support accessibility text sizes.

---

## 5. Refactoring Priority List 📋

### P0 — Critical (Fix Before App Store Submission)

| # | File:Line | Description | Fix |
|---|-----------|-------------|-----|
| P0-1 | `Sound.swift:343-381` | **Duplicate `SleepSchedule` struct** — compilation error | Remove the `SleepSchedule` struct from `Sound.swift`. The real one is in `SleepSchedule.swift`. |
| P0-2 | `MiniPlayerView.swift:163-182` | **Duplicate `HapticManager` class** — compilation error | Remove the `HapticManager` class from `MiniPlayerView.swift`. Use the one in `Core/Utils/HapticManager.swift`. |
| P0-3 | `MiniPlayerView.swift:187-207` | **Duplicate `gradientColors` extension** — compilation error | Remove the `Sound.gradientColors` extension from `MiniPlayerView.swift`. Use the property defined in `Sound.swift`. |
| P0-4 | `SoundCatalog.swift` | **Missing `static let shared`** — compilation error | Add `public static let shared = SoundCatalog()` and make `init()` private. |
| P0-5 | `SleepScheduleManager.swift:47,282,322` | **`hasFeature` does not exist** on `PremiumManager` | Replace `premiumManager.hasFeature(.sleepSchedules)` with `premiumManager.hasAccess(to: .sleepSchedules)`. |
| P0-6 | `SleepSchedulesView.swift:129` | **`hasFeature` does not exist** on `PremiumManager` | Replace with `hasAccess(to:)`. |
| P0-7 | `AudioEngineManager.swift` | **Missing `currentSound` property** — referenced in 6+ views | Add `var currentSound: Sound?` computed property based on `currentlyPlaying.values.first?.sound`. |
| P0-8 | `BackgroundAudioManager.swift:246` | **Force unwrap `currentlyPlaying.values.first!`** — crash risk | Replace with `guard let primaryTrackInfo = currentlyPlaying.values.first else { return }`. |
| P0-9 | `SleepScheduleManager.swift:176` | **Russian text in notification** ("Через...мин." = "In...min." in Russian) | Replace `"Через \(schedule.reminderMinutes) мин. schedule starts"` with proper English/localized string, e.g., `String(localized: "Bedtime in \(schedule.reminderMinutes) minutes")`. |
| P0-10 | `AudioEngineManager.swift:569-571` | **Stub `updateNowPlayingInfo()` shadows real implementation** | Remove the private stub method. The extension's public method in `BackgroundAudioManager.swift` will be used correctly. |

### P1 — High (Fix in v1.0)

| # | File:Line | Description | Fix |
|---|-----------|-------------|-----|
| P1-1 | `AudioEngineManager.swift:816` | Force unwrap `tracks[handle.id]!` | Use `guard let track = tracks[handle.id] else { return }` |
| P1-2 | `AudioEngineManager.swift:453,563,662` | `DispatchQueue.main` in `@MainActor` class | Replace with `Task { @MainActor in ... }` |
| P1-3 | `SafeVolumeManager.swift:212` | `DispatchQueue.main.asyncAfter` for 30-min timeout | Replace with `Task { try? await Task.sleep(...) }` |
| P1-4 | `PremiumManager.swift:230` | `DispatchQueue.main.async` in `@MainActor` class | Remove unnecessary dispatch, just set properties directly |
| P1-5 | `ContentView.swift:23,42,52,62` | Deprecated `NavigationView` | Replace with `NavigationStack` |
| P1-6 | `ParentGateManager.swift:220-235` | Empty `recordCancellation`/`recordTimeout` | Implement analytics tracking (OSLog) |
| P1-7 | `BackgroundAudioManager.swift:289-348` | `generateNowPlayingArtwork()` never called | Call it in `updateNowPlayingInfo()` or remove |
| P1-8 | `SettingsView.swift:190` | TODO: App Store ID | Replace with actual App Store ID before submission |
| P1-9 | `SleepScheduleManager.swift:175-202` | Notification strings not localized | Use `NSLocalizedString` or `String(localized:)` |
| P1-10 | `SubscriptionServiceSK2.swift:206` | Unused `subscriptionProduct` binding | Remove or use the variable |

### P2 — Medium (Fix in v1.1)

| # | File:Line | Description | Fix |
|---|-----------|-------------|-----|
| P2-1 | Multiple | 9 singletons with `.shared` | Introduce protocol-based DI, inject via `@EnvironmentObject` |
| P2-2 | `NowPlayingView.swift:312` | `FavoritesManager` defined inside view file | Extract to `Core/Data/FavoritesManager.swift` |
| P2-3 | `AudioEngineManager.swift:236-251` | Synchronous file loading on main thread | Move to background with `Task.detached` |
| P2-4 | `ContentView.swift` | 806 LOC | Extract tab views and parent gate logic into ViewModel |
| P2-5 | `SleepScheduleManager.swift:154-228` | 30-day notification scheduling | Implement re-scheduling when notifications expire |
| P2-6 | Multiple views | Missing accessibility labels | Add `accessibilityLabel`/`accessibilityHint` to all interactive elements |
| P2-7 | Multiple | Weekday names hardcoded in English | Use `Calendar.current.weekdaySymbols` or `NSLocalizedString` |
| P2-8 | `AudioEngineManager.swift:496-518` | Linear fade-out stepping | Use exponential curve for smoother fading |
| P2-9 | Tests | Missing test coverage | Add tests for `AudioEngineManager`, `ParentGateManager`, `SoundCatalog` |
| P2-10 | `SoundCatalog.swift:56-64` | Favorites limit bypass in DEBUG | Fix production path, check premium status properly |

### P3 — Low / Nice-to-Have (v2.0+)

| # | File:Line | Description | Fix |
|---|-----------|-------------|-----|
| P3-1 | `BackgroundAudioManager.swift:307` | Force unwrap on `CGGradient` | Use `guard let gradient = ... else { return renderer.image { ... } }` |
| P3-2 | `ParentGateManager.swift:65,84,92,107,121,144` | Force unwraps on `randomElement()` | Use `guard let` even though arrays are always non-empty |
| P3-3 | Multiple | `print()` statements for logging | Replace with OSLog `Logger` for consistency with `AnalyticsService` |
| P3-4 | `SafeVolumeManager.swift:145-148` | `NSKeyedUnarchiver` for Date | Use `UserDefaults.standard.object(forKey:) as? Date` directly |
| P3-5 | `AudioEngineManager.swift:463-479` | Full file buffering | Implement streaming for large audio files |
| P3-6 | `SubscriptionServiceSK2` | No grace period detection | Implement grace period status from transaction properties |
| P3-7 | `ParentGateManager` | No memory test challenge | Implement memory-based challenge type |
| P3-8 | Architecture | No Coordinator pattern | Consider implementing for navigation-heavy flows |
| P3-9 | `SoundCatalog` | Manual JSON parsing | Use `Codable` with custom decoder for cleaner parsing |
| P3-10 | UI | No preview providers for some views | Add `#Preview` macros for faster iteration |

---

## 6. Recommended Refactoring Steps 🗺️

### Phase 1: Fix Compilation Errors (P0)
**Goal**: Get the project compiling cleanly.

1. **Remove duplicate `SleepSchedule`** from `Sound.swift` (lines 343-381)
2. **Remove duplicate `HapticManager`** from `MiniPlayerView.swift` (lines 163-182)
3. **Remove duplicate `gradientColors`** extension from `MiniPlayerView.swift` (lines 187-207)
4. **Add `static let shared`** to `SoundCatalog` and make `init()` private
5. **Fix `hasFeature` → `hasAccess(to:)`** in `SleepScheduleManager.swift` and `SleepSchedulesView.swift`
6. **Add `currentSound` property** to `AudioEngineManager`
7. **Remove stub `updateNowPlayingInfo()`** from `AudioEngineManager.swift`
8. **Fix force unwrap** in `BackgroundAudioManager.swift:246`
9. **Fix Russian text** in `SleepScheduleManager.swift:176`

### Phase 2: Fix Concurrency Issues (P1)
**Goal**: Align with Swift 6 strict concurrency.

1. Replace all `DispatchQueue.main.async/asyncAfter` with `Task { @MainActor in }` or `Task.sleep`
2. Review Timer callbacks for proper `@MainActor` isolation
3. Ensure audio buffer completion handlers properly dispatch to `@MainActor`

### Phase 3: Fix Remaining P1 Issues
**Goal**: Production-ready quality.

1. Replace deprecated `NavigationView` with `NavigationStack`
2. Implement empty stub methods or remove them
3. Fix unused variables
4. Replace TODO with actual values
5. Localize all user-facing strings

### Phase 4: Architecture Improvements (P2)
**Goal**: Improve maintainability and testability.

1. Create protocols for all managers (e.g., `AudioPlayable`, `PremiumCheckable`)
2. Refactor singletons to injectable dependencies
3. Extract business logic from large views into ViewModels
4. Consolidate `FavoritesManager` into `SoundCatalog`
5. Add missing unit tests with proper mock injection

### Phase 5: Polish (P2-P3)
**Goal**: Production excellence.

1. Add accessibility labels to all interactive elements
2. Replace `print()` with OSLog `Logger`
3. Implement smoother audio fading
4. Add async audio file preloading
5. Complete StoreKit edge cases (grace period, renewal notifications)
6. Add UI tests for critical flows

---

## Appendix: File Reference

### Files by LOC (Descending)

| File | LOC | Layer |
|------|-----|-------|
| BabySoundsApp/ContentView.swift | 3,860 | App (Xcode target) |
| AudioEngineManager.swift | 821 | Core/Audio |
| ContentView.swift | 806 | App |
| DataDebugView.swift | 752 | Features/Settings |
| SafetySettingsView.swift | 669 | Features/ParentalControls |
| SafeVolumeManager.swift | 541 | Core/Audio |
| ParentGateView.swift | 533 | Features/ParentalControls |
| BackgroundAudioManager.swift | 495 | Core/Audio |
| SleepScheduleEditView.swift | 452 | Features/SleepSchedule |
| ParentGateManager.swift | 451 | Core/Data |
| AppleMusicSettingsView.swift | 445 | Features/Settings |
| SoundCatalog.swift | 431 | Core/Data |
| SafetyNoticeView.swift | 418 | Features/ParentalControls |
| SleepSchedulesView.swift | 413 | Features/SleepSchedule |
| PaywallView.swift | 411 | Features/Subscription |
| PremiumManager.swift | 383 | Core/Data |
| Sound.swift | 381 | Core/Models |
| NotificationPermissionManager.swift | 377 | Core/Data |
| SubscriptionServiceSK2.swift | 374 | Services/StoreKit |
| AppleMusicStyleModifiers.swift | 364 | UI/Modifiers |
| FavoritesListView.swift | 356 | Features/Favorites |
| SleepScheduleManager.swift | 354 | Core/Data |
| NowPlayingView.swift | 347 | UI/Views |
| PlayroomView.swift | 322 | Features/Playroom |
| SafeLinkWrapper.swift | 320 | Features/ParentalControls |
| SoundPlayerView.swift | 304 | Features/AudioPlayer |
| PremiumGateView.swift | 292 | Features/Subscription |
| SleepListView.swift | 292 | Features/Sleep |
| SchedulesListView.swift | 282 | Features/Schedules |
| AnalyticsService.swift | 269 | Services/Analytics |
| SoundCell.swift | 268 | UI/Components |
| SettingsView.swift | 244 | Features/Settings |
| SleepScheduleTests.swift | 235 | Tests |
| MiniPlayerView.swift | 208 | UI/Components |
| TermsOfServiceView.swift | 194 | Features/Legal |
| PremiumManagerTests.swift | 191 | Tests |
| SleepSchedule.swift | 184 | Core/Models |
| SubscriptionCardStoreKit.swift | 158 | Features/Subscription |
| SearchView.swift | 152 | Features/Search |
| SafeVolumeManagerTests.swift | 149 | Tests |
| PrivacyPolicyView.swift | 137 | Features/Legal |
| HapticManager.swift | 73 | Core/Utils |
| AppDelegate.swift | 50 | App |
| BabySoundsApp.swift | 34 | App |

### Singleton Registry

| Singleton | File | Mutable State | Thread-Safe |
|-----------|------|---------------|-------------|
| `AudioEngineManager.shared` | AudioEngineManager.swift | Yes (`tracks`, `currentlyPlaying`) | Via `@MainActor` |
| `SafeVolumeManager.shared` | SafeVolumeManager.swift | Yes (multiple `@Published`) | Via `@MainActor` |
| `PremiumManager.shared` | PremiumManager.swift | Yes (`pendingGateAction`) | Via `@MainActor` |
| `SleepScheduleManager.shared` | SleepScheduleManager.swift | Yes (`schedules`) | Via `@MainActor` |
| `SoundCatalog.shared` | SoundCatalog.swift | Yes (`sounds`, `favorites`) | Via `@MainActor` (⚠️ missing `shared`) |
| `SubscriptionServiceSK2.shared` | SubscriptionServiceSK2.swift | Yes (`subscriptionStatus`, etc.) | Via `@MainActor` |
| `AnalyticsService.shared` | AnalyticsService.swift | Yes (`isEnabled`) | Via `@MainActor` |
| `HapticManager.shared` | HapticManager.swift | No | Via `@MainActor` |
| `HapticManager.shared` ⚠️ | MiniPlayerView.swift | No | ❌ Not `@MainActor` |
| `FavoritesManager.shared` | NowPlayingView.swift | Yes | ❌ Unknown |

---

*End of Audit Report*
