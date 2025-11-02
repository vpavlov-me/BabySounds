# Changelog

All notable changes to BabySounds will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned for v1.0 (95% Complete)
- App Store assets (screenshots, icon)
- Final testing and bug fixes

### Planned for v1.1
- Custom sound mixes
- Offline sound pack downloads
- Multi-language support
- Expanded sound library
- Advanced analytics

### Planned for v2.0
- Audio equalizer
- Spatial audio effects
- Community features
- Advanced mixing controls

## [0.95.0] - 2025-11-02

### Added
- Privacy-compliant analytics service (OSLog-based)
- Comprehensive settings screen with all features
- Child-appropriate content filtering in Playroom
- Unit tests for core managers (48 tests passing)
- Complete English localization
- GitHub Pages documentation site

### Changed
- Updated project status to 95% complete for v1.0
- Consolidated documentation (removed duplicate files)
- Improved .gitignore to exclude build artifacts

### Fixed
- Build artifacts no longer tracked in git

## [0.9.0] - 2025-11-01

### Added
- Initial project structure with Swift Package Manager
- 5-tab Apple Music-style interface
- Audio engine with multi-track support (up to 4 simultaneous tracks)
- WHO-compliant volume safety system
- Parent gate with math challenges and memory tests
- Sleep schedule management UI
- Premium subscription system (StoreKit 2)
- 14 professional sleep sounds (MP3)
- Favorites management
- Playroom mode for children
- Mini player with progress tracking
- Full-screen now playing view
- Background audio playback support
- Now Playing information center integration
- Safe link wrapper for external URLs
- Notification permission management
- Accessibility support (VoiceOver, Dynamic Type)

### Core Components Implemented
- `AudioEngineManager.swift` (799 LOC) - Multi-track audio engine
- `SafeVolumeManager.swift` (477 LOC) - WHO hearing safety
- `BackgroundAudioManager.swift` (504 LOC) - Background playback
- `PremiumManager.swift` - Subscription feature gating
- `ParentGateManager.swift` - Parental controls
- `SleepScheduleManager.swift` - Schedule automation
- `SoundCatalog.swift` - Sound library management
- 48 Swift source files totaling 12,907 lines of code

### Documentation
- README with comprehensive feature list
- CONTRIBUTING guide
- CODE_OF_CONDUCT
- MIT LICENSE
- Privacy Policy
- Terms of Service
- GitHub issue templates
- GitHub Pages setup

### Infrastructure
- GitHub Issues created for v1.0 milestones
- Project labels and milestones configured
- CI/CD preparation (workflows pending)

## [0.5.0] - 2025-10-XX

### Added
- Initial Swift Package structure
- Basic SwiftUI views
- Sound model definitions
- Audio file resources

## [0.1.0] - 2025-10-XX

### Added
- Project initialization
- Repository setup
- Basic documentation

---

## Release Notes Format

### Categories
- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

### Version Numbers
- **Major** (X.0.0): Breaking changes
- **Minor** (0.X.0): New features, backwards compatible
- **Patch** (0.0.X): Bug fixes, backwards compatible

---

[unreleased]: https://github.com/vpavlov-me/BabySounds/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/vpavlov-me/BabySounds/releases/tag/v0.9.0
