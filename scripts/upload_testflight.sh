#!/bin/bash
# =============================================================================
# BabySounds — TestFlight Upload Script
# =============================================================================
# Usage:
#   1. Set DEVELOPMENT_TEAM below to your Apple Developer Team ID
#      (find it at https://developer.apple.com/account -> Membership -> Team ID)
#   2. Run: bash scripts/upload_testflight.sh
#
# Prerequisites:
#   - Xcode 15.4+
#   - Signed in to Xcode with your Apple ID (Xcode > Settings > Accounts)
#   - App created in App Store Connect with Bundle ID: com.babysounds.app
# =============================================================================

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
TEAM_ID="${1:-}"          # Pass as first arg: bash upload_testflight.sh XXXXXXXXXX
SCHEME="BabySoundsApp"
WORKSPACE="BabySounds.xcworkspace"
ARCHIVE_PATH="./build/BabySounds.xcarchive"
EXPORT_PATH="./build/export"
EXPORT_OPTIONS="./ExportOptions.plist"

# ── Validate inputs ───────────────────────────────────────────────────────────
if [[ -z "$TEAM_ID" ]]; then
    echo "❌ Usage: bash scripts/upload_testflight.sh YOUR_TEAM_ID"
    echo "   Find your Team ID at: https://developer.apple.com/account (Membership tab)"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  BabySounds → TestFlight"
echo "  Team: $TEAM_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Bump build number (auto-increment) ────────────────────────────────────────
CURRENT_BUILD=$(agvtool what-version -terse 2>/dev/null || echo "0")
NEW_BUILD=$((CURRENT_BUILD + 1))
echo "📦 Build number: $CURRENT_BUILD → $NEW_BUILD"
agvtool new-version -all "$NEW_BUILD"

# ── Clean ─────────────────────────────────────────────────────────────────────
mkdir -p build
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

# ── Archive ───────────────────────────────────────────────────────────────────
echo ""
echo "🔨 Archiving..."
xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_ASSET_PATHS="" \
    | xcpretty --simple 2>/dev/null || true

# Fallback without xcpretty
if [[ ! -d "$ARCHIVE_PATH" ]]; then
    xcodebuild archive \
        -workspace "$WORKSPACE" \
        -scheme "$SCHEME" \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=iOS" \
        DEVELOPMENT_TEAM="$TEAM_ID" \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_ASSET_PATHS="" \
        2>&1 | grep -E "error:|warning:|ARCHIVE SUCCEEDED|ARCHIVE FAILED" | tail -20
fi

if [[ ! -d "$ARCHIVE_PATH" ]]; then
    echo "❌ Archive failed. Check output above."
    exit 1
fi
echo "✅ Archive created: $ARCHIVE_PATH"

# ── Export & Upload ───────────────────────────────────────────────────────────
echo ""
echo "☁️  Exporting and uploading to App Store Connect..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$EXPORT_PATH" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    2>&1 | grep -E "error:|EXPORT|Upload|success" | tail -20

if [[ $? -eq 0 ]]; then
    echo ""
    echo "✅ Upload complete!"
    echo "   → Go to https://appstoreconnect.apple.com → TestFlight"
    echo "   → Wait ~15 minutes for processing"
    echo "   → Add internal testers and distribute"
else
    echo "❌ Export/upload failed. Check output above."
    exit 1
fi
