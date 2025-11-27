# BabySounds - AI Development Guide

> Quick reference for Claude and other AI tools when working with the BabySounds project

## 📋 Project Overview

**BabySounds** - iOS app for baby sleep with professional sounds and parental controls.

- **Platform**: iOS 17.0+
- **Language**: Swift 6.0
- **UI**: SwiftUI
- **Architecture**: MVVM + Swift Package Manager
- **Status**: v1.0 at 95% (App Store preparation)

### Key Metrics
- 12,907 lines of Swift code
- 48 unit tests
- Zero external dependencies
- COPPA compliant, WHO hearing safety guidelines

---

## 🏗 Project Architecture

### Directory Structure

```
BabySounds/
├── Package.swift                    # SPM manifest
├── BabySounds/Sources/BabySounds/  # Main app (12,907 LOC)
│   ├── App/                        # App entry point
│   ├── Core/                       # Business logic
│   │   ├── Audio/                  # Audio engine (1,780 LOC)
│   │   │   ├── AudioEngineManager.swift      (799 LOC)
│   │   │   ├── SafeVolumeManager.swift       (477 LOC)
│   │   │   └── BackgroundAudioManager.swift  (504 LOC)
│   │   ├── Data/                   # Data managers
│   │   └── Models/                 # Data models
│   ├── Features/                   # Feature screens
│   │   ├── Sleep/                  # Sound library
│   │   ├── Playroom/               # Child-friendly interface
│   │   ├── Favorites/              # Saved sounds
│   │   ├── Schedules/              # Sleep schedules
│   │   ├── Settings/               # App settings
│   │   ├── ParentalControls/       # Parental controls
│   │   └── Subscription/           # StoreKit 2
│   ├── Services/                   # External services
│   ├── UI/                         # Reusable components
│   └── Resources/                  # Audio files, JSON
├── Packages/                       # SPM modules
│   ├── BabySoundsCore/            # Core library
│   └── BabySoundsUI/              # UI components
└── docs/                          # Documentation
```

### Key Components

1. **Audio System** (1,780 LOC)
   - Multi-track playback (up to 4 tracks simultaneously)
   - WHO volume safety compliance
   - Fade-in/fade-out effects
   - Background playback + Now Playing integration

2. **Premium System**
   - StoreKit 2 integration
   - Feature gating (Favorites, Timer, Custom Mixes)
   - Monthly $4.99 / Annual $29.99

3. **Parental Controls**
   - Math challenges
   - Parent gate for protected actions
   - 5-minute timeout after verification

4. **Sleep Schedules**
   - Automated sound playback
   - Weekday repeat patterns
   - Notification integration

---

## 🔧 Technical Requirements

### Required

- macOS 14.0 (Sonoma) or later
- Xcode 15.4 or later
- Swift 6.0
- Git

### Recommended

- GitHub CLI (`gh`)
- SwiftLint (linting)
- SwiftFormat (formatting)

### Environment Check

```bash
# Xcode version
xcodebuild -version  # Should be 15.4+

# Swift version
swift --version      # Should be 6.0+

# Git
git --version
```

---

## 🚀 Quick Start for AI Development

### 1. Opening the Project

```bash
cd /Users/pavlov/Documents/Vibecoding/BabySounds/BabySounds
open Package.swift
```

### 2. Build and Run

```bash
# Build
swift build

# Run tests
swift test

# In Xcode
# Cmd+B - Build
# Cmd+R - Run
# Cmd+U - Test
```

### 3. Scheme Structure

- **BabySoundsApp** - main app scheme
- Recommended simulator: iPhone 15 Pro

---

## 📝 Git Workflow

### Post-v1.0 Workflow (CURRENT)

**IMPORTANT**: After v1.0 release, use the develop → main workflow

#### Branch Strategy

- `main` - production-ready code, protected
- `develop` - integration branch for testing
- `feature/*` - feature development branches (optional)

#### Standard Workflow

