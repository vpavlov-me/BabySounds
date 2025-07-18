# BabySounds 🍼🎵

[![iOS Build](https://github.com/vpavlov-me/BabySounds/actions/workflows/ios-build.yml/badge.svg)](https://github.com/vpavlov-me/BabySounds/actions/workflows/ios-build.yml)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)
[![iOS 17.0+](https://img.shields.io/badge/iOS-17.0+-blue)](https://developer.apple.com/ios/)
[![Kids Category](https://img.shields.io/badge/Category-Kids-green)](https://developer.apple.com/app-store/kids-apps/)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen)](https://swift.org/package-manager/)

> **Production-Ready Kids Category iOS App** - Professional sleep aid app for children with modular Swift Package Manager architecture.

## 🏗 Project Architecture

The project is organized with a **Feature-First** approach and modular architecture via SPM:

```
BabySounds/
├── 📱 BabySounds/        # Main application (SwiftUI + Swift 6)
├── 📦 Packages/          # SPM modules (Core + UI)
├── 🛠 Tools/            # DevOps tools
├── 📚 Examples/         # Usage examples
└── 📖 docs/            # Complete documentation
```

**Detailed documentation:** [📁 Project Structure](docs/PROJECT_STRUCTURE.md)

## 🚀 Quick Start

### Requirements
- **Xcode 15.4+** (iOS 17 SDK)
- **Swift 6.0+** 
- **macOS Ventura 13.0+**
- Apple Developer Account (for StoreKit)

### Installation

```bash
# Clone the project
git clone https://github.com/vpavlov-me/BabySounds.git
cd BabySounds

# Automatic setup
make bootstrap

# Alternative: manual setup
swift package resolve
```

### Building and Testing

```bash
# Build all modules
swift build

# Run tests
swift test

# Code checking
make lint

# Formatting
make format
```

## 📦 SPM Modules

### BabySoundsCore
Core business logic without UI dependencies:
- 🔊 AudioEngine management
- 📊 Data services and models  
- ⚡ Utilities and extensions

### BabySoundsUI  
Reusable SwiftUI components:
- 🧩 UI Components
- 🎨 Design System
- ♿ Accessibility support

## 🎯 Key Features

- **🎵 Audio Engine** - AVAudioEngine with 4+ sound support
- **⏰ Sleep Schedules** - Smart sleep scheduling
- **💳 StoreKit 2** - Subscriptions without third-party SDKs
- **👨‍👩‍👧‍👦 Parental Gate** - Child safety
- **🌍 Localization** - EN/RU with support for new languages
- **♿ Accessibility** - VoiceOver and Switch Control

## 📋 Development Commands

```bash
# Development
make dev          # Start development server
make test         # All tests
make test-ui      # UI tests
make clean        # Clean build

# Code quality  
make lint         # SwiftLint check
make format       # SwiftFormat auto-format
make danger       # Danger PR checks

# Deployment
make build        # Release build
make archive      # Archive for App Store
fastlane beta     # TestFlight upload
```

## 📖 Documentation

- **[📁 Project Structure](docs/PROJECT_STRUCTURE.md)** - Architecture and organization
- **[🔧 Technical Documentation](docs/technical/)** - Deep dive  
- **[👨‍💻 Contributing Guide](docs/development/CONTRIBUTING.md)** - Development workflow
- **[🏪 App Store Materials](docs/app-store/)** - Release procedures
- **[🚀 Refactoring Report](docs/REFACTORING_SUMMARY.md)** - Work completed

## ✅ Project Principles

### 1. **Swift 6 + SwiftUI-only**
- No UIKit/Storyboard
- No force unwrap
- Async/await for asynchronous operations

### 2. **Feature-First Architecture**  
- Each feature is a separate folder
- Structure: `Feature > Data > UI > Tests`
- Clear boundaries

### 3. **Kids Category Compliance**
- COPPA compliance
- Parental controls
- Safe volume (WHO guidelines)
- No third-party trackers

### 4. **Production Quality**
- Comprehensive testing (Unit/UI/Integration)
- CI/CD via GitHub Actions + Fastlane
- Automatic code quality control
- StoreKit testing

## 🤝 Contributing

We welcome contributions to the project! 

1. **Read** [Contributing Guide](docs/development/CONTRIBUTING.md)
2. **Create** feature branch
3. **Follow** code style (SwiftLint + SwiftFormat)
4. **Add** tests for new functionality
5. **Create** Pull Request

## 📄 License

MIT License. Details in [LICENSE](LICENSE) file.

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/vpavlov-me/BabySounds/issues)
- **Documentation:** [docs/](docs/)
- **Email:** support@babysounds.app

---

**Made with ❤️ for children and their parents** 