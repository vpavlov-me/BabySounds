# 🛠️ GitHub Repository Setup Guide

## 🍼 BabySounds GitHub Configuration

Эта инструкция описывает полную настройку GitHub репозитория для BabySounds - Kids Category iOS приложения с учетом всех требований безопасности и соответствия.

## 📋 Repository Settings

### 🏠 General Settings

1. **Repository Name**: `BabySounds`
2. **Description**: `🍼 Professional Kids Category iOS app for baby sleep sounds with comprehensive DevOps infrastructure. COPPA compliant with zero data collection.`
3. **Website**: `https://babysounds.com`
4. **Topics**: 
   ```
   ios-app
   kids-category
   baby-sounds
   white-noise
   sleep-timer
   coppa-compliant
   swift
   swiftui
   xcode
   fastlane
   accessibility
   who-compliant
   ```

### 🔒 Security Settings

#### Branch Protection Rules

**Main Branch (`main`)**:
- ✅ Require pull request reviews before merging
  - Required reviewers: 2
  - Dismiss stale reviews when new commits are pushed
  - Require review from code owners
  - Restrict pushes that create new files matching CODEOWNERS
- ✅ Require status checks to pass before merging
  - Require branches to be up to date before merging
  - Status checks:
    - `SwiftLint`
    - `Build & Test (iPhone 15 Pro)`
    - `Build & Test (iPhone SE 3rd gen)`
    - `Build & Test (iPad 10th gen)`
    - `Danger Analysis`
    - `Accessibility Tests`
    - `Kids Category Compliance`
- ✅ Require conversation resolution before merging
- ✅ Require signed commits
- ✅ Require linear history
- ✅ Include administrators (no bypass for owners)
- ✅ Restrict pushes that create new files
- ✅ Allow force pushes: ❌ Never
- ✅ Allow deletions: ❌ Never

**Develop Branch (`develop`)**:
- ✅ Require pull request reviews before merging
  - Required reviewers: 1
  - Require review from code owners
- ✅ Require status checks to pass before merging
  - Same status checks as main
- ✅ Require conversation resolution before merging
- ✅ Require signed commits

#### Security & Analysis

- ✅ **Private vulnerability reporting**: Enabled
- ✅ **Dependency graph**: Enabled
- ✅ **Dependabot alerts**: Enabled
- ✅ **Dependabot security updates**: Enabled
- ✅ **Code scanning**: Enabled (CodeQL analysis)
- ✅ **Secret scanning**: Enabled
- ✅ **Push protection**: Enabled

### 🔑 Repository Secrets

Настройте следующие секреты в `Settings > Secrets and variables > Actions`:

#### iOS Development & Distribution
```bash
# Apple Developer Account
APPLE_ID="your-apple-id@email.com"
APPLE_ID_PASSWORD="app-specific-password"
TEAM_ID="XXXXXXXXXX"

# App Store Connect
ASC_KEY_ID="XXXXXXXXXX"
ASC_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
ASC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"

# Code Signing
MATCH_PASSWORD="your-match-password"
MATCH_GIT_URL="https://github.com/your-org/certificates"
MATCH_GIT_BASIC_AUTHORIZATION="base64-encoded-token"

# Distribution Certificates
DISTRIBUTION_CERTIFICATE="base64-encoded-p12"
DISTRIBUTION_CERTIFICATE_PASSWORD="certificate-password"
PROVISIONING_PROFILE="base64-encoded-mobileprovision"

# Keychain
KEYCHAIN_PASSWORD="secure-keychain-password"
```

#### CI/CD & Automation
```bash
# GitHub
GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx" # Fine-grained token
DANGER_GITHUB_API_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"

# Fastlane
FASTLANE_PASSWORD="your-apple-id-password"
FASTLANE_SESSION="base64-encoded-session"
FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="app-specific-password"

# TestFlight
PILOT_GROUPS="Internal,Beta Testers,Accessibility Team"

# Slack (for notifications)
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```

