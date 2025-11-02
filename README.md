# BabySounds 🍼🎵

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![GitHub Issues](https://img.shields.io/github/issues/vpavlov-me/BabySounds)](https://github.com/vpavlov-me/BabySounds/issues)
[![GitHub Stars](https://img.shields.io/github/stars/vpavlov-me/BabySounds)](https://github.com/vpavlov-me/BabySounds/stargazers)

> **Baby sleep sounds app with Apple Music-inspired interface**

A modern, enterprise-grade iOS app designed to help babies and children sleep better through soothing sounds, backed by WHO hearing safety guidelines and powerful parental controls.

## ✨ Features

### 🎵 Audio Experience
- **15 Professional Sounds** - White noise, nature sounds, lullabies, and more
- **Multi-track Playback** - Up to 4 simultaneous sounds with individual volume control
- **Smart Audio Engine** - Fade-in/fade-out effects, gapless looping
- **Background Playback** - Continues playing when device is locked
- **Now Playing Integration** - Control from lock screen and Control Center

### 🎨 User Interface
- **Apple Music Design** - Modern 5-tab interface (Sleep, Playroom, Favorites, Schedules, Settings)
- **Mini Player** - Persistent player with progress bar across all tabs
- **Full-Screen Now Playing** - Immersive experience with 300×300 artwork
- **Playroom Mode** - Large, child-friendly buttons for direct interaction
- **Favorites Management** - Quick access to most-used sounds

### 🔒 Safety & Parental Controls
- **WHO-Compliant Volume Limits** - Automatic volume monitoring and restrictions
- **Listening Time Tracking** - Recommendations for breaks after prolonged use
- **Parent Gate** - Math challenges and memory tests to prevent unauthorized actions
- **Protected Links** - All external links require parental verification
- **Safe by Design** - COPPA compliant, no data collection from children

### ⏰ Sleep Schedules
- **Automated Playback** - Schedule sounds to start at bedtime automatically
- **Repeat Patterns** - Daily or custom day-of-week schedules
- **Notification Integration** - Gentle reminders at scheduled times
- **Multiple Schedules** - Different routines for naps and nighttime

### 💎 Premium Features
- **Unlimited Favorites** - Free: 5, Premium: Unlimited
- **Extended Timer** - Free: 30 min, Premium: Unlimited
- **Custom Mixes** - Create personalized sound combinations
- **Offline Downloads** - Save sounds for use without internet (Coming in v1.1)
- **Advanced Controls** - Fine-tune volume, pan, and effects for each track

### ♿ Accessibility
- **VoiceOver Support** - Full screen reader compatibility
- **Dynamic Type** - Scales text to user preferences
- **High Contrast Mode** - Enhanced visibility options
- **Reduce Motion** - Respects animation preferences  

## 📱 Screenshots

*Coming soon - app screenshots will be added here*

## 🚀 Requirements

### User Requirements
- iOS 17.0 or later
- iPhone or iPad

### Developer Requirements
- **macOS** 14.0 (Sonoma) or later
- **Xcode** 15.4 or later
- **Swift** 6.0
- **GitHub CLI** (optional, for issue management)

## 🛠 Development

### Quick Start

```bash
# Clone the repository
git clone https://github.com/vpavlov-me/BabySounds.git
cd BabySounds

# Open in Xcode (Swift Package structure)
open Package.swift
```

### Project Structure

```
BabySounds/
├── Package.swift                    # Swift Package manifest
├── BabySounds/                      # Main app target
│   ├── Sources/BabySounds/         # 12,907 lines of Swift code
│   │   ├── App/                    # App entry point & root views
│   │   ├── Core/                   # Business logic
│   │   │   ├── Audio/              # Audio engine (1,780 LOC)
│   │   │   ├── Data/               # Managers
│   │   │   └── Models/             # Data models
│   │   ├── Features/               # Feature screens
│   │   │   ├── Sleep/              # Sound library
│   │   │   ├── Playroom/           # Child-friendly interface
│   │   │   ├── Favorites/          # Saved sounds
│   │   │   ├── Schedules/          # Sleep schedules
│   │   │   ├── Settings/           # App settings
│   │   │   ├── ParentalControls/   # Parent gate
│   │   │   └── Subscription/       # StoreKit 2 integration
│   │   ├── Services/               # External services
│   │   ├── UI/                     # Reusable components
│   │   └── Resources/              # Audio files, JSON
│   └── Tests/                      # Unit tests
├── Packages/                        # SPM modules
│   ├── BabySoundsCore/             # Core library
│   ├── BabySoundsUI/               # UI components library
│   └── Tests/
├── docs/                            # Documentation
└── .github/                         # GitHub configuration
    ├── ISSUE_TEMPLATE/              # Issue templates
    └── workflows/                   # CI/CD (future)
```

### Building & Running

```bash
# Build for simulator
swift build

# Run tests
swift test

# Or use Xcode
# 1. Open Package.swift in Xcode
# 2. Select BabySoundsApp scheme
# 3. Choose simulator (iPhone 15 Pro recommended)
# 4. Press Cmd+R to build and run
```

### Running Tests

```bash
# Command line
swift test

# Xcode
# Press Cmd+U to run all tests
```

## 📊 Current Status

### v1.0 Progress: 95% Complete 🎉

**All Core Features Complete**:
- ✅ Audio engine with multi-track mixing and fade effects
- ✅ WHO-compliant volume safety system (30-75% limit, listening time tracking)
- ✅ 5-tab Apple Music-style interface
- ✅ Parent gate with math challenges + analytics
- ✅ Sleep schedule management with notifications
- ✅ Premium feature gating (StoreKit 2)
- ✅ Complete sound library (15/15 sounds)
- ✅ Privacy Policy & Terms of Service views
- ✅ Settings screen (safety, premium, privacy, about)
- ✅ Privacy-compliant analytics (OSLog only, COPPA compliant)
- ✅ Unit tests (48 tests for core managers)
- ✅ Playroom content filtering (child-appropriate sounds)
- ✅ English localization
- ✅ GitHub Pages documentation ([vpavlov-me.github.io/BabySounds](https://vpavlov-me.github.io/BabySounds))

**Remaining for v1.0** (See [Issues](https://github.com/vpavlov-me/BabySounds/issues)):
- 📝 Update documentation (Issue #18) - IN PROGRESS
- 📝 Create GitHub Wiki with technical guides (Issue #19)
- 🎨 App Store assets preparation (Issue #20)

See [Milestone v1.0](https://github.com/vpavlov-me/BabySounds/milestone/1) for complete task list.

## 📝 Code Quality

This project follows industry best practices:

- **Swift 6** - Latest language features with strict concurrency
- **SwiftUI** - Modern declarative UI framework
- **MVVM Architecture** - Clear separation of concerns
- **No Force Unwrapping** - Safe, crash-free code
- **Accessibility-First** - VoiceOver and Dynamic Type throughout
- **WHO Guidelines** - Hearing safety for children
- **COPPA Compliant** - Child-safe data practices

### Code Statistics
- **13,000+ lines** of Swift code
- **50+ source files**
- **48 unit tests** for core managers (SafeVolume, Premium, SleepSchedule)
- **Privacy-first analytics** with OSLog (no external SDK)
- **Zero TODO markers** in production code (all tracked in Issues)

## 🏪 App Store Preparation

This app is designed for the **Kids Category** with:

### Compliance
- ✅ **COPPA** - No data collection from children under 13
- ✅ **WHO Hearing Safety** - Volume limits and monitoring
- ✅ **Parental Controls** - Parent gate for all sensitive actions
- ✅ **Privacy First** - Minimal data collection, transparent policies

### App Store Requirements
- [ ] App Store assets (icons, screenshots) - [Issue #20](https://github.com/vpavlov-me/BabySounds/issues/20)
- [ ] Privacy policy published - [Issue #12](https://github.com/vpavlov-me/BabySounds/issues/12)
- [ ] Terms of service published - [Issue #12](https://github.com/vpavlov-me/BabySounds/issues/12)
- [ ] StoreKit testing complete - [Issue #10](https://github.com/vpavlov-me/BabySounds/issues/10)
- [ ] TestFlight beta testing (planned)

## 🗺 Roadmap

### v1.0 (Target: 2-3 weeks)
Focus: Core functionality and App Store launch
- Complete audio playback
- Finish StoreKit 2 integration
- English localization only
- Basic unit tests
- Legal documentation

### v1.1 (Target: Q1 2025)
Focus: Enhanced features
- Custom sound mixes
- Offline downloads
- Expanded sound library
- Multi-language support
- Advanced analytics

### v2.0 (Target: Q2 2025)
Focus: Advanced audio
- Equalizer
- Audio effects (reverb, spatial audio)
- Sound customization
- Community features

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Contribution Guide

1. Check [open issues](https://github.com/vpavlov-me/BabySounds/issues)
2. Comment on an issue you'd like to work on
3. Fork the repository
4. Create a feature branch: `git checkout -b feature/amazing-feature`
5. Commit changes: `git commit -m 'Add amazing feature'`
6. Push to branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Areas Needing Help
- 🎨 UI/UX improvements
- 🧪 Test coverage
- 📝 Documentation
- 🌍 Localization
- 🎵 Sound library expansion
- 🐛 Bug fixes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📚 Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [Development Setup](docs/SETUP.md)
- [Privacy Policy](https://vpavlov-me.github.io/BabySounds/privacy-policy)
- [Terms of Service](https://vpavlov-me.github.io/BabySounds/terms-of-service)
- [GitHub Wiki](https://github.com/vpavlov-me/BabySounds/wiki)

## 🔗 Links

- [App Store](https://apps.apple.com/app/babysounds) (Coming soon)
- [Report an Issue](https://github.com/vpavlov-me/BabySounds/issues/new/choose)
- [Discussions](https://github.com/vpavlov-me/BabySounds/discussions)

## 👨‍💻 Author

**Vadim Pavlov** - [GitHub](https://github.com/vpavlov-me)

## 🙏 Acknowledgments

- Apple's SwiftUI and AVFoundation frameworks
- WHO for hearing safety guidelines
- All contributors and beta testers

---

**Made with ❤️ for better baby sleep**

*BabySounds - Helping families sleep better, one sound at a time.* 