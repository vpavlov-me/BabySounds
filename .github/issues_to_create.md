# BabySounds v1.0 GitHub Issues

This file contains all issues to be created for the v1.0 release.
Use the script `create_issues.sh` to bulk create these issues.

---

## Priority 1: Critical Blockers (v1-blocker label)

### Issue 1: Complete Audio Playback Implementation
**Labels**: v1-blocker, critical, audio
**Milestone**: v1.0
**Body**:
```
## Issue Description
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
- BabySounds/Sources/BabySounds/Core/Audio/AudioEngineManager.swift (line 261)
- BabySounds/Sources/BabySounds/Core/Audio/BackgroundAudioManager.swift (line 151)

## Related Files
- AudioEngineManager.swift
- BackgroundAudioManager.swift
- SafeVolumeManager.swift

## Dependencies
None - this can be started immediately

## Estimated Effort
- [x] Medium (1-2 days)
```

---

### Issue 2: Add Missing Audio File (piano_music.mp3)
**Labels**: v1-blocker, critical, content
**Milestone**: v1.0
**Body**:
```
## Issue Description
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
Location: BabySounds/Sources/BabySounds/Resources/Audio/piano_music.mp3

## Dependencies
None

## Estimated Effort
- [x] Small (< 4 hours) - assuming we can source/create appropriate audio
```

---

### Issue 3: Remove Russian Localization - English Only for v1.0
**Labels**: v1-blocker, high, localization
**Milestone**: v1.0
**Body**:
```
## Issue Description
Remove all Russian text from the codebase. App will be English-only for v1.0 release.

## Current State
- Mixed Russian and English strings throughout codebase
- Notable locations:
  - SleepSchedulesView.swift line 22: "Загрузка расписаний..."
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
- [ ] No "TODO" comments related to translations

## Technical Details
Files with known Russian text:
- SleepSchedulesView.swift (line 22, 80+)
- Search entire codebase for Cyrillic: `grep -r "[А-Яа-я]" BabySounds/Sources/`

## Dependencies
None

## Estimated Effort
- [x] Small (< 4 hours)
```

---

### Issue 4: Complete StoreKit 2 Purchase Flow
**Labels**: v1-blocker, high, monetization
**Milestone**: v1.0
**Body**:
```
## Issue Description
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
- BabySounds/Sources/BabySounds/Services/SubscriptionServiceSK2.swift
- BabySounds/Sources/BabySounds/Core/Managers/PremiumManager.swift

## Dependencies
- App Store Connect product setup required
- Test accounts needed

## Estimated Effort
- [x] Medium (1-2 days)
```

---

### Issue 5: Implement Sleep Schedule Notifications
**Labels**: v1-blocker, high, feature
**Milestone**: v1.0
**Body**:
```
## Issue Description
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
- BabySounds/Sources/BabySounds/Core/Managers/SleepScheduleManager.swift
- BabySounds/Sources/BabySounds/Core/Managers/NotificationPermissionManager.swift

## Dependencies
- Issue #4 (notifications require background audio to be working)

## Estimated Effort
- [x] Medium (1-2 days)
```

---

### Issue 6: Create Privacy Policy & Terms of Service
**Labels**: v1-blocker, high, legal, documentation
**Milestone**: v1.0
**Body**:
```
## Issue Description
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
- [ ] Public URLs work: yourusername.github.io/BabySounds/privacy-policy
- [ ] Public URLs work: yourusername.github.io/BabySounds/terms-of-service
- [ ] Links in PaywallView point to public URLs

## Technical Details
Create:
- docs/privacy-policy.md
- docs/terms-of-service.md
- BabySounds/Sources/BabySounds/Features/Settings/Legal/PrivacyPolicyView.swift
- BabySounds/Sources/BabySounds/Features/Settings/Legal/TermsOfServiceView.swift
- docs/_config.yml (for GitHub Pages)

Modify:
- PaywallView.swift lines 157-158 (link to public URLs)

## Dependencies
- Issue #7 (GitHub Pages setup)

## Estimated Effort
- [x] Medium (1-2 days)
```

---

