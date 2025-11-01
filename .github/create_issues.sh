#!/bin/bash

# BabySounds - GitHub Issues Creation Script
# This script creates all v1.0 issues in the GitHub repository

REPO="vpavlov-me/BabySounds"

echo "🚀 Creating GitHub Issues for BabySounds v1.0"
echo "================================================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Error: Not authenticated with GitHub CLI"
    echo "Run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Create labels first
echo "📋 Creating labels..."
gh label create "v1-blocker" --color "d73a4a" --description "Critical blocker for v1.0 release" --repo $REPO 2>/dev/null || echo "  Label 'v1-blocker' already exists"
gh label create "critical" --color "b60205" --description "Critical priority" --repo $REPO 2>/dev/null || echo "  Label 'critical' already exists"
gh label create "high" --color "d93f0b" --description "High priority" --repo $REPO 2>/dev/null || echo "  Label 'high' already exists"
gh label create "medium" --color "fbca04" --description "Medium priority" --repo $REPO 2>/dev/null || echo "  Label 'medium' already exists"
gh label create "low" --color "0e8a16" --description "Low priority" --repo $REPO 2>/dev/null || echo "  Label 'low' already exists"
gh label create "audio" --color "1d76db" --description "Audio system related" --repo $REPO 2>/dev/null || echo "  Label 'audio' already exists"
gh label create "monetization" --color "5319e7" --description "Monetization/subscriptions" --repo $REPO 2>/dev/null || echo "  Label 'monetization' already exists"
gh label create "documentation" --color "0075ca" --description "Documentation" --repo $REPO 2>/dev/null || echo "  Label 'documentation' already exists"
gh label create "testing" --color "bfd4f2" --description "Testing related" --repo $REPO 2>/dev/null || echo "  Label 'testing' already exists"
gh label create "localization" --color "c5def5" --description "Localization/i18n" --repo $REPO 2>/dev/null || echo "  Label 'localization' already exists"
gh label create "legal" --color "ededed" --description "Legal/compliance" --repo $REPO 2>/dev/null || echo "  Label 'legal' already exists"
gh label create "infrastructure" --color "c2e0c6" --description "Infrastructure/CI/CD" --repo $REPO 2>/dev/null || echo "  Label 'infrastructure' already exists"
gh label create "analytics" --color "bfdadc" --description "Analytics/tracking" --repo $REPO 2>/dev/null || echo "  Label 'analytics' already exists"
gh label create "ui" --color "d4c5f9" --description "User interface" --repo $REPO 2>/dev/null || echo "  Label 'ui' already exists"
gh label create "safety" --color "f9d0c4" --description "Child safety features" --repo $REPO 2>/dev/null || echo "  Label 'safety' already exists"
gh label create "content" --color "c5f9c4" --description "Content/assets" --repo $REPO 2>/dev/null || echo "  Label 'content' already exists"
gh label create "app-store" --color "fef2c0" --description "App Store submission" --repo $REPO 2>/dev/null || echo "  Label 'app-store' already exists"
gh label create "enhancement" --color "a2eeef" --description "New feature or enhancement" --repo $REPO 2>/dev/null || echo "  Label 'enhancement' already exists"
gh label create "future" --color "e4e669" --description "Future version (not v1.0)" --repo $REPO 2>/dev/null || echo "  Label 'future' already exists"

echo "✅ Labels created"
echo ""

# Create milestone
echo "🎯 Creating v1.0 milestone..."
gh api repos/$REPO/milestones -f title="v1.0" -f state="open" -f description="First production release of BabySounds" 2>/dev/null || echo "  Milestone 'v1.0' may already exist"
echo ""

# Issue 1: Complete Audio Playback Implementation
echo "📝 Creating Issue #1: Complete Audio Playback Implementation..."
gh issue create \
  --repo $REPO \
  --title "[V1 BLOCKER] Complete Audio Playback Implementation" \
  --label "v1-blocker,critical,audio" \
  --milestone "v1.0" \
  --body "## Issue Description
