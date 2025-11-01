---
layout: default
title: Development Setup Guide
---

# BabySounds Development Setup Guide

Complete guide to setting up your development environment for contributing to BabySounds.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Setup](#project-setup)
- [Running the App](#running-the-app)
- [Testing](#testing)
- [Common Issues](#common-issues)
- [Development Workflow](#development-workflow)

## Prerequisites

### Required Software

1. **macOS** 14.0 (Sonoma) or later
2. **Xcode** 15.4 or later
3. **Git** (included with Xcode Command Line Tools)

### Optional but Recommended

4. **GitHub CLI** - For managing issues and PRs
5. **SwiftLint** - For code style checking
6. **SwiftFormat** - For code formatting

### Checking Your Environment

```bash
# Check macOS version
sw_vers

# Check Xcode version
xcodebuild -version

# Check Swift version
swift --version

# Check Git
git --version
```

Expected output:
```
Xcode 15.4 or later
Swift 6.0 or later
git version 2.39 or later
```

## Installation

### 1. Install Xcode

Download from the Mac App Store or [Apple Developer](https://developer.apple.com/xcode/).

After installation, open Xcode at least once to complete setup:
```bash
open -a Xcode
```

Install Command Line Tools:
```bash
xcode-select --install
```

### 2. Install GitHub CLI (Optional)

```bash
# Using Homebrew
brew install gh

# Authenticate
gh auth login
```

### 3. Install SwiftLint (Optional)

```bash
# Using Homebrew
brew install swiftlint

# Verify installation
swiftlint version
```

### 4. Install SwiftFormat (Optional)

```bash
# Using Homebrew
brew install swiftformat

# Verify installation
swiftformat --version
```

## Project Setup

### 1. Fork the Repository

1. Go to [github.com/vpavlov-me/BabySounds](https://github.com/vpavlov-me/BabySounds)
2. Click "Fork" button
3. Select your account

### 2. Clone Your Fork

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/BabySounds.git
cd BabySounds

# Add upstream remote
git remote add upstream https://github.com/vpavlov-me/BabySounds.git

# Verify remotes
git remote -v
```

Expected output:
```
origin    https://github.com/YOUR_USERNAME/BabySounds.git (fetch)
origin    https://github.com/YOUR_USERNAME/BabySounds.git (push)
upstream  https://github.com/vpavlov-me/BabySounds.git (fetch)
upstream  https://github.com/vpavlov-me/BabySounds.git (push)
```

### 3. Open the Project

BabySounds uses Swift Package Manager. Open the package:

```bash
open Package.swift
```

Or from within Xcode:
1. File > Open
2. Navigate to BabySounds directory
3. Select `Package.swift`
4. Click Open

### 4. Resolve Dependencies

Xcode will automatically resolve Swift Package dependencies. If not:

1. File > Packages > Resolve Package Versions
2. Wait for resolution to complete

### 5. Select Build Scheme

1. In Xcode toolbar, click scheme dropdown
2. Select `BabySoundsApp`
3. Select simulator (iPhone 15 Pro recommended)

## Running the App

### Using Xcode

1. **Build**: Cmd+B
2. **Run**: Cmd+R
3. **Stop**: Cmd+.

### Using Command Line

```bash
# Build for simulator
swift build

# Run on simulator (requires Xcode)
xcodebuild -scheme BabySoundsApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' run

# Build for release
swift build -c release
```

### Selecting a Simulator

Available simulators:
- iPhone 15 Pro (recommended)
- iPhone 15 Pro Max
- iPad Pro 12.9"
- iPad Air

To list all available simulators:
```bash
xcrun simctl list devices
```

To boot a specific simulator:
```bash
xcrun simctl boot "iPhone 15 Pro"
```

## Testing

### Running Tests in Xcode

1. **All Tests**: Cmd+U
2. **Single Test**: Click diamond next to test function
3. **Test Class**: Click diamond next to test class

### Running Tests from Command Line

```bash
# Run all tests
swift test

# Run specific test
swift test --filter BabySoundsTests.AudioEngineManagerTests

# Run with coverage
swift test --enable-code-coverage

# Generate coverage report
xcrun llvm-cov show \
  .build/debug/BabySoundsPackageTests.xctest/Contents/MacOS/BabySoundsPackageTests \
  -instr-profile .build/debug/codecov/default.profdata
```

### Test Structure

Tests are located in:
```
BabySounds/
└── Tests/
    └── BabySoundsTests/
        ├── AudioEngineManagerTests.swift
        ├── SafeVolumeManagerTests.swift
        ├── PremiumManagerTests.swift
        └── ...
```

## Common Issues

### Issue 1: "No such module 'BabySounds'"

**Solution**:
1. Clean build folder: Cmd+Shift+K
2. Close Xcode
3. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
4. Reopen project and build

### Issue 2: Simulator not appearing

**Solution**:
```bash
# Reset simulator list
xcrun simctl list devices | grep -v "unavailable"

# Create new simulator if needed
xcrun simctl create "iPhone 15 Pro" "iPhone 15 Pro" "iOS 17.0"
```

### Issue 3: Audio files not loading

**Solution**:
1. Check that all audio files exist in `BabySounds/Sources/BabySounds/Resources/Audio/`
2. Verify files are added to target in Project Navigator
3. Clean and rebuild

### Issue 4: Build fails with "Swift Compiler Error"

**Solution**:
```bash
# Update to latest Swift tools
xcode-select --install

# Check Swift version
swift --version

# Should be Swift 6.0 or later
```

### Issue 5: Code signing issues

**Solution**:
1. Select project in Project Navigator
2. Select BabySounds target
3. Signing & Capabilities tab
4. Select "Automatically manage signing"
5. Select your team

## Development Workflow

### 1. Keep Your Fork Updated

```bash
# Fetch latest changes from upstream
git fetch upstream

# Switch to main branch
git checkout main

# Merge upstream changes
git merge upstream/main

# Push to your fork
git push origin main
```

### 2. Create a Feature Branch

```bash
# Create and switch to new branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

### 3. Make Changes

1. Edit code in Xcode
2. Build frequently: Cmd+B
3. Test changes: Cmd+U
4. Format code (if SwiftFormat installed):
   ```bash
   swiftformat .
   ```

### 4. Commit Changes

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: add new sound mixing feature"

# Push to your fork
git push origin feature/your-feature-name
```

### 5. Create Pull Request

Using GitHub CLI:
```bash
gh pr create --title "Add sound mixing feature" --body "Description of changes"
```

Or via GitHub web interface:
1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. Fill out PR template
4. Submit PR

## Development Tools

### Xcode Shortcuts

| Action | Shortcut |
|--------|----------|
| Build | Cmd+B |
| Run | Cmd+R |
| Test | Cmd+U |
| Clean | Cmd+Shift+K |
| Find in Project | Cmd+Shift+F |
| Quick Open | Cmd+Shift+O |
| Jump to Definition | Cmd+Click |
| Show Documentation | Option+Click |

### Useful Commands

```bash
# Format all Swift files
swiftformat .

# Lint all Swift files
swiftlint

# Count lines of code
find . -name "*.swift" -not -path "./Tests/*" | xargs wc -l

# Search for TODO comments
grep -r "TODO" --include="*.swift" .

# Find Russian text (Cyrillic)
grep -r "[А-Яа-я]" --include="*.swift" .
```

## Debugging

### Print Debugging

```swift
// Use print for simple debugging
print("Current sound: \(sound.name)")

// Use debugPrint for detailed output
debugPrint(sound)

// Conditional breakpoint in code
assert(sound.category != nil, "Sound must have a category")
```

### Xcode Debugger

1. Set breakpoint: Click line number gutter
2. Run with debugger: Cmd+R
3. When breakpoint hits:
   - Step over: F6
   - Step into: F7
   - Continue: Cmd+Ctrl+Y
   - View variables: Debug area at bottom

### LLDB Commands

In Xcode debugger console:
```lldb
# Print variable
po sound

# Print expression
po sound.name

# Continue execution
c

# Step over
n

# Step into
s
```

## Performance Profiling

### Using Instruments

1. Product > Profile (Cmd+I)
2. Select instrument:
   - **Time Profiler**: CPU usage
   - **Allocations**: Memory usage
   - **Leaks**: Memory leaks
   - **Audio**: Audio performance
3. Record and analyze

### Memory Debugging

Enable Memory Graph in Xcode:
1. Run app
2. Click memory graph button in debug bar
3. View object graph and reference cycles

## Continuous Integration (Future)

GitHub Actions workflow (to be implemented):

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build and Test
        run: swift test
```

## Additional Resources

### Documentation
- [Architecture Guide](ARCHITECTURE.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [API Reference](https://github.com/vpavlov-me/BabySounds/wiki)

### Apple Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [AVFoundation Guide](https://developer.apple.com/documentation/avfoundation)
- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)

### Community
- [GitHub Discussions](https://github.com/vpavlov-me/BabySounds/discussions)
- [Issue Tracker](https://github.com/vpavlov-me/BabySounds/issues)

## Getting Help

If you encounter issues:

1. Check [Common Issues](#common-issues) section
2. Search [existing issues](https://github.com/vpavlov-me/BabySounds/issues)
3. Ask in [GitHub Discussions](https://github.com/vpavlov-me/BabySounds/discussions)
4. Create a [new issue](https://github.com/vpavlov-me/BabySounds/issues/new/choose)

---

**Happy coding!** 🎵

[Back to Home](index)
