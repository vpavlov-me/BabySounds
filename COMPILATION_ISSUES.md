# Compilation Issues to Fix

This document outlines remaining compilation issues that need to be addressed before the project can build successfully.

## Issues Found

### 1. Missing @available Attributes in AudioEngineManager

**File**: `Packages/BabySoundsCore/Sources/Audio/AudioEngineManager.swift`

**Problem**: The class uses iOS 10.15+ APIs without proper @available attributes.

**Errors**:
- Line 92: `ObservableObject` is only available in macOS 10.15 or newer
- Line 113: `Task` is only available in macOS 10.15 or newer
- Line 119: `@Published` is only available in macOS 10.15 or newer
- Line 122: `@Published` is only available in macOS 10.15 or newer

**Solution**: Add @available attribute to the class:
```swift
@available(iOS 17.0, macOS 10.15, *)
@MainActor
public final class AudioEngineManager: ObservableObject {
```

### 2. Duplicate Method Declaration

**File**: `Packages/BabySoundsCore/Sources/Audio/AudioEngineManager.swift`

**Problem**: `updateNowPlayingInfo()` method is declared twice.

**Error**: Line 572: invalid redeclaration of 'updateNowPlayingInfo()'

**Solution**: Remove the stub method declaration or merge with the actual implementation in the BackgroundAudioManager extension.

### 3. Invalid @objc Usage

**File**: `Packages/BabySoundsCore/Sources/Audio/AudioEngineManager.swift`

**Problem**: @objc attribute used on methods that aren't part of a class in Swift 6.

**Errors**:
- Line 614: `@objc private func handleAudioRouteChangedForSafety()`
- Line 622: `@objc private func handleVolumeWarning(notification: Notification)`

**Solution**: These methods are in a `final class`, which is correct. The error suggests they might be in an extension context. Verify the class structure and ensure @objc is only used where needed for Objective-C interop (NotificationCenter selectors).

### 4. Russian Text in Code

**Files**:
- `Packages/BabySoundsCore/Sources/Models/SleepSchedule.swift`

**Problem**: Contains Russian text in default values and error messages, but the app should be English-only for v1.0.

**Examples**:
- Line 20: `name: String = "Мое расписание сна"` (should be "My Sleep Schedule")
- Line 93: `return "Каждый день"` (should be "Every day")
- Line 95: `return "Будни"` (should be "Weekdays")
- Lines 125-132: Russian weekday names
- Lines 137-144: Russian short weekday names
- Lines 166-172: Russian error messages

**Solution**: Replace all Russian text with English equivalents for v1.0 launch.

## Priority

1. **High**: Fix @available attributes (prevents compilation)
2. **High**: Fix duplicate method declaration (prevents compilation)
3. **High**: Fix @objc usage (prevents compilation)
4. **Medium**: Replace Russian text with English (needed for v1.0)

## Next Steps

1. Add `@available(iOS 17.0, macOS 10.15, *)` to AudioEngineManager
2. Remove duplicate `updateNowPlayingInfo()` declaration
3. Review @objc method contexts and fix as needed
4. Replace all Russian text in SleepSchedule.swift with English
5. Run `swift build` to verify fixes
6. Run `swift test` to ensure tests pass

## Notes

The repository cleanup was successful:
- ✅ Removed 725MB of build artifacts from git tracking
- ✅ Removed duplicate documentation files (PROJECT_SUMMARY.md, SCREENSHOTS.md)
- ✅ Updated README to reflect 95% v1.0 completion
- ✅ Fixed public/internal access control in BabySoundsCore models
- ✅ Updated CHANGELOG with v0.95.0 release

The .gitignore already properly excludes .build/ directory, so future builds won't be tracked.