```bash
# 1. Start work in develop branch
git checkout develop
git pull origin develop

# 2. Make changes and commit
git add .
git commit -m "feat(scope): description"

# 3. Push to develop
git push origin develop

# 4. Wait for CI/CD to pass (CRITICAL!)
# Check GitHub Actions for:
# - ✅ SwiftLint check
# - ✅ Build & Test (iPhone 15 Pro, SE, iPad)
# - ✅ Security scan
# - ✅ Accessibility check
# - ✅ Kids compliance check

# 5. Once ALL tests pass in develop, create PR to main
gh pr create --base main --head develop \
  --title "Release: [version]" \
  --body "All tests passed in develop branch"

# 6. Merge PR after review
gh pr merge --merge
```

### Critical CI/CD Rules

🚨 **MANDATORY BEFORE MERGING TO MAIN:**

1. **All CI/CD checks MUST pass in `develop`**
   - SwiftLint (code quality)
   - Build & Test on 3 devices
   - Security scan (Trivy)
   - Accessibility check
   - Kids compliance check

2. **Never merge to `main` if ANY test fails**
   - Fix the issue in `develop`
   - Wait for green checkmarks
   - Then create PR

3. **Monitor GitHub Actions**
   ```bash
   # Check workflow status
   gh run list --branch develop

   # View specific run
   gh run view [run-id]
   ```

### Rules for Develop Branch

✅ **DO:**
- Push all changes to `develop` first
- Wait for CI/CD to pass
- Fix any failing tests immediately
- Keep commits atomic and focused
- Use conventional commit format

❌ **DON'T:**
- Push directly to `main` (protected)
- Merge to `main` with failing tests
- Skip CI/CD checks
- Commit work-in-progress

### Commit Message Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

**Types:**
- `feat` - new feature
- `fix` - bug fix
- `docs` - documentation
- `style` - code formatting
- `refactor` - code refactoring
- `test` - tests
- `chore` - maintenance

**Scopes:**
- `audio` - audio system
- `ui` - user interface
- `premium` - premium features
- `safety` - safety features (volume, parent gate)
- `schedule` - schedules
- `settings` - app settings
- `store` - purchases

**Examples:**
```bash
feat(audio): implement buffer scheduling for playback
fix(volume): correct WHO decibel calculation
docs: update README with new features
test: add unit tests for AudioEngineManager
```

### After v1.0 (Future)

After release, switch to feature branch workflow:
- `main` - production
- `develop` - integration
- `feature/*` - new features
- `fix/*` - bug fixes
- `hotfix/*` - critical fixes

---

## 💻 Coding Standards

### Swift Style Guide

Follow Apple Swift API Design Guidelines:

```swift
// Types: UpperCamelCase
class AudioEngineManager { }
struct Sound { }
enum SoundCategory { }

// Variables and functions: lowerCamelCase
var currentSound: Sound?
func playSound(_ sound: Sound) { }

// Constants: lowerCamelCase
let maxVolume = 1.0
let defaultFadeDuration = 2.0
```

### Swift 6 Requirements

❌ **FORBIDDEN:**
```swift
// Force unwrapping
let sound = sounds[id]!

// Implicitly unwrapped optionals
var currentSound: Sound!
```

✅ **CORRECT:**
```swift
// Optional binding
guard let sound = sounds[id] else { return }

// Explicit optionals
var currentSound: Sound?

// @MainActor for UI
@MainActor
class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
}
```

### Code Organization

```swift
// MARK: - Type Definition
class SoundManager {

    // MARK: - Properties
    private var sounds: [Sound] = []

    // MARK: - Initialization
    init() {
        loadSounds()
    }

    // MARK: - Public Methods
    func play(_ sound: Sound) {
        // Implementation
    }

    // MARK: - Private Methods
    private func loadSounds() {
        // Implementation
    }
}
```

### Accessibility

All UI must be accessible:

```swift
Button("Play Sound") { }
    .accessibilityLabel("Play white noise sound")
    .accessibilityHint("Double tap to start playing")
    .accessibilityAddTraits(.startsMediaSession)
```

---

## 🧪 Testing

**IMPORTANT:** This project uses **Swift Package Manager (SPM)** for testing, NOT Xcode test targets.

### Testing Architecture

- **Main app**: `BabySoundsApp.xcodeproj` - NO test targets here
- **Tests location**: `BabySounds/Tests/` - SPM test target only
- **Test command**: `swift test` - runs SPM tests

