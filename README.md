# BabySounds

BabySounds is a compact iOS 17+ SwiftUI app for quick night-time sleep sound playback.

The current product direction is intentionally simple: open the app, choose a sound, adjust the sleep timer if needed, and keep playback available through background audio, widgets, and system Now Playing controls.

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
- Background audio with Now Playing metadata and remote playback controls
- System volume and AirPlay route controls in the player
- WidgetKit quick-start widgets
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

Shared widget models live in `BabySoundsApp/BabySoundsShared.swift`.

Widget UI lives in `BabySoundsWidget/BabySoundsWidgetBundle.swift`.

## Assets

- `BabySoundsApp/Assets.xcassets` contains the app icon and launch screen assets.
- `BabySoundsApp/DesignAssets` contains generated UI artwork used by SwiftUI at runtime.
- Sound illustrations are stored as portrait 9:16 PNG files for player backgrounds and cropped into cards in the catalog.

## Development

Build the app target for Simulator:

```bash
xcodebuild \
  -project BabySoundsApp.xcodeproj \
  -scheme BabySoundsApp \
  -configuration Debug \
  -sdk iphonesimulator \
  -derivedDataPath build/DerivedData build
```

Install and launch the built app on the booted simulator:

```bash
xcrun simctl install booted build/DerivedData/Build/Products/Debug-iphonesimulator/BabySoundsApp.app
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
- Lock Screen and Control Center playback use native Now Playing metadata and remote commands.
- Public landing and release documents are served from GitHub Pages at `https://vpavlov-me.github.io/BabySounds/`.
- In-app Privacy, Terms, Support, and TestFlight links point to the root GitHub Pages documents.

## Repository Hygiene

The repository intentionally keeps only the Xcode project, app source, widget source, local assets, license, and this README.

Ignored local files include Xcode user data, build products, DerivedData, local environment files, and IDE folders.
