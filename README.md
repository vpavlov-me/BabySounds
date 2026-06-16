# BabySounds

BabySounds is a compact iOS 17+ SwiftUI app for parents who need to start a calming sleep sound quickly, especially at night.

The MVP flow is intentionally simple: open the app, choose one sound, set a sleep timer, lock the phone, and keep playback available through background audio and Lock Screen / Control Center controls.

## Features

- Simple sound catalog with white, pink, brown, fan, nature, heartbeat, and womb-style sounds
- Generated audio playback with no bundled sound-file dependencies
- Single-sound playback: starting a new sound stops the previous one
- Background audio with Now Playing metadata for Lock Screen and Control Center
- Sleep Timer with 15, 30, 45, and 60 minute options
- Gentle 30 second fade out when the timer ends
- Favorites for quick access to preferred sounds
- Premium support through StoreKit for premium sounds and extended 45/60 minute timers
- Settings with restore purchases, feedback, rating, privacy policy, and terms links
- Display-only Live Activity integration for active playback and timer state
- Offline-friendly UI using SF Symbols and local SwiftUI artwork, not remote placeholder images

## Requirements

- iOS 17.0+
- Xcode 26.5 in the current local setup
- Swift 6

## Project Structure

```text
BabySounds/
├── BabySoundsApp.xcodeproj
├── BabySoundsApp/
│   ├── BabySoundsAppApp.swift
│   ├── ContentView.swift
│   ├── Info.plist
│   ├── BabySoundsApp.entitlements
│   └── Assets.xcassets/
├── LICENSE
└── README.md
```

Most of the current MVP implementation lives in `BabySoundsApp/ContentView.swift`.

## Development

Build for the booted simulator:

```bash
xcodebuild \
  -project BabySoundsApp.xcodeproj \
  -scheme BabySoundsApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=22EA8DBA-AC1A-4F15-ADAC-DC10511EF70A' \
  -configuration Debug build
```

Launch after building:

```bash
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/BabySoundsApp-*/Build/Products/Debug-iphonesimulator/BabySoundsApp.app
xcrun simctl launch booted com.babysounds.app
```

## Notes

- The app is parent-operated; it is not a child-facing play product in the MVP.
- Live Activity is display-only and mirrors active sound/timer state without adding remote controls.
- Asset catalogs are not part of the current app target resources because the local environment has an iOS SDK/runtime mismatch that breaks `actool`; the UI does not depend on those assets.