❌ **DO NOT:**
- Create test targets in `BabySoundsApp.xcodeproj`
- Add folders like `BabySoundsAppTests` or `BabySoundsAppUITests`
- Use Xcode's "Add Test Target" feature

✅ **CORRECT:**
- All tests live in `BabySounds/Tests/` folder
- Use `swift test` to run tests
- Tests are part of SPM package, not Xcode project

### Test Structure

```swift
import XCTest
@testable import BabySounds

final class SoundManagerTests: XCTestCase {

    var sut: SoundManager!

    override func setUp() {
        super.setUp()
        sut = SoundManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testPlaySound_WhenSoundExists_ReturnsTrue() {
        // Given
        let sound = Sound.whitenoise

        // When
        let result = sut.play(sound)

        // Then
        XCTAssertTrue(result)
    }
}
```

### Running Tests

```bash
# All tests (SPM)
swift test

# Specific test
swift test --filter AudioEngineManagerTests

# With coverage
swift test --enable-code-coverage
```

---

## 🎯 Rules for AI Assistant

### Always DO

1. **Read files before modifying**
   - Use `Read` tool before `Edit` or `Write`
   - Understand the context of changes

2. **Verify before committing**
   ```bash
   swift build  # Build without errors
   swift test   # All tests pass
   ```

3. **Follow conventions**
   - Swift 6 strict concurrency
   - No force unwrapping
   - MVVM architecture
   - Accessibility-first

4. **Document changes**
   - Add comments for complex logic
   - Update documentation when needed

### Never DO

❌ **FORBIDDEN:**
- Create files without necessity
- Use force unwrapping (`!`)
- Use implicitly unwrapped optionals (`!`)
- Commit unfinished code to main
- Push broken builds
- Ignore tests
- Add TODO comments (use Issues instead)
- Create test targets in Xcode project (BabySoundsApp.xcodeproj)
- Create simplified/demo versions of the app
- Add any test folders (BabySoundsAppTests, BabySoundsAppUITests, etc.)

### Security

- Check for vulnerabilities: XSS, SQL injection, command injection
- Follow WHO guidelines for volume
- COPPA compliance - no data from children
- Parent gate for all sensitive actions

### Common Tasks

**1. Adding a new feature:**
```bash
# 1. Create model in Core/Models/
# 2. Create ViewModel in Features/[Feature]/
# 3. Create View in Features/[Feature]/
# 4. Add tests in Tests/
# 5. Update documentation
```

**2. Fixing a bug:**
```bash
# 1. Reproduce the bug
# 2. Write failing test
# 3. Fix the code
# 4. Ensure test passes
# 5. Commit: fix(scope): description
```

**3. Refactoring:**
```bash
# 1. Ensure all tests pass
# 2. Perform refactoring
# 3. Ensure tests still pass
# 4. Commit: refactor(scope): description
```

---

## 📚 Key Files Reference

### Core Logic

- `AudioEngineManager.swift` (799 LOC) - multi-track audio engine
- `SafeVolumeManager.swift` (477 LOC) - WHO volume safety
- `BackgroundAudioManager.swift` (504 LOC) - background playback
- `PremiumManager.swift` - feature gating
- `ParentGateManager.swift` - parental controls
- `SleepScheduleManager.swift` - schedules

### Data Models

- `Sound.swift` - sound objects
- `SoundCategory.swift` - sound categories
- `SleepSchedule.swift` - schedules

### UI Components

- `SoundCard.swift` - sound card
- `MiniPlayerView.swift` - mini player
- `NowPlayingView.swift` - full-screen player

---

## 🔍 Useful Commands

### Code Search

```bash
# Find TODO (should be none!)
grep -r "TODO" --include="*.swift" .

# Find Cyrillic text
grep -r "[А-Яа-я]" --include="*.swift" .

# Count lines of code
find . -name "*.swift" -not -path "./Tests/*" | xargs wc -l

# Find force unwrapping
grep -r "!" --include="*.swift" . | grep -v "!="
```

### Debugging

```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# List simulators
xcrun simctl list devices

# Boot simulator
xcrun simctl boot "iPhone 15 Pro"
```

### Git Commands

