# Contributing to BabySounds 🤝

Thank you for your interest in contributing to BabySounds! This document provides guidelines and instructions for contributing to the project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Guidelines](#issue-guidelines)

## Code of Conduct

This project adheres to a Code of Conduct that all contributors are expected to follow. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

## Getting Started

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15.4 or later
- Swift 6.0
- Git
- GitHub account
- GitHub CLI (optional, but recommended)

### Setting Up Development Environment

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/BabySounds.git
   cd BabySounds
   ```

3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/vpavlov-me/BabySounds.git
   ```

4. **Open in Xcode**:
   ```bash
   open Package.swift
   ```

5. **Build the project**:
   - Select the `BabySoundsApp` scheme
   - Choose an iOS simulator (iPhone 15 Pro recommended)
   - Press Cmd+B to build

6. **Run tests**:
   ```bash
   swift test
   # Or press Cmd+U in Xcode
   ```

### Project Structure

Familiarize yourself with the project structure:

```
BabySounds/
├── BabySounds/Sources/BabySounds/   # Main app source
│   ├── App/                         # App entry point
│   ├── Core/                        # Core business logic
│   ├── Features/                    # Feature screens
│   ├── Services/                    # External services
│   ├── UI/                          # Reusable UI components
│   └── Resources/                   # Assets and data files
├── Packages/                         # Swift Package modules
└── Tests/                           # Test files
```

## Development Workflow

### Branching Strategy

**IMPORTANT**: Until v1.0 release, we work directly in the `main` branch for speed and simplicity.

**Current Phase (Pre-v1.0)**:
- Work directly in `main` branch
- Commit frequently with clear messages
- Test before pushing
- No broken builds in main

**Future Phase (Post-v1.0)**:
- Feature branch workflow with `develop` branch
- All features in separate branches
- Pull requests required
- Code review before merge

See detailed workflow: [GIT_WORKFLOW.md](docs/GIT_WORKFLOW.md)

### 1. Find or Create an Issue

- Browse [existing issues](https://github.com/vpavlov-me/BabySounds/issues)
- Comment on an issue you want to work on
- Wait for maintainer approval before starting work
- If no issue exists for your contribution, create one first

### 2. Work in Main (Current - Pre-v1.0)

Until v1.0 release, work directly in main:

```bash
# Update main branch
git checkout main
git pull origin main

# Make changes
# ... edit files ...

# Test your changes
swift test

# Commit with clear message
git add .
git commit -m "feat(audio): add buffer scheduling"

# Push to main
git push origin main
```

### 3. Future: Create Feature Branch (Post-v1.0)

After v1.0, use feature branches:

```bash
# Update develop branch
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/42-your-feature-name

# Or for bug fixes
git checkout -b fix/38-bug-description
```

Branch naming conventions (Post-v1.0):
- `feature/ISSUE-description` - New features
- `fix/ISSUE-description` - Bug fixes
- `hotfix/ISSUE-description` - Critical production fixes
- `docs/description` - Documentation updates
- `test/description` - Test additions
- `refactor/description` - Code refactoring
- `chore/description` - Maintenance tasks

### 3. Make Your Changes

- Write clean, readable code
- Follow Swift and SwiftUI best practices
- Add tests for new functionality
- Update documentation as needed
- Ensure code builds without warnings

### 4. Test Your Changes

```bash
# Run all tests
swift test

# Run specific test
swift test --filter TestClassName

# In Xcode
# Press Cmd+U to run all tests
```

### 5. Commit Your Changes

Follow our commit message guidelines (see below):

```bash
git add .
git commit -m "feat: add new sound mixing feature"
```

### 6. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 7. Create Pull Request

- Go to your fork on GitHub
- Click "New Pull Request"
- Fill out the PR template completely
- Link related issues
- Request review from maintainers

## Coding Standards

### Swift Style Guide

We follow Apple's Swift API Design Guidelines with some additions:

#### General Principles

- **Clarity at the point of use** is your most important goal
- **Clarity is more important than brevity**
- Write code that is self-documenting
- Use meaningful, descriptive names

#### Naming Conventions

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

// Private properties: leading underscore optional
private var isPlaying = false
```

#### Code Organization

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

#### Swift 6 Requirements

- **No force unwrapping**: Use optional binding or provide defaults
  ```swift
  // Bad
  let sound = sounds[id]!

  // Good
  guard let sound = sounds[id] else { return }
  ```

- **Explicit optionals**: Don't hide optionals with implicitly unwrapped optionals
  ```swift
  // Bad
  var currentSound: Sound!

  // Good
  var currentSound: Sound?
  ```

- **Strict concurrency**: Use `@MainActor` appropriately
  ```swift
  @MainActor
  class AudioPlayer: ObservableObject {
      @Published var isPlaying = false
  }
  ```

#### SwiftUI Best Practices

```swift
// Extract reusable views
struct SoundCard: View {
    let sound: Sound

    var body: some View {
        VStack {
            // Simple view body
        }
    }
}

// Keep views small and focused
// Use @ViewBuilder for complex layouts
// Prefer composition over inheritance
```

### Documentation

Add documentation comments for:
- All public APIs
- Complex algorithms
- Non-obvious code

```swift
/// Plays a sound with optional fade-in effect.
///
/// - Parameters:
///   - sound: The sound to play
///   - fadeDuration: Duration of fade-in in seconds (default: 2.0)
/// - Returns: True if playback started successfully
func playSound(_ sound: Sound, fadeDuration: TimeInterval = 2.0) -> Bool {
    // Implementation
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

## Testing Guidelines

### Test Coverage

- Aim for at least 60% code coverage
- All new features must include tests
- Bug fixes should include regression tests

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

### What to Test

- **Unit Tests**: Core business logic, managers, models
- **Integration Tests**: Feature flows, data persistence
- **UI Tests**: Critical user journeys (optional but encouraged)

### Running Tests

```bash
# All tests
swift test

# Specific test
swift test --filter AudioEngineManagerTests

# With coverage
swift test --enable-code-coverage
```

## Commit Message Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/):

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(audio): add multi-track mixing support

Implement support for playing up to 4 audio tracks simultaneously
with individual volume control for each track.

Closes #42
```

```
fix(volume): correct WHO volume limit calculation

The previous calculation was using incorrect decibel conversion.
Updated to use proper logarithmic scale.

Fixes #38
```

```
docs(readme): update installation instructions

Add details about Xcode version requirements and Swift Package setup.
```

### Guidelines

- Use present tense ("add feature" not "added feature")
- Use imperative mood ("move cursor to..." not "moves cursor to...")
- Capitalize first letter of subject
- No period at end of subject
- Limit subject line to 50 characters
- Wrap body at 72 characters
- Reference issues and pull requests in footer

## Pull Request Process

### Before Submitting

- [ ] Code builds without warnings
- [ ] All tests pass
- [ ] New tests added for new functionality
- [ ] Documentation updated
- [ ] Code follows style guidelines
- [ ] Commit messages follow guidelines
- [ ] No merge conflicts with main branch

### PR Template

When creating a PR, fill out the template completely:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issues
Closes #issue_number

## Testing
How was this tested?

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Code follows style guide
```

### Review Process

1. Maintainer will review within 2-3 business days
2. Address any requested changes
3. Once approved, maintainer will merge
4. Branch will be deleted after merge

### After Merge

- Pull latest main branch
- Delete your feature branch locally
- Close related issues if not auto-closed

## Issue Guidelines

### Creating Issues

Use appropriate issue templates:

- **Bug Report**: For reporting bugs
- **Feature Request**: For suggesting new features
- **v1.0 Blocker**: For critical v1.0 issues

### Writing Good Issues

**Bug Reports** should include:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Environment details (iOS version, device)
- Screenshots if applicable

**Feature Requests** should include:
- Problem the feature solves
- Proposed solution
- Alternative solutions considered
- Priority assessment

### Issue Labels

Labels help organize and prioritize work:

- `v1-blocker`: Critical for v1.0 release
- `critical`, `high`, `medium`, `low`: Priority levels
- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Documentation improvements
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention needed

## Questions?

- Check existing [GitHub Discussions](https://github.com/vpavlov-me/BabySounds/discussions)
- Create a new discussion if your question is unique
- For bugs, create an issue instead

## Recognition

Contributors will be:
- Listed in release notes
- Mentioned in CHANGELOG.md
- Added to CONTRIBUTORS.md

Thank you for contributing to BabySounds! 🎵
