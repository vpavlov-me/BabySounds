# 🚀 BabySounds DevOps Setup Commands

Complete CLI command reference for setting up production-ready iOS development environment.

## 📋 Table of Contents

1. [Initial Setup](#1-initial-setup)
2. [Development Environment](#2-development-environment)
3. [Git Configuration](#3-git-configuration)
4. [Code Quality Tools](#4-code-quality-tools)
5. [CI/CD Setup](#5-cicd-setup)
6. [Release Management](#6-release-management)
7. [Daily Development](#7-daily-development)

---

## 1. Initial Setup

### Clone and Bootstrap Project

```bash
# Clone repository
git clone https://github.com/vpavlov-me/BabySounds.git
cd BabySounds

# One-command bootstrap (installs everything)
make bootstrap

# Alternative: Manual setup
make install-dependencies
make setup-git
make setup-hooks
```

### Verify Installation

```bash
# Check all dependencies
make check-deps

# Display project information
make project-info

# Show available commands
make help
```

---

## 2. Development Environment

### Install Dependencies

```bash
# Install via Homebrew
brew install swiftlint swiftformat fastlane git-lfs xcpretty

# Install Ruby gems
gem install danger danger-swiftlint danger-xcode_summary

# Verify installations
swiftlint version
swiftformat --version
fastlane --version
git lfs version
```

### Xcode Setup

```bash
# Open workspace
make open
# or manually:
open BabySoundsDemo.xcworkspace

# Select Xcode version (if multiple installed)
sudo xcode-select --switch /Applications/Xcode_15.4.app/Contents/Developer

# Verify Xcode configuration
xcodebuild -version
```

---

## 3. Git Configuration

### Git LFS Setup

```bash
# Initialize Git LFS
git lfs install

# Track audio files (already configured in .gitattributes)
git lfs track "*.mp3"
git lfs track "*.wav"
git lfs track "*.aac"
git lfs track "*.m4a"

# Verify LFS tracking
git lfs track
```

### Branch Setup

```bash
# Create develop branch (if not exists)
git checkout -b develop
git push -u origin develop

# Set develop as default branch on GitHub
gh repo edit --default-branch develop

# Create feature branch
make create-feature BRANCH=new-audio-engine

# Create release branch
make create-release VERSION=1.2.0

# Create hotfix branch
make create-hotfix VERSION=1.1.1
```

### Pre-commit Hooks

```bash
# Install pre-commit hook
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Test pre-commit hook
git add .
git commit -m "test: verify pre-commit hook"
```

---

## 4. Code Quality Tools

### SwiftLint Configuration

```bash
# Run linting
make lint
# or directly:
swiftlint lint --config .swiftlint.yml --strict

# Auto-fix issues
make fix-lint
# or directly:
swiftlint --fix --config .swiftlint.yml
```

### SwiftFormat Configuration

```bash
# Format code
make format
# or directly:
swiftformat . --config .swiftformat

# Check formatting (without changes)
swiftformat --config .swiftformat --lint .
```

### Combined Quality Check

```bash
# Run all quality checks
make quality

# This runs:
# 1. SwiftFormat
# 2. SwiftLint
# 3. Unit tests
```

---

## 5. CI/CD Setup

### GitHub Secrets Configuration

```bash
# Required secrets for GitHub Actions:

# App Store Connect API Key (base64 encoded .p8 file)
APP_STORE_CONNECT_API_KEY=LS0tLS1CRUdJTi...

# App Store Connect credentials
APP_STORE_CONNECT_KEY_ID=ABCD123456
APP_STORE_CONNECT_ISSUER_ID=12345678-1234-1234-1234-123456789012

# iOS Distribution Certificate (base64 encoded .p12 file)
IOS_DISTRIBUTION_CERTIFICATE=MIIKyAIBAzCCCoQG...
IOS_CERTIFICATE_PASSWORD=your_certificate_password

# iOS Provisioning Profile (base64 encoded .mobileprovision)
IOS_PROVISIONING_PROFILE=MIIMQwYJKoZIhvc...

# Optional: Slack webhook for notifications
SLACK_WEBHOOK=https://hooks.slack.com/services/...
```

### Encode Certificates for GitHub Secrets

```bash
# Encode App Store Connect API key
base64 -i AuthKey_ABCD123456.p8 | pbcopy

# Encode distribution certificate
base64 -i distribution_certificate.p12 | pbcopy

# Encode provisioning profile
base64 -i BabySounds_App_Store.mobileprovision | pbcopy
```

### Verify CI/CD Workflows

```bash
# Check workflow syntax
gh workflow list

# Run workflow manually (if needed)
gh workflow run "iOS Build & Test"

# View workflow status
gh run list
```

---

## 6. Release Management

### Version Management

```bash
# Patch version (1.0.0 → 1.0.1)
make bump-patch

# Minor version (1.0.0 → 1.1.0)  
make bump-minor

# Major version (1.0.0 → 2.0.0)
make bump-major

# Manual version bump via Fastlane
fastlane bump_version type:patch
```

### Release Process

```bash
# Complete release (patch)
make release-patch

# This performs:
# 1. Version bump
# 2. Quality checks
# 3. Build and test
# 4. Deploy to TestFlight
# 5. Create GitHub release

# Manual release steps
fastlane release type:patch

# Upload to TestFlight only
make testflight
```

### Hotfix Process

```bash
# Create hotfix branch
make create-hotfix VERSION=1.0.1

# Apply fixes, then:
git add .
git commit -m "fix: critical security issue"

# Deploy hotfix
fastlane hotfix version:1.0.1 description:"Critical security fix"
```

---

## 7. Daily Development

### Building and Testing

```bash
# Clean build
make clean

# Build project
make build

# Run unit tests
make test

# Run tests on all devices
make test-all

# Build release version
make build-release
```

### Git Workflow

```bash
# Start new feature
git checkout develop
git pull origin develop
make create-feature BRANCH=audio-improvements

# Work on feature
git add .
git commit -m "feat: add new audio engine"

# Push feature branch
git push -u origin feature/audio-improvements

# Create pull request
gh pr create --title "feat: improve audio engine" --body "Adds new multi-track audio capabilities"

# Merge after approval (via GitHub UI or CLI)
gh pr merge --squash --delete-branch
```

### Code Quality Maintenance

```bash
# Daily quality check
make quality

# Fix common issues
make fix-lint
make format

# Check project statistics
make size

# Monitor dependencies
make check-deps
```

### Development Helpers

```bash
# Open simulator
make simulator

# View device logs
make logs

# Open Xcode workspace
make open

# Show project info
make project-info
```

---

## 📋 GitHub Actions Workflow Examples

### Trigger Build Manually

```bash
# Trigger iOS build workflow
gh workflow run "iOS Build & Test" --ref develop

# Trigger release workflow (requires tag)
git tag v1.0.1
git push origin v1.0.1
```

### Monitor CI/CD Status

```bash
# List recent workflow runs
gh run list

# View specific run details
gh run view [RUN_ID]

# Download artifacts
gh run download [RUN_ID]
```

---

## 🚨 Emergency Procedures

### Hotfix Deployment

```bash
# Emergency hotfix in <30 minutes
git checkout main
git pull origin main
make create-hotfix VERSION=1.0.1

# Apply critical fix
git add .
git commit -m "fix: resolve crash on iOS 17.5"

# Quick quality check
make lint
make test

# Deploy immediately
git push origin hotfix/1.0.1
# Creates PR → auto-merge → TestFlight upload
```

### Rollback Release

```bash
# If release has issues, rollback via:
# 1. TestFlight: Disable problematic build
# 2. GitHub: Create hotfix with revert
git revert [COMMIT_HASH]
git tag v1.0.2
git push origin v1.0.2
```

---

## 🔧 Troubleshooting

### Common Issues

**Build Failures:**
```bash
make clean
make build
```

**Linting Errors:**
```bash
make fix-lint
make format
```

**Git LFS Issues:**
```bash
git lfs fetch
git lfs pull
```

**Fastlane Errors:**
```bash
fastlane --verbose
# Check fastlane/Fastfile for configuration
```

### Reset Development Environment

```bash
# Complete reset
rm -rf ~/Library/Developer/Xcode/DerivedData/BabySounds*
make clean
make bootstrap

# Reset Git hooks
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

---

## 📚 Additional Resources

### Documentation Commands

```bash
# Generate documentation
make docs

# View code coverage
make coverage

# Analyze code quality
make analyze
```

### Useful Aliases

Add to your `~/.zshrc` or `~/.bash_profile`:

```bash
# BabySounds development aliases
alias bs="cd ~/path/to/BabySounds"
alias bsb="make build"
alias bst="make test"
alias bsq="make quality"
alias bsr="make release-patch"
alias bso="make open"
```

---

**Ready for production development!** 🚀

All commands tested and verified for BabySounds DevOps infrastructure. 