```bash
# Status
git status
git log --oneline -10

# Revert changes
git restore <file>
git restore .

# Undo last commit (keep changes)
git reset --soft HEAD~1
```

---

## 🎨 Project Features

### Audio System

- **AVAudioEngine** with 4 player nodes
- Fade-in/fade-out effects
- Individual volume + pan control
- Gapless looping
- WHO volume limits (30-75%)

### Premium Features

- Unlimited Favorites (Free: 5)
- Extended Timer (Free: 30 min)
- Custom Mixes (4 tracks)
- StoreKit 2 integration

### Safety Features

- WHO hearing safety guidelines
- Parent gate (math challenges)
- Listening time tracking
- Safe link wrapper
- COPPA compliance

### Playroom Mode

- Large, child-friendly buttons
- Child-appropriate sound filtering
- Simple, colorful interface

---

## 📊 Current Status (v1.0 - 95%)

### ✅ Complete

- Audio engine with multi-track
- WHO volume safety
- 5-tab interface (Apple Music style)
- Parent gate with analytics
- Sleep schedule management
- Premium feature gating (StoreKit 2)
- 15 professional sounds
- Privacy Policy & Terms of Service
- Settings screen
- 48 unit tests
- Playroom content filtering
- English localization
- GitHub Pages documentation

### 🚧 Remaining for v1.0

- App Store assets (screenshots, icon) - Issue #20
- Final testing

---

## 🚨 Critical Rules

### 1. NEVER Break the Build

```bash
# Before committing ALWAYS:
swift build && swift test
```

### 2. Test Critical Features

- Audio playback
- Volume safety
- Premium feature gating
- Parent gate verification
- Schedule triggers

### 3. Child Safety is Priority

- Volume always within WHO limits (30-75%)
- Parent gate for all external links
- No data collection from children (COPPA)
- Child-appropriate content in Playroom

### 4. Accessibility is Mandatory

- VoiceOver labels on all buttons
- Dynamic Type support
- High Contrast Mode
- Reduce Motion respect

---

## 📖 Additional Resources

### Project Documentation

- [README.md](README.md) - general overview
- [CONTRIBUTING.md](CONTRIBUTING.md) - contribution guide
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - architecture
- [docs/SETUP.md](docs/SETUP.md) - setup guide
- [docs/GIT_WORKFLOW.md](docs/GIT_WORKFLOW.md) - git workflow
- [APP_STORE.md](APP_STORE.md) - App Store preparation

### Apple Documentation

- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [AVFoundation](https://developer.apple.com/documentation/avfoundation)
- [StoreKit 2](https://developer.apple.com/documentation/storekit)

### GitHub

- [Issues](https://github.com/vpavlov-me/BabySounds/issues)
- [Discussions](https://github.com/vpavlov-me/BabySounds/discussions)
- [Milestone v1.0](https://github.com/vpavlov-me/BabySounds/milestone/1)

---

## 🤖 Template for AI Prompts

When working with the project, use this context:

```
Project: BabySounds
Language: Swift 6.0, SwiftUI
Architecture: MVVM, SPM
iOS: 17.0+
Status: v1.0 (95% complete)

Rules:
- Work in main branch
- No force unwrapping (!)
- @MainActor for UI
- Accessibility-first
- WHO volume safety
- COPPA compliance
- Test before commit

Current task: [description]
Files: [list]
```

---

## ✅ Pre-Commit Checklist

```bash
# 1. Build without errors
swift build
# ✅ Build succeeded

# 2. All tests pass
swift test
# ✅ All tests passed

# 3. No force unwrapping
grep -r "!" --include="*.swift" BabySounds/Sources | grep -v "!=" | wc -l
# ✅ 0 results (or only safe cases)

# 4. No TODO comments
grep -r "TODO" --include="*.swift" BabySounds/Sources | wc -l
# ✅ 0 results

# 5. Conventional commit message
git commit -m "feat(scope): clear description"
# ✅ Follows convention

# 6. Push to main
git push origin main
# ✅ Pushed successfully
```

---

**Last Updated**: November 2024
**Document Version**: 1.0
**Author**: Vadim Pavlov (@vpavlov-me)

---

*Made with ❤️ for better baby sleep*