Complete the audio playback implementation in AudioEngineManager. Currently has TODO markers that block core functionality.

## Current State
- Audio engine setup is present
- File loading logic implemented
- Buffer scheduling framework exists
- TODO at line 261 in AudioEngineManager.swift blocks actual playback

## Required State for v1.0
- Remove all TODO markers in audio system
- Implement actual audio buffer scheduling
- Test multi-track playback (up to 4 concurrent tracks)
- Verify fade-in/fade-out effects work correctly
- Test loop functionality

## Acceptance Criteria
- [ ] TODO-AUDIO markers removed from AudioEngineManager.swift
- [ ] play() method fully functional
- [ ] Can play single sound successfully
- [ ] Can play multiple sounds simultaneously (up to 4 tracks)
- [ ] Volume controls work correctly
- [ ] Fade effects work smoothly
- [ ] Loop mode works without gaps
- [ ] No audio glitches or crashes

## Technical Details
Files to modify:
- \`BabySounds/Sources/BabySounds/Core/Audio/AudioEngineManager.swift\` (line 261)
- \`BabySounds/Sources/BabySounds/Core/Audio/BackgroundAudioManager.swift\` (line 151)

## Related Files
- AudioEngineManager.swift
- BackgroundAudioManager.swift
- SafeVolumeManager.swift

## Estimated Effort
Medium (1-2 days)"

echo "✅ Issue #1 created"
echo ""

# Issue 2: Add Missing Audio File
echo "📝 Creating Issue #2: Add Missing Audio File (piano_music.mp3)..."
gh issue create \
  --repo $REPO \
  --title "[V1 BLOCKER] Add Missing Audio File (piano_music.mp3)" \
  --label "v1-blocker,critical,content" \
  --milestone "v1.0" \
  --body "## Issue Description
The sound catalog references 15 sounds, but only 14 MP3 files are present. Missing: piano_music.mp3

## Current State
- sounds.json defines piano_music sound
- File Resources/Audio/piano_music.mp3 does not exist
- 14 other sound files are present

## Required State for v1.0
- piano_music.mp3 file added to Resources/Audio/
- File matches quality of other sounds (clear, loopable)
- Appropriate length (2-5 minutes recommended)

## Acceptance Criteria
- [ ] piano_music.mp3 exists in Resources/Audio/
- [ ] File is valid MP3 format
- [ ] Sound is appropriate for babies/children
- [ ] Sound loops smoothly
- [ ] File size is reasonable (< 5MB)
- [ ] Sound can be played in app without errors

## Technical Details
Location: \`BabySounds/Sources/BabySounds/Resources/Audio/piano_music.mp3\`

## Estimated Effort
Small (< 4 hours)"

echo "✅ Issue #2 created"
echo ""

# Issue 3: Remove Russian Localization
echo "📝 Creating Issue #3: Remove Russian Localization - English Only..."
gh issue create \
  --repo $REPO \
  --title "[V1 BLOCKER] Remove Russian Localization - English Only for v1.0" \
  --label "v1-blocker,high,localization" \
  --milestone "v1.0" \
  --body "## Issue Description
Remove all Russian text from the codebase. App will be English-only for v1.0 release.

## Current State
- Mixed Russian and English strings throughout codebase
- Notable locations:
  - SleepSchedulesView.swift line 22: \"Загрузка расписаний...\"
  - Various other views with Russian text

## Required State for v1.0
- All UI text in English only
- Remove ru.lproj directories if any
- Clean English translations for all strings
- Consistent terminology throughout app

## Acceptance Criteria
- [ ] Search codebase for Cyrillic characters - zero results
- [ ] All user-facing strings in English
- [ ] No Russian .lproj folders
- [ ] Test all screens to verify English text
- [ ] No \"TODO\" comments related to translations

## Technical Details
Files with known Russian text:
- SleepSchedulesView.swift (line 22, 80+)
- Search: \`grep -r \"[А-Яа-я]\" BabySounds/Sources/\`

## Estimated Effort
Small (< 4 hours)"

echo "✅ Issue #3 created"
echo ""

# Issue 4: Complete StoreKit 2 Purchase Flow
echo "📝 Creating Issue #4: Complete StoreKit 2 Purchase Flow..."
gh issue create \
  --repo $REPO \
  --title "[V1 BLOCKER] Complete StoreKit 2 Purchase Flow" \
  --label "v1-blocker,high,monetization" \
  --milestone "v1.0" \
  --body "## Issue Description
Complete the StoreKit 2 integration for in-app purchases. Currently at ~60% completion.

## Current State
- Product definitions ready (monthly/annual)
- Product loading implemented
- Purchase flow scaffolding present
- Missing: transaction observation, receipt validation, restore purchases

## Required State for v1.0
- Full purchase flow working end-to-end
- Transaction observation complete
- Receipt validation implemented
- Restore purchases functional
- Error handling for all edge cases
- Testing on real devices

## Acceptance Criteria
- [ ] Can successfully purchase monthly subscription
- [ ] Can successfully purchase annual subscription
- [ ] Transaction observer receives and processes updates
- [ ] Receipt validation works correctly
- [ ] Restore purchases button works
- [ ] Premium features unlock after purchase
- [ ] Handles errors gracefully (network issues, cancelled purchases, etc.)
- [ ] Tested on real device with sandbox account

## Technical Details
Files to modify:
- \`BabySounds/Sources/BabySounds/Services/SubscriptionServiceSK2.swift\`
- \`BabySounds/Sources/BabySounds/Core/Managers/PremiumManager.swift\`

## Dependencies
- App Store Connect product setup required
- Test accounts needed

## Estimated Effort
Medium (1-2 days)"

echo "✅ Issue #4 created"
echo ""

# Issue 5: Implement Sleep Schedule Notifications
echo "📝 Creating Issue #5: Implement Sleep Schedule Notifications..."
gh issue create \
  --repo $REPO \
  --title "[V1 BLOCKER] Implement Sleep Schedule Notifications" \
  --label "v1-blocker,high" \
  --milestone "v1.0" \
  --body "## Issue Description
Complete the sleep schedule notification system. UI is built but background scheduling is incomplete.

## Current State
- SleepScheduleManager exists with schedule models
- UI for creating/editing schedules complete
- Notification permission flow ready
- Missing: actual notification scheduling logic

## Required State for v1.0
- Schedule notifications fire at correct times
- Repeat patterns work (daily, specific days)
- Notifications trigger app to start playing sounds
- Edit/delete schedules updates notifications
- Permission handling complete

## Acceptance Criteria
- [ ] Can create schedule with notification
- [ ] Notification fires at scheduled time
- [ ] Notification triggers sound playback
- [ ] Repeat patterns work correctly (daily, custom days)
- [ ] Editing schedule updates notification
- [ ] Deleting schedule cancels notification
- [ ] Permission denied is handled gracefully
- [ ] Works in background/when app is closed

## Technical Details
Files to modify:
- \`BabySounds/Sources/BabySounds/Core/Managers/SleepScheduleManager.swift\`
- \`BabySounds/Sources/BabySounds/Core/Managers/NotificationPermissionManager.swift\`

## Estimated Effort
Medium (1-2 days)"

echo "✅ Issue #5 created"
echo ""

# Issue 6: Create Privacy Policy & Terms
echo "📝 Creating Issue #6: Create Privacy Policy & Terms of Service..."
gh issue create \
  --repo $REPO \
  --title "[V1 BLOCKER] Create Privacy Policy & Terms of Service" \
  --label "v1-blocker,high,legal,documentation" \
  --milestone "v1.0" \
  --body "## Issue Description
Create real privacy policy and terms of service documents to replace placeholder text. Must be implemented both in-app and as public GitHub Pages documents.

## Current State
- Placeholder text in Settings views
- No actual legal documents

## Required State for v1.0
- Complete privacy policy (GDPR/CCPA compliant)
- Complete terms of service
- Documents accessible in-app
- Documents hosted on GitHub Pages with public URLs
- Both markdown and in-app SwiftUI views

## Acceptance Criteria
- [ ] privacy-policy.md created in docs/
- [ ] terms-of-service.md created in docs/
- [ ] Documents cover: data collection, usage, storage, deletion, children's privacy (COPPA)
- [ ] In-app PrivacyPolicyView displays content
- [ ] In-app TermsOfServiceView displays content
- [ ] GitHub Pages site deployed
- [ ] Public URLs work: vpavlov-me.github.io/BabySounds/privacy-policy
- [ ] Public URLs work: vpavlov-me.github.io/BabySounds/terms-of-service
- [ ] Links in PaywallView point to public URLs

## Technical Details
Create:
- docs/privacy-policy.md
- docs/terms-of-service.md
- BabySounds/Sources/BabySounds/Features/Settings/Legal/PrivacyPolicyView.swift
- BabySounds/Sources/BabySounds/Features/Settings/Legal/TermsOfServiceView.swift
- docs/_config.yml (for GitHub Pages)

Modify:
- PaywallView.swift lines 157-158

## Estimated Effort
Medium (1-2 days)"

echo "✅ Issue #6 created"
echo ""

# Issue 7: Setup GitHub Pages
echo "📝 Creating Issue #7: Setup GitHub Pages..."
gh issue create \
  --repo $REPO \
  --title "[V1 BLOCKER] Setup GitHub Pages for Public Documentation" \
  --label "v1-blocker,medium,infrastructure,documentation" \
  --milestone "v1.0" \
  --body "## Issue Description
Setup GitHub Pages to host public-facing documentation including privacy policy and terms of service.

## Current State
- No GitHub Pages site configured
- No docs/ directory structure

## Required State for v1.0
- GitHub Pages enabled on repository
- docs/ directory with Jekyll structure
- Privacy policy and terms accessible via public URLs

## Acceptance Criteria
- [ ] GitHub Pages enabled in repository settings
- [ ] docs/ directory created with proper structure
- [ ] _config.yml configured
- [ ] index.md landing page created
- [ ] Site builds successfully
- [ ] Public URLs accessible
- [ ] Mobile-responsive design
- [ ] SSL/HTTPS enabled

## Technical Details
Create:
- docs/_config.yml
- docs/index.md
- docs/privacy-policy.md
- docs/terms-of-service.md

GitHub Pages URL: https://vpavlov-me.github.io/BabySounds/

## Estimated Effort
Small (< 4 hours)"

echo "✅ Issue #7 created"
echo ""

# Issue 8: Add Unit Tests
echo "📝 Creating Issue #8: Add Basic Unit Tests..."
gh issue create \
  --repo $REPO \
  --title "[HIGH] Add Basic Unit Tests for Core Managers" \
  --label "high,testing" \
  --milestone "v1.0" \
  --body "## Issue Description
Add basic unit tests for critical business logic. Currently test coverage is nearly non-existent.

## Current State
- BabySoundsTests.swift has only placeholder tests
- No tests for critical logic

## Required State for v1.0
- Unit tests for core managers
- At least 60% code coverage for critical paths
- Tests pass in CI

## Test Coverage Needed
- [ ] AudioEngineManager tests
- [ ] SafeVolumeManager tests
- [ ] PremiumManager tests
- [ ] ParentGateManager tests
- [ ] SleepScheduleManager tests
- [ ] SoundCatalog tests

## Acceptance Criteria
- [ ] At least 15 meaningful unit tests
- [ ] Tests cover happy paths and error cases
- [ ] All tests pass
- [ ] Can run tests via Xcode
- [ ] Test coverage report shows >60% for critical files

## Estimated Effort
Large (3-5 days)"

echo "✅ Issue #8 created"
echo ""

# Issue 9: Integrate Analytics
echo "📝 Creating Issue #9: Integrate Analytics Service..."
gh issue create \
  --repo $REPO \
  --title "[HIGH] Integrate Analytics Service" \
  --label "high,analytics,infrastructure" \
  --milestone "v1.0" \
  --body "## Issue Description
Integrate analytics service to track user behavior and feature usage. Currently 28+ TODO markers for analytics throughout codebase.

## Current State
- TODO markers in: ParentGateManager, PremiumManager, SafeLinkWrapper, etc.
- No analytics service integrated

## Required State for v1.0
- Analytics service integrated (recommend TelemetryDeck or Firebase)
- Key events tracked
- Privacy-compliant implementation
- No PII collected

## Events to Track
- [ ] App launch
- [ ] Sound played
- [ ] Premium feature attempted (free user)
- [ ] Purchase initiated/completed
- [ ] Parent gate challenged/passed/failed
- [ ] Schedule created/triggered
- [ ] External link opened
- [ ] Error occurred

## Acceptance Criteria
- [ ] Analytics SDK integrated
- [ ] Privacy policy updated to mention analytics
- [ ] Key events tracked
- [ ] Analytics dashboard accessible
- [ ] No crashes from analytics code

## Technical Details
Recommended: TelemetryDeck (privacy-focused)

Files to modify: All files with \"TODO: Send to analytics\" comments

## Estimated Effort
Medium (1-2 days)"

echo "✅ Issue #9 created"
echo ""

# Issue 10: Complete Settings Screens
echo "📝 Creating Issue #10: Complete Settings Screens..."
gh issue create \
  --repo $REPO \
  --title "[HIGH] Complete Settings Screens" \
  --label "high,ui" \
  --milestone "v1.0" \
  --body "## Issue Description
Complete placeholder settings screens that currently show \"coming soon\" or incomplete content.

## Current State
- ThemeSettingsView: Shows \"coming soon\"
- OfflinePacksView: Shows \"coming soon\"
- Notification Settings: Incomplete

## Required State for v1.0
Either implement these features OR remove placeholders and add to roadmap.

## Acceptance Criteria
- [ ] Decision made: implement or remove each feature
- [ ] No \"coming soon\" placeholders visible to users
- [ ] If removed, add to public roadmap
- [ ] If implemented, feature works correctly

## Technical Details
Recommendation: Remove theme and offline packs for v1.0, keep for v1.1

## Estimated Effort
Small (< 4 hours) if removing placeholders"

echo "✅ Issue #10 created"
echo ""

# Issue 11: Playroom Content Filtering
echo "📝 Creating Issue #11: Implement Playroom Content Filtering..."
gh issue create \
  --repo $REPO \
  --title "[HIGH] Implement Playroom Content Filtering" \
  --label "high,safety" \
  --milestone "v1.0" \
  --body "## Issue Description
Filter sounds in Playroom tab to show only age-appropriate content for children's interaction.

## Current State
- TODO comment at ContentView.swift line 391
- Currently shows first 6 sounds regardless of appropriateness

## Required State for v1.0
- Playroom shows only child-safe sounds
- Appropriate volume defaults
- Large, tap-friendly buttons
- No complex sounds that might be overstimulating

## Acceptance Criteria
- [ ] Sound filtering criteria defined
- [ ] Playroom shows only appropriate sounds
- [ ] UI optimized for child interaction

## Technical Details
File: \`BabySounds/Sources/BabySounds/ContentView.swift\` line 391

Suggested child-appropriate sounds:
- White noise, pink noise
- Heartbeat, womb sounds
- Gentle nature sounds
- Lullabies

## Estimated Effort
Small (< 4 hours)"

echo "✅ Issue #11 created"
echo ""

# Issue 12: Update Documentation
echo "📝 Creating Issue #12: Update Project Documentation..."
gh issue create \
  --repo $REPO \
  --title "[MEDIUM] Update Project Documentation (README, CONTRIBUTING)" \
  --label "medium,documentation" \
  --milestone "v1.0" \
  --body "## Issue Description
Create comprehensive project documentation including README, CONTRIBUTING guide, and technical docs.

## Required Documents
- [ ] README.md - Project overview, features, installation
- [ ] CONTRIBUTING.md - How to contribute
- [ ] CODE_OF_CONDUCT.md - Community standards
- [ ] CHANGELOG.md - Version history
- [ ] docs/ARCHITECTURE.md - Technical architecture
- [ ] docs/SETUP.md - Development setup guide

## Acceptance Criteria
- [ ] All documents created and complete
- [ ] README includes: features, screenshots, installation, usage
- [ ] Documentation is clear and well-formatted

## Estimated Effort
Medium (1-2 days)"

echo "✅ Issue #12 created"
echo ""

# Issue 13: GitHub Wiki
echo "📝 Creating Issue #13: Create GitHub Wiki..."
gh issue create \
  --repo $REPO \
  --title "[MEDIUM] Create GitHub Wiki with Technical Artifacts" \
  --label "medium,documentation" \
  --milestone "v1.0" \
  --body "## Issue Description
Setup GitHub Wiki with technical documentation and architecture artifacts.

## Wiki Pages Needed
- [ ] Home - Project overview
- [ ] Architecture - System design
- [ ] Audio System - How audio works
- [ ] Premium Features - Subscriptions
- [ ] Safety Features - Volume & parental controls
- [ ] API Reference - Key classes
- [ ] Development Guide - Setup
- [ ] Testing Guide - How to test
- [ ] Release Process - Deployment

## Acceptance Criteria
- [ ] All wiki pages created
- [ ] Pages include diagrams where helpful
- [ ] Code examples included

## Estimated Effort
Medium (1-2 days)"

echo "✅ Issue #13 created"
echo ""

# Issue 14: App Store Assets
echo "📝 Creating Issue #14: App Store Assets Preparation..."
gh issue create \
  --repo $REPO \
  --title "[MEDIUM] App Store Assets Preparation" \
  --label "medium,app-store" \
  --milestone "v1.0" \
  --body "## Issue Description
Prepare all assets needed for App Store submission.

## Required Assets
- [ ] App icon (1024x1024)
- [ ] Screenshots (all required sizes)
- [ ] App preview video (optional)
- [ ] App Store description text
- [ ] Keywords for ASO
- [ ] Promotional text

## Acceptance Criteria
- [ ] All required sizes generated
- [ ] Icons follow Apple guidelines
- [ ] Screenshots show key features
- [ ] Text is compelling

## Estimated Effort
Medium (1-2 days)"

echo "✅ Issue #14 created"
echo ""

# Future features
echo "📝 Creating Issue #15: Custom Mix Interface (v1.1)..."
gh issue create \
  --repo $REPO \
  --title "[FUTURE] Implement Custom Mix Interface" \
  --label "low,enhancement,future" \
  --milestone "v1.1" \
  --body "## Issue Description
Implement UI for creating custom sound mixes (multiple sounds simultaneously).

Deferred to v1.1 - not needed for initial release."

echo "✅ Issue #15 created"
echo ""

echo "📝 Creating Issue #16: Offline Downloads (v1.1)..."
gh issue create \
  --repo $REPO \
  --title "[FUTURE] Implement Offline Downloads System" \
  --label "low,enhancement,future" \
  --milestone "v1.1" \
  --body "## Issue Description
Implement offline download system for sound packs (premium feature).

Deferred to v1.1 - not needed for initial release."

echo "✅ Issue #16 created"
echo ""

echo "📝 Creating Issue #17: Advanced Audio Controls (v2.0)..."
gh issue create \
  --repo $REPO \
  --title "[FUTURE] Advanced Audio Controls (EQ, Effects)" \
  --label "low,enhancement,future" \
  --body "## Issue Description
Add advanced audio controls like equalizer, reverb, spatial audio.

Deferred to v2.0 - not needed for initial release."

echo "✅ Issue #17 created"
echo ""

echo ""
echo "================================================"
echo "✅ All issues created successfully!"
echo ""
echo "Next steps:"
echo "1. View issues: gh issue list --repo $REPO"
echo "2. Create project board: Visit https://github.com/$REPO/projects"
echo "3. Add issues to project and organize by priority"
echo ""
