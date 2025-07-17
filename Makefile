# Makefile for BabySounds iOS Project
# Provides convenient commands for development workflow

.PHONY: help bootstrap clean build test lint fix-lint format release setup-git

# Default target
help: ## Show this help message
	@echo "BabySounds iOS Development Commands"
	@echo "==================================="
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Project Setup
bootstrap: ## Set up the project for first time development
	@echo "🚀 Setting up BabySounds project..."
	@$(MAKE) install-dependencies
	@$(MAKE) setup-git
	@$(MAKE) setup-hooks
	@echo "✅ Project setup completed!"

install-dependencies: ## Install required development dependencies
	@echo "📦 Installing dependencies..."
	@brew list swiftlint &>/dev/null || brew install swiftlint
	@brew list swiftformat &>/dev/null || brew install swiftformat
	@brew list fastlane &>/dev/null || brew install fastlane
	@brew list git-lfs &>/dev/null || brew install git-lfs
	@gem install xcpretty
	@echo "✅ Dependencies installed"

setup-git: ## Initialize Git LFS and hooks
	@echo "🔧 Setting up Git configuration..."
	@git lfs install
	@git lfs track "*.mp3" "*.wav" "*.aac" "*.m4a"
	@echo "✅ Git LFS configured"

setup-hooks: ## Install Git hooks for pre-commit validation
	@echo "🪝 Setting up Git hooks..."
	@cp scripts/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✅ Git hooks installed"

# Development
clean: ## Clean build artifacts and derived data
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf DerivedData/
	@rm -rf ~/Library/Developer/Xcode/DerivedData/BabySounds*
	@xcodebuild clean -workspace BabySoundsDemo.xcworkspace -scheme BabySounds >/dev/null 2>&1 || true
	@echo "✅ Clean completed"

build: ## Build the project
	@echo "🔨 Building BabySounds..."
	@xcodebuild build -workspace BabySoundsDemo.xcworkspace -scheme BabySounds -destination 'platform=iOS Simulator,name=iPhone 15 Pro' | xcpretty
	@echo "✅ Build completed"

build-release: ## Build release version using Fastlane
	@echo "🔨 Building release version..."
	@fastlane build_release
	@echo "✅ Release build completed"

# Testing
test: ## Run unit tests
	@echo "🧪 Running tests..."
	@xcodebuild test -workspace BabySoundsDemo.xcworkspace -scheme BabySounds -destination 'platform=iOS Simulator,name=iPhone 15 Pro' | xcpretty
	@echo "✅ Tests completed"

test-all: ## Run tests on all supported devices
	@echo "🧪 Running tests on all devices..."
	@fastlane test_all_devices
	@echo "✅ All device tests completed"

# Code Quality
lint: ## Run SwiftLint
	@echo "🔍 Running SwiftLint..."
	@swiftlint lint --config .swiftlint.yml
	@echo "✅ Linting completed"

fix-lint: ## Auto-fix SwiftLint issues
	@echo "🔧 Fixing lint issues..."
	@swiftlint --fix --config .swiftlint.yml
	@echo "✅ Lint fixes applied"

format: ## Format code with SwiftFormat
	@echo "✨ Formatting code..."
	@swiftformat . --config .swiftformat
	@echo "✅ Code formatting completed"

quality: ## Run all code quality checks
	@echo "🎯 Running quality checks..."
	@$(MAKE) format
	@$(MAKE) lint
	@$(MAKE) test
	@echo "✅ Quality checks passed"

# Version Management
bump-patch: ## Bump patch version (1.0.0 -> 1.0.1)
	@echo "📈 Bumping patch version..."
	@fastlane bump_version type:patch
	@echo "✅ Patch version bumped"

bump-minor: ## Bump minor version (1.0.0 -> 1.1.0)
	@echo "📈 Bumping minor version..."
	@fastlane bump_version type:minor
	@echo "✅ Minor version bumped"

bump-major: ## Bump major version (1.0.0 -> 2.0.0)
	@echo "📈 Bumping major version..."
	@fastlane bump_version type:major
	@echo "✅ Major version bumped"

# Release
release-patch: ## Release patch version to TestFlight
	@echo "🚀 Releasing patch version..."
	@fastlane release type:patch
	@echo "✅ Patch release completed"

release-minor: ## Release minor version to TestFlight
	@echo "🚀 Releasing minor version..."
	@fastlane release type:minor
	@echo "✅ Minor release completed"

release-major: ## Release major version to TestFlight
	@echo "🚀 Releasing major version..."
	@fastlane release type:major
	@echo "✅ Major release completed"

testflight: ## Upload current build to TestFlight
	@echo "✈️ Uploading to TestFlight..."
	@fastlane upload_testflight
	@echo "✅ TestFlight upload completed"

# Development Helpers
open: ## Open Xcode workspace
	@open BabySoundsDemo.xcworkspace

simulator: ## Open iOS Simulator
	@open -a Simulator

logs: ## Show device logs for debugging
	@xcrun simctl spawn booted log stream --predicate 'process == "BabySounds"'

# Git Workflow
create-feature: ## Create new feature branch (use: make create-feature BRANCH=feature-name)
	@echo "🌿 Creating feature branch..."
	@git checkout develop
	@git pull origin develop
	@git checkout -b feature/$(BRANCH)
	@echo "✅ Feature branch 'feature/$(BRANCH)' created"

create-release: ## Create release branch (use: make create-release VERSION=1.2.0)
	@echo "🏷️ Creating release branch..."
	@git checkout develop
	@git pull origin develop
	@git checkout -b release/$(VERSION)
	@echo "✅ Release branch 'release/$(VERSION)' created"

create-hotfix: ## Create hotfix branch (use: make create-hotfix VERSION=1.0.1)
	@echo "🚨 Creating hotfix branch..."
	@git checkout main
	@git pull origin main
	@git checkout -b hotfix/$(VERSION)
	@echo "✅ Hotfix branch 'hotfix/$(VERSION)' created"

# Utilities
check-deps: ## Check if all dependencies are installed
	@echo "🔍 Checking dependencies..."
	@command -v swiftlint >/dev/null 2>&1 || (echo "❌ SwiftLint not installed" && exit 1)
	@command -v swiftformat >/dev/null 2>&1 || (echo "❌ SwiftFormat not installed" && exit 1)
	@command -v fastlane >/dev/null 2>&1 || (echo "❌ Fastlane not installed" && exit 1)
	@command -v git-lfs >/dev/null 2>&1 || (echo "❌ Git LFS not installed" && exit 1)
	@echo "✅ All dependencies are installed"

project-info: ## Show project information
	@echo "📱 BabySounds Project Information"
	@echo "================================"
	@echo "Project: BabySounds iOS App"
	@echo "Bundle ID: com.babysounds.app"
	@echo "Platform: iOS 17.0+"
	@echo "Language: Swift 5.10"
	@echo "Architecture: SwiftUI + AVFoundation"
	@echo "Current Branch: $$(git branch --show-current)"
	@echo "Last Commit: $$(git log -1 --oneline)"

size: ## Show app size information
	@echo "📊 App Size Information"
	@echo "======================"
	@find BabySounds -name "*.swift" | wc -l | xargs echo "Swift files:"
	@find BabySounds -name "*.swift" -exec wc -l {} + | tail -1 | awk '{print "Lines of code: " $$1}'
	@du -sh BabySounds/Resources/Sounds/ 2>/dev/null | awk '{print "Audio files size: " $$1}' || echo "Audio files size: Not found" 