### Issue 7: Setup GitHub Pages for Public Documentation
**Labels**: v1-blocker, medium, infrastructure, documentation
**Milestone**: v1.0
**Body**:
```
## Issue Description
Setup GitHub Pages to host public-facing documentation including privacy policy and terms of service.

## Current State
- No GitHub Pages site configured
- No docs/ directory structure

## Required State for v1.0
- GitHub Pages enabled on repository
- docs/ directory with Jekyll structure
- Privacy policy and terms accessible via public URLs
- Custom domain optional but nice to have

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
- docs/assets/ (optional styling)

GitHub Pages URL will be: https://vpavlov-me.github.io/BabySounds/

## Dependencies
None - can start immediately

## Estimated Effort
- [x] Small (< 4 hours)
```

---

## Priority 2: High Priority for v1.0 (high label)

### Issue 8: Add Basic Unit Tests for Core Managers
**Labels**: high, testing, quality
**Milestone**: v1.0
**Body**:
```
## Issue Description
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

## Technical Details
Files to create/modify:
- BabySounds/Tests/BabySoundsTests/AudioEngineManagerTests.swift
- BabySounds/Tests/BabySoundsTests/SafeVolumeManagerTests.swift
- BabySounds/Tests/BabySoundsTests/PremiumManagerTests.swift
- BabySounds/Tests/BabySoundsTests/ParentGateManagerTests.swift

## Dependencies
None

## Estimated Effort
- [x] Large (3-5 days)
```

---

### Issue 9: Integrate Analytics Service
**Labels**: high, analytics, infrastructure
**Milestone**: v1.0
**Body**:
```
## Issue Description
Integrate analytics service to track user behavior and feature usage. Currently 28+ TODO markers for analytics throughout codebase.

## Current State
- TODO markers in: ParentGateManager, PremiumManager, SafeLinkWrapper, etc.
- No analytics service integrated

## Required State for v1.0
- Analytics service integrated (recommend Firebase Analytics or TelemetryDeck)
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
- [ ] Opt-out mechanism provided (if required)

## Technical Details
Recommended: TelemetryDeck (privacy-focused) or Firebase Analytics

Files to modify:
- All files with "TODO: Send to analytics" comments
- Add new AnalyticsService.swift

## Dependencies
- Issue #6 (privacy policy must mention analytics)

## Estimated Effort
- [x] Medium (1-2 days)
```

---

### Issue 10: Complete Settings Screens
**Labels**: high, ui, feature
**Milestone**: v1.0
**Body**:
```
## Issue Description
Complete placeholder settings screens that currently show "coming soon" or incomplete content.

## Current State
- ThemeSettingsView: Shows "coming soon"
- OfflinePacksView: Shows "coming soon"
- Notification Settings: Incomplete

## Required State for v1.0
Either implement these features OR remove placeholders and add to roadmap.

## Acceptance Criteria
- [ ] Decision made: implement or remove each feature
- [ ] No "coming soon" placeholders visible to users
- [ ] If removed, add to public roadmap
- [ ] If implemented, feature works correctly
- [ ] Settings persist correctly

## Technical Details
Files to review:
- BabySounds/Sources/BabySounds/Features/Settings/ThemeSettingsView.swift
- BabySounds/Sources/BabySounds/Features/Settings/OfflinePacksView.swift
- BabySounds/Sources/BabySounds/Features/Settings/NotificationSettingsView.swift

Recommendation: Remove theme and offline packs for v1.0, keep for v1.1

## Dependencies
None

## Estimated Effort
- [x] Small (< 4 hours) - if removing placeholders
- [x] Large (3-5 days) - if implementing features
```

---

### Issue 11: Implement Playroom Content Filtering
**Labels**: high, feature, safety
**Milestone**: v1.0
**Body**:
```
## Issue Description
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
- [ ] Sounds are engaging for children
- [ ] UI optimized for child interaction
- [ ] No inappropriate sounds accessible

## Technical Details
File to modify:
- BabySounds/Sources/BabySounds/ContentView.swift line 391

Suggested child-appropriate sounds:
- White noise, pink noise
- Heartbeat, womb sounds
- Gentle nature sounds (rain, ocean)
- Lullabies
- Exclude: complex music, jarring sounds

## Dependencies
None

## Estimated Effort
- [x] Small (< 4 hours)
```

---

## Priority 3: Medium Priority (medium label)

### Issue 12: Update Project Documentation (README, CONTRIBUTING)
**Labels**: medium, documentation
**Milestone**: v1.0
**Body**:
```
## Issue Description
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
- [ ] CONTRIBUTING explains development workflow
- [ ] Documentation is clear and well-formatted
- [ ] Links between documents work correctly

## Dependencies
None

## Estimated Effort
- [x] Medium (1-2 days)
```

---

### Issue 13: Create GitHub Wiki with Technical Artifacts
**Labels**: medium, documentation
**Milestone**: v1.0
**Body**:
```
## Issue Description
Setup GitHub Wiki with technical documentation and architecture artifacts.

## Wiki Pages Needed
- [ ] Home - Project overview and navigation
- [ ] Architecture - System design and patterns
- [ ] Audio System - How audio engine works
- [ ] Premium Features - Subscription system details
- [ ] Safety Features - Volume control and parental gates
- [ ] API Reference - Key classes and methods
- [ ] Development Guide - Setup and workflow
- [ ] Testing Guide - How to run and write tests
- [ ] Release Process - How to deploy

## Acceptance Criteria
- [ ] All wiki pages created
- [ ] Pages include diagrams where helpful
- [ ] Code examples included
- [ ] Links between pages work
- [ ] Mobile-readable

## Dependencies
- Issue #12 (general documentation)

## Estimated Effort
- [x] Medium (1-2 days)
```

---

### Issue 14: App Store Assets Preparation
**Labels**: medium, marketing, app-store
**Milestone**: v1.0
**Body**:
```
## Issue Description
Prepare all assets needed for App Store submission.

## Required Assets
- [ ] App icon (1024x1024)
- [ ] Screenshots (6.5", 6.7", 12.9" displays)
- [ ] App preview video (optional but recommended)
- [ ] App Store description text
- [ ] Keywords for ASO
- [ ] Promotional text
- [ ] What's new text

## Acceptance Criteria
- [ ] All required sizes generated
- [ ] Icons follow Apple guidelines
- [ ] Screenshots show key features
- [ ] Text is compelling and clear
- [ ] Keywords researched
- [ ] All assets in /App Store/ directory

## Dependencies
- App must be feature-complete for screenshots

## Estimated Effort
- [x] Medium (1-2 days)
```

---

## Priority 4: Nice to Have / Future (low label)

### Issue 15: Implement Custom Mix Interface
**Labels**: low, enhancement, future
**Milestone**: v1.1
**Body**:
```
## Issue Description
Implement UI for creating custom sound mixes (multiple sounds playing simultaneously).

## Current State
- Mix model exists in codebase
- No UI implementation
- 4-track audio engine supports it technically

## Future Feature for v1.1+
- User can select multiple sounds
- Adjust volume for each track
- Save custom mixes
- Share mixes (optional)

## Deferred to v1.1
This is explicitly not needed for v1.0 release.
```

---

### Issue 16: Implement Offline Downloads System
**Labels**: low, enhancement, future
**Milestone**: v1.1
**Body**:
```
## Issue Description
Implement offline download system for sound packs (premium feature).

## Current State
- OfflinePacksView shows "coming soon"
- No download logic implemented
- Premium feature not developed

## Future Feature for v1.1+
- Download sound packs for offline use
- Manage storage
- Delete downloaded packs
- Premium-only feature

## Deferred to v1.1
This is explicitly not needed for v1.0 release.
```

---

### Issue 17: Advanced Audio Controls (EQ, Effects)
**Labels**: low, enhancement, future
**Milestone**: v2.0
**Body**:
```
## Issue Description
Add advanced audio controls like equalizer, reverb, spatial audio.

## Future Feature for v2.0+
- Equalizer with presets
- Audio effects (reverb, delay)
- Spatial audio support
- Advanced mixing controls

## Deferred to v2.0
This is explicitly not needed for v1.0 release.
```

---

## Setup Instructions

To create all issues at once, run:
```bash
chmod +x .github/create_issues.sh
./.github/create_issues.sh
```

Or create manually through GitHub web interface using templates in `.github/ISSUE_TEMPLATE/`
