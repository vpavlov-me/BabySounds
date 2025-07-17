# Changelog

All notable changes to BabySounds iOS app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- DevOps infrastructure setup
- Comprehensive CI/CD pipeline
- Code quality automation

### Changed
- Project structure optimization for team development

### Security
- Enhanced Kids Category compliance checks

## [1.0.0] - 2024-01-XX

### Added
- 🎵 Professional multi-track audio engine with AVAudioEngine
- 📻 Background audio playback with Now Playing integration
- 📊 Complete JSON data system with real-time UI synchronization
- 💎 Premium subscription system with StoreKit 2
- 🔒 Advanced parental controls with multiple challenge types
- 🛡️ Comprehensive child safety and hearing protection
- ⏰ Sleep schedules with local notifications
- 🌍 Full English + Russian localization
- 👶 Kids Category compliance (COPPA safe)

### Audio Features
- Multi-track mixing (up to 4 concurrent sounds)
- Professional fade-in/out with configurable durations
- Per-track gain, pan, and loop controls
- Scheduled stops with async/await Tasks
- Audio file caching and validation system
- TrackHandle system for precise playback control

### Safety & Compliance
- WHO Guidelines compliance (85dB/70% volume maximum)
- 4-level volume warning system
- Listening session tracking with break reminders
- Parental gate protection for settings and purchases
- SafeLinkWrapper for external URL protection
- No data collection from children

### Premium Features
- 8 distinct premium features with smart gating
- Monthly ($4.99) and Annual ($29.99) subscription plans
- 7-day free trial for both plans
- Real-time transaction updates and receipt validation
- Premium sound library access
- Extended timer functionality (unlimited vs 30min free)
- Unlimited favorites (vs 5 free)
- Multiple sleep schedules (vs 1 free)

### Development
- SwiftUI + AVFoundation architecture
- Comprehensive error handling and logging
- Professional code organization with MVVM pattern
- Extensive debug and testing infrastructure
- App Store Connect ready configuration

### Security
- Parental gate with 6 usage contexts
- 5 challenge types (Math, Reading, Time, Text input)
- Security: 3 attempts → 1 minute lockout
- 30-second timeout with visual countdown
- No external analytics or tracking

---

## Release Types

- **Major** (X.0.0): Breaking changes, major new features
- **Minor** (x.Y.0): New features, non-breaking changes
- **Patch** (x.y.Z): Bug fixes, minor improvements

## Categories

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

## Links

- [App Store Connect](https://appstoreconnect.apple.com)
- [TestFlight](https://testflight.apple.com)
- [Kids Category Guidelines](https://developer.apple.com/app-store/kids-apps/) 