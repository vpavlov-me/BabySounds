# Contributing to BabySounds 🍼

Welcome to the BabySounds development team! This guide will help you contribute effectively to our Kids Category iOS app.

## 📋 Table of Contents

- [Development Setup](#development-setup)
- [Git Workflow](#git-workflow)
- [Code Standards](#code-standards)
- [Kids Category Compliance](#kids-category-compliance)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)
- [Release Process](#release-process)

## 🚀 Development Setup

### Prerequisites

- **Xcode 15.4+** with iOS 17.0+ SDK
- **macOS Ventura 13.0+**
- **Homebrew** for dependency management

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/vpavlov-me/BabySounds.git
cd BabySounds

# Run bootstrap script
make bootstrap

# Open workspace
make open
```

### Required Tools

The bootstrap script will install:
- SwiftLint (code linting)
- SwiftFormat (code formatting)
- Fastlane (deployment automation)
- Git LFS (large file support)

### Manual Installation

```bash
# Install dependencies
brew install swiftlint swiftformat fastlane git-lfs

# Setup Git LFS
git lfs install
git lfs track "*.mp3" "*.wav" "*.aac" "*.m4a"

# Install pre-commit hooks
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## 🌿 Git Workflow

We follow a **Git Flow** strategy with strict branch protection:

### Branch Structure

```
main              # Production releases only
├── develop       # Integration branch for features
├── feature/*     # Feature development
├── release/*     # Release preparation
└── hotfix/*      # Emergency fixes
```

### Branch Naming

- **Feature branches**: `feature/{task-id}-{short-description}`
- **Release branches**: `release/{version}`
- **Hotfix branches**: `hotfix/{version}`

Examples:
```bash
feature/123-audio-engine-improvements
feature/456-new-sound-category
release/1.2.0
hotfix/1.1.1
```

### Creating Branches

```bash
# Feature branch
make create-feature BRANCH=audio-improvements

# Release branch
make create-release VERSION=1.2.0

# Hotfix branch
make create-hotfix VERSION=1.1.1
```

### Branch Protection Rules

- **main**: Requires 2 approvals, CI passing, no direct pushes
- **develop**: Requires 1 approval, CI passing, no direct pushes
- All PRs must be up-to-date with base branch

## 📝 Code Standards

### SwiftLint Configuration

We enforce strict coding standards:

- **Line length**: 120 characters
- **Function length**: 50 lines (warning), 80 lines (error)
- **Type length**: 300 lines (warning), 400 lines (error)
- **Cyclomatic complexity**: 10 (warning), 15 (error)

### Code Formatting

```bash
# Format code
make format

# Check formatting
swiftformat --config .swiftformat --lint .
```

### Naming Conventions

```swift
// Classes and Structs: PascalCase
class AudioEngineManager { }
struct SoundCatalog { }

// Variables and Functions: camelCase
var currentVolume: Float
func playSound(_ sound: Sound) { }

// Constants: PascalCase for types, camelCase for instances
static let maxVolumeLevel = 0.85
let defaultFadeDuration: TimeInterval = 1.0

// Enums: PascalCase with lowercase cases
enum PlaybackState {
    case playing
    case paused
    case stopped
}
```

### File Organization

```swift
// File header (required)
//
//  AudioEngineManager.swift
//  BabySounds
//
//  Created by Developer on 01/01/2024.
//  Copyright © 2024 BabySounds. All rights reserved.
//

import Foundation
import AVFoundation

// MARK: - Main Class
class AudioEngineManager: ObservableObject {
    
    // MARK: - Properties
    @Published var isPlaying = false
    
    // MARK: - Initialization
    init() {
        setupEngine()
    }
    
    // MARK: - Public Methods
    func playSound(_ sound: Sound) {
        // Implementation
    }
    
    // MARK: - Private Methods
    private func setupEngine() {
        // Implementation
    }
}

// MARK: - Extensions
extension AudioEngineManager {
    // Related functionality
}
```

## 👶 Kids Category Compliance

**CRITICAL**: All changes must comply with Kids Category requirements:

### Data Collection

❌ **NEVER collect**:
- Names, emails, addresses
- Location data
- User behavior analytics
- Personal information

✅ **Allowed**:
- Anonymous usage statistics
- Crash reports (no PII)
- App version/device info

### External Content

❌ **NEVER include**:
- Direct web links
- Social media integration
- Unmoderated content
- Third-party ads

✅ **Required**:
- SafeLinkWrapper for any URLs
- Parental gate before external access
- Age-appropriate content only

### Code Examples

```swift
// ❌ WRONG: Direct URL access
Button("Visit Website") {
    UIApplication.shared.open(URL(string: "https://example.com")!)
}

// ✅ CORRECT: Protected URL access
SafeLinkWrapper(url: "https://example.com", 
                requiresParentGate: true) {
    Button("Visit Website") {
        // Safe link will handle parental gate
    }
}

// ❌ WRONG: Data collection
UserDefaults.standard.set(userEmail, forKey: "email")

// ✅ CORRECT: Anonymous preferences only
UserDefaults.standard.set(selectedTheme, forKey: "theme_preference")
```

### Compliance Checklist

Before every PR:
- [ ] No personal data collection
- [ ] All URLs use SafeLinkWrapper
- [ ] Content is age-appropriate (5 & under)
- [ ] No external analytics/tracking
- [ ] Parental gates implemented correctly
- [ ] Accessibility attributes added

## 🔄 Pull Request Process

### Before Creating PR

1. **Run quality checks**:
   ```bash
   make quality  # Runs format, lint, and tests
   ```

2. **Ensure compliance**:
   - Kids Category requirements met
   - Accessibility attributes added
   - No hardcoded strings (use localization)

3. **Update documentation**:
   - Add CHANGELOG.md entry for user-facing changes
   - Update README.md if needed

### PR Template

Use this checklist for every PR:

```markdown
## 📋 Changes

- [ ] Feature/Bug description
- [ ] Related issue: #123

## 🧪 Testing

- [ ] Unit tests added/updated
- [ ] Manual testing completed
- [ ] Tested on iPhone and iPad
- [ ] Accessibility testing done

## 👶 Kids Category Compliance

- [ ] No personal data collection
- [ ] External URLs use SafeLinkWrapper
- [ ] Content age-appropriate
- [ ] Parental gates implemented

## ♿ Accessibility

- [ ] All UI elements have accessibility labels
- [ ] VoiceOver tested
- [ ] High contrast tested
- [ ] Large text tested

## 📱 Devices Tested

- [ ] iPhone SE (3rd gen)
- [ ] iPhone 15 Pro
- [ ] iPad (10th gen)
- [ ] iOS 17.0 minimum

## 📝 Additional Notes

[Any specific testing instructions or considerations]
```

### PR Size Guidelines

- **Small** (<200 lines): ✅ Preferred
- **Medium** (200-500 lines): ⚠️ Acceptable with good description
- **Large** (>500 lines): 🚨 Should be split into smaller PRs

### Review Process

1. **Automated Checks**: CI/CD must pass
2. **Code Review**: 1-2 approvals required
3. **QA Testing**: Manual verification
4. **Compliance Review**: Kids Category validation

## 🧪 Testing Guidelines

### Unit Testing

```bash
# Run tests
make test

# Run tests on all devices
make test-all
```

### Test Structure

```swift
import XCTest
@testable import BabySounds

class AudioEngineTests: XCTestCase {
    
    var audioEngine: AudioEngineManager!
    
    override func setUp() {
        super.setUp()
        audioEngine = AudioEngineManager()
    }
    
    override func tearDown() {
        audioEngine = nil
        super.tearDown()
    }
    
    func testPlaySound() {
        // Given
        let sound = Sound.mock()
        
        // When
        audioEngine.playSound(sound)
        
        // Then
        XCTAssertTrue(audioEngine.isPlaying)
    }
}
```

### Accessibility Testing

Always test with:
- **VoiceOver** enabled
- **High Contrast** mode
- **Large Text** sizes
- **Voice Control**

### Manual Testing Checklist

For every feature:
- [ ] iPhone SE (smallest screen)
- [ ] iPhone 15 Pro (standard)
- [ ] iPad (tablet interface)
- [ ] Portrait and landscape
- [ ] Light and dark mode
- [ ] Various text sizes
- [ ] VoiceOver navigation

## 🚀 Release Process

### Version Bumping

```bash
# Patch release (1.0.0 → 1.0.1)
make bump-patch

# Minor release (1.0.0 → 1.1.0)
make bump-minor

# Major release (1.0.0 → 2.0.0)
make bump-major
```

### Release Workflow

1. **Create release branch**: `release/1.2.0`
2. **Update CHANGELOG.md** with release notes
3. **Bump version** using make commands
4. **Create PR** to main branch
5. **Tag release** after merge: `v1.2.0`
6. **GitHub Actions** automatically deploys to TestFlight

### Hotfix Process

```bash
# Create hotfix branch from main
make create-hotfix VERSION=1.1.1

# Make fixes, test thoroughly
make quality

# Create PR, merge, and tag
git tag v1.1.1
git push origin --tags
```

## 📞 Getting Help

### Common Issues

**Build errors**:
```bash
make clean
make build
```

**Linting failures**:
```bash
make fix-lint
```

**Test failures**:
```bash
make test
# Check logs for specific issues
```

### Development Commands

```bash
make help              # Show all available commands
make project-info      # Display project information
make check-deps        # Verify dependencies
make size              # Show project statistics
```

### Contact

- **Issues**: Create GitHub issue with bug/feature template
- **Questions**: Use GitHub Discussions
- **Security**: Contact maintainers privately

## 🎯 Quality Standards

We maintain high standards for:

- **Code Quality**: SwiftLint score >90%
- **Test Coverage**: >80% for business logic
- **Performance**: <2s app launch time
- **Accessibility**: 100% VoiceOver compatible
- **Kids Compliance**: Zero tolerance for violations

## 📚 Resources

- [Swift Style Guide](https://swift.org/documentation/api-design-guidelines/)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Kids Category Guidelines](https://developer.apple.com/app-store/kids-apps/)
- [COPPA Compliance](https://www.ftc.gov/enforcement/rules/rulemaking-regulatory-reform-proceedings/childrens-online-privacy-protection-rule)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)

Thank you for contributing to BabySounds! 🍼✨ 