#### Kids Category Compliance
```bash
# Compliance Monitoring
COPPA_COMPLIANCE_CHECK_TOKEN="compliance-api-token"
KIDS_CATEGORY_AUDIT_KEY="audit-service-key"
WHO_HEARING_SAFETY_API_KEY="hearing-safety-api-key"

# Security
SECURITY_SCAN_TOKEN="security-scanner-token"
ACCESSIBILITY_TEST_TOKEN="accessibility-testing-token"
```

### 🚨 Dependabot Configuration

Создайте файл `.github/dependabot.yml`:

```yaml
version: 2
updates:
  # Swift Package Manager
  - package-ecosystem: "swift"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    assignees:
      - "vpavlov-me"
      - "ios-team-lead"
    reviewers:
      - "senior-dev"
      - "security-team"
    commit-message:
      prefix: "🔒"
      include: "scope"
    labels:
      - "dependencies"
      - "security"
    open-pull-requests-limit: 5

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "10:00"
    assignees:
      - "devops-lead"
    reviewers:
      - "vpavlov-me"
      - "ci-cd-specialist"
    commit-message:
      prefix: "🔧"
      include: "scope"
    labels:
      - "ci-cd"
      - "github-actions"
```

## 🏷️ Labels Configuration

### 🐛 Bug Labels
- `bug` (🔴 #d73a4a) - Something isn't working
- `critical-bug` (🔴 #b60205) - Critical bug affecting Kids safety
- `accessibility-bug` (🟡 #fbca04) - Accessibility issue
- `audio-bug` (🟠 #ff9500) - Audio playback issue

### ✨ Enhancement Labels
- `enhancement` (🟢 #0e8a16) - New feature or request
- `accessibility` (♿ #1d76db) - Accessibility improvement
- `performance` (⚡ #fef2c0) - Performance improvement
- `ui-ux` (🎨 #e99695) - User interface/experience

### 🔧 Technical Labels
- `dependencies` (📦 #0366d6) - Dependency updates
- `ci-cd` (🔧 #fbca04) - CI/CD related
- `github-actions` (⚙️ #0e8a16) - GitHub Actions
- `fastlane` (🚀 #1d76db) - Fastlane automation

### 📱 Platform Labels
- `ios` (📱 #0e8a16) - iOS specific
- `iphone` (📱 #1d76db) - iPhone specific
- `ipad` (📱 #5319e7) - iPad specific
- `watchos` (⌚ #fbca04) - Apple Watch (future)

### 🍼 Kids Category Labels
- `kids-category` (👶 #ff69b4) - Kids Category compliance
- `coppa-compliance` (🛡️ #b60205) - COPPA related
- `safety` (🔒 #d93f0b) - Child safety
- `hearing-protection` (🔊 #fbca04) - Hearing safety

### 🎯 Priority Labels
- `priority-critical` (🚨 #b60205) - Critical priority
- `priority-high` (🔴 #d73a4a) - High priority
- `priority-medium` (🟡 #fbca04) - Medium priority
- `priority-low` (🟢 #0e8a16) - Low priority

### 📋 Status Labels
- `needs-triage` (🔍 #fbca04) - Needs initial review
- `needs-review` (👀 #0e8a16) - Needs code review
- `ready-for-testing` (🧪 #1d76db) - Ready for QA
- `blocked` (🚫 #d73a4a) - Blocked by dependency

### 🏆 Special Labels
- `good-first-issue` (🌟 #7057ff) - Good for newcomers
- `hacktoberfest` (🎃 #ff6600) - Hacktoberfest eligible
- `question` (❓ #d876e3) - Further information requested
- `wontfix` (❌ #ffffff) - This will not be worked on

## 🚀 GitHub Actions Permissions

### Repository Permissions
```yaml
# .github/workflows permissions
permissions:
  contents: read
  issues: write
  pull-requests: write
  checks: write
  security-events: write
  id-token: write
```

### Fine-grained Token Permissions
- **Contents**: Read/Write (for releases)
- **Issues**: Write (for automation)
- **Pull Requests**: Write (for automation)
- **Checks**: Write (for status checks)
- **Actions**: Read (for workflow runs)
- **Security Events**: Write (for security scanning)

## 📊 GitHub Projects Setup

### 📋 Development Board

**Columns**:
1. **📥 Backlog** - New issues and feature requests
2. **🔍 Triage** - Issues being evaluated
3. **🏗️ In Progress** - Currently being worked on
4. **👀 Review** - Pull requests awaiting review
5. **🧪 Testing** - Features in QA testing
6. **✅ Done** - Completed items

**Automation Rules**:
- Move to "In Progress" when PR is opened
- Move to "Review" when PR is ready for review
- Move to "Testing" when PR is merged to develop
- Move to "Done" when released to App Store

### 🎯 Release Planning Board

**Columns**:
1. **🎯 Planned** - Features planned for next release
2. **🏗️ Development** - Features in development
3. **🧪 Testing** - Features in testing
4. **📦 Release Candidate** - Ready for release
5. **🚀 Released** - Live in App Store

## 🔔 Notifications & Integrations

### 📱 Slack Integration

```yaml
# Slack webhook for important events
on:
  pull_request:
    types: [opened, closed, review_requested]
  issues:
    types: [opened, closed, labeled]
  release:
    types: [published]
  workflow_run:
    workflows: ["iOS Build & Test"]
    types: [completed]
```

### 📧 Email Notifications

**Security Alerts**: All maintainers
**Critical Issues**: @vpavlov-me, @security-team
**Release Updates**: All team members
**Dependency Updates**: @devops-lead, @senior-dev

## 🔍 Code Scanning Setup

### CodeQL Analysis

```yaml
# .github/workflows/codeql-analysis.yml
strategy:
  matrix:
    language: ['swift']
```

### Custom Security Rules

- COPPA compliance checks
- Kids Category requirements validation
- Audio safety validation
- Accessibility compliance checks

## 📚 Wiki Configuration

### 📖 Documentation Structure

1. **Home** - Project overview and quick start
2. **Kids Category Compliance** - COPPA and safety guidelines
3. **Audio Safety Guidelines** - WHO hearing protection
4. **Accessibility Guide** - WCAG compliance and VoiceOver
5. **Development Setup** - Detailed setup instructions
6. **Testing Guidelines** - Manual and automated testing
7. **Release Process** - Step-by-step release guide
8. **Security Policy** - Security reporting and guidelines

### 🔗 Important Links

- [Apple Kids Category Guidelines](https://developer.apple.com/app-store/kids-apps/)
- [COPPA Compliance Guide](https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa)
- [WHO Hearing Safety](https://www.who.int/news-room/fact-sheets/detail/deafness-and-hearing-loss)
- [iOS Accessibility](https://developer.apple.com/accessibility/)

## ✅ Setup Verification Checklist

### Repository Configuration
- [ ] Branch protection rules configured
- [ ] Required status checks enabled
- [ ] Code owners file configured
- [ ] Security scanning enabled
- [ ] Dependabot configured

### CI/CD Setup
- [ ] All GitHub Actions workflows passing
- [ ] Fastlane configuration tested
- [ ] TestFlight deployment working
- [ ] Code signing certificates configured

### Kids Category Compliance
- [ ] COPPA compliance checks enabled
- [ ] Accessibility testing automated
- [ ] Audio safety validation configured
- [ ] Security scanning for Kids apps enabled

### Team Access
- [ ] Team members added with appropriate permissions
- [ ] Code owners properly configured
- [ ] Review requirements set up
- [ ] Notification preferences configured

---

## 🆘 Support

For setup assistance:
- **GitHub Issues**: Technical configuration questions
- **Slack**: `#babysounds-dev` channel
- **Email**: `devops@babysounds.com`
- **Emergency**: `security@babysounds.com`

---

**Last Updated**: March 2024  
**Next Review**: June 2024 