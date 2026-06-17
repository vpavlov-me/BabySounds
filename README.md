# BabySounds

BabySounds is a compact iOS 17+ SwiftUI app for quick night-time sleep sound playback.

The current product direction is intentionally simple: open the app, choose a sound, adjust the sleep timer if needed, and keep playback available through background audio, widgets, and Live Activity status.

## Current Features

- Two-column sound catalog with visual sound cards
- Local 9:16 artwork for sound detail backgrounds
- Single active sound at a time
- Full-screen player sheet with swipe navigation between sounds
- Sleep timer sheet with circular time selection
- Optional fade-out at the end of the timer
- Favorites tab with an illustrated empty state
- Icon-only bottom tab bar
- Dark mode by default
- Native launch screen with centered app icon
- Background audio with Now Playing metadata
- WidgetKit quick-start widgets
- Display-only Live Activity for current playback and timer state
- StoreKit premium gate for premium sounds and longer timer durations

## Requirements

- iOS 17.0+
- Xcode 26.5 in the current local setup
- Swift 6

## Project Structure

```text
BabySound/
├── BabySoundsApp.xcodeproj
├── BabySoundsApp/
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/
│   │   ├── LaunchBackground.colorset/
│   │   └── LaunchIcon.imageset/
│   ├── DesignAssets/
│   ├── BabySoundsApp.entitlements
│   ├── BabySoundsAppApp.swift
│   ├── BabySoundsShared.swift
│   ├── ContentView.swift
│   └── Info.plist
├── BabySoundsWidget/
│   ├── BabySoundsWidget.entitlements
│   ├── BabySoundsWidgetBundle.swift
│   └── Info.plist
├── LICENSE
└── README.md
```

Most of the app UI, audio engine, premium flow, and settings are currently implemented in `BabySoundsApp/ContentView.swift`.

Shared widget and Live Activity models live in `BabySoundsApp/BabySoundsShared.swift`.

Widget and Live Activity UI live in `BabySoundsWidget/BabySoundsWidgetBundle.swift`.

## Assets

- `BabySoundsApp/Assets.xcassets` contains the app icon and launch screen assets.
- `BabySoundsApp/DesignAssets` contains generated UI artwork used by SwiftUI at runtime.
- Sound illustrations are stored as portrait 9:16 PNG files for player backgrounds and cropped into cards in the catalog.

## Development

Build the app target for Simulator:

```bash
xcodebuild \
  -project BabySoundsApp.xcodeproj \
  -target BabySoundsApp \
  -configuration Debug \
  -sdk iphonesimulator build
```

Install and launch the built app on the booted simulator:

```bash
xcrun simctl install booted build/Debug-iphonesimulator/BabySoundsApp.app
xcrun simctl launch booted com.babysounds.app
```

To reset the installed app during UI checks:

```bash
xcrun simctl terminate booted com.babysounds.app || true
xcrun simctl uninstall booted com.babysounds.app || true
```

## Runtime Notes

- The app group is `group.com.babysounds.app`.
- Deep links use the `babysounds://` scheme.
- Widgets can start playback via `babysounds://play?soundId=...`.
- `babysounds://open?soundId=...` opens the player sheet for a sound.
- Live Activity mirrors playback and timer state; it does not expose remote controls.

## Repository Hygiene

The repository intentionally keeps only the Xcode project, app source, widget source, local assets, license, and this README.

Ignored local files include Xcode user data, build products, DerivedData, local environment files, and IDE folders.
