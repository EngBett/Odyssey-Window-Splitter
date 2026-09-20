#!/bin/bash
#
# Build a shareable OdysseyWindowSplitter release: a universal (Apple Silicon +
# Intel) Release build, signed, packaged as a .dmg and a .zip under dist/.
#
#   scripts/build-release.sh
#
# By default the app is ad-hoc signed, which is all a local build can do without
# an Apple Developer Program membership. macOS will quarantine it on the
# recipient's Mac; INSTALL.md tells them how to get past that in one command.
#
# If you do have a Developer ID certificate, set these and the script will sign
# and notarize properly, so the app opens with no warning at all:
#
#   SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE=odyssey \
#   scripts/build-release.sh
#
# NOTARY_PROFILE is a keychain profile created once with:
#   xcrun notarytool store-credentials odyssey \
#     --apple-id you@example.com --team-id TEAMID --password <app-specific-password>

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$PROJECT_ROOT/OdysseyWindowSplitter.xcodeproj"
TARGET="OdysseyWindowSplitter"
APP_NAME="OdysseyWindowSplitter"
DIST="$PROJECT_ROOT/dist"
WORK="$PROJECT_ROOT/dist/.build"

SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# --- preflight ---------------------------------------------------------------

command -v xcodebuild >/dev/null || die "xcodebuild not found. Install Xcode from the App Store."

if ! xcrun --sdk macosx --show-sdk-path >/dev/null 2>&1; then
  die "The Xcode command line tools are not ready. Run these once, then retry:
    sudo xcodebuild -license accept
    sudo xcodebuild -runFirstLaunch"
fi

if ! xcodebuild -project "$PROJECT" -list >/dev/null 2>&1; then
  die "xcodebuild cannot read the project. Open Xcode once and let it finish
installing its components, then retry. If it still fails, run:
    sudo xcodebuild -runFirstLaunch"
fi

# --- build -------------------------------------------------------------------

rm -rf "$WORK"
mkdir -p "$WORK" "$DIST"

say "Building universal Release binary"

# Without a real certificate, build unsigned and ad-hoc sign afterwards; that
# way the signature covers exactly the bundle we ship.
if [[ -n "$SIGN_IDENTITY" ]]; then
  SIGN_ARGS=(
    CODE_SIGN_IDENTITY="$SIGN_IDENTITY"
    CODE_SIGN_STYLE=Manual
    ENABLE_HARDENED_RUNTIME=YES
  )
else
  SIGN_ARGS=(
    CODE_SIGN_IDENTITY="-"
    CODE_SIGNING_REQUIRED=NO
    CODE_SIGNING_ALLOWED=NO
  )
fi

xcodebuild \
  -project "$PROJECT" \
  -target "$TARGET" \
  -configuration Release \
  -derivedDataPath "$WORK/DerivedData" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  "${SIGN_ARGS[@]}" \
  build

APP="$WORK/DerivedData/Build/Products/Release/$APP_NAME.app"
[[ -d "$APP" ]] || die "Build succeeded but $APP is missing."

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
say "Built $APP_NAME $VERSION"
lipo -archs "$APP/Contents/MacOS/$APP_NAME" | sed 's/^/    architectures: /'

# --- sign --------------------------------------------------------------------

# Stray xattrs (quarantine, Finder info) make codesign fail or produce a
# signature that breaks the moment the bundle is copied.
xattr -cr "$APP"

if [[ -n "$SIGN_IDENTITY" ]]; then
  say "Signing with $SIGN_IDENTITY"
  codesign --force --timestamp --options runtime \
    --sign "$SIGN_IDENTITY" "$APP"
else
  say "Ad-hoc signing (no Developer ID certificate configured)"
  codesign --force --sign - "$APP"
fi

codesign --verify --strict --verbose=2 "$APP" 2>&1 | sed 's/^/    /'

# --- package -----------------------------------------------------------------

say "Packaging disk image"

STAGE="$WORK/stage"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
cp "$PROJECT_ROOT/INSTALL.md" "$STAGE/Read Me First.txt"

DMG="$DIST/$APP_NAME-$VERSION.dmg"
rm -f "$DMG"
hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$STAGE" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  "$DMG" >/dev/null

ZIP="$DIST/$APP_NAME-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --keepParent --sequesterRsrc "$APP" "$ZIP"

# --- notarize ----------------------------------------------------------------

if [[ -n "$NOTARY_PROFILE" ]]; then
  [[ -n "$SIGN_IDENTITY" ]] || die "NOTARY_PROFILE needs SIGN_IDENTITY: Apple only notarizes Developer ID signed apps."
  say "Notarizing (this takes a few minutes)"
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
  xcrun stapler staple "$APP"
  rm -f "$ZIP"
  ditto -c -k --keepParent --sequesterRsrc "$APP" "$ZIP"
  say "Notarized and stapled"
elif [[ -z "$SIGN_IDENTITY" ]]; then
  cat <<'NOTE'

    Note: this build is ad-hoc signed, not notarized. macOS on the receiving
    Mac will refuse to open it until the quarantine flag is cleared. That is
    expected, and "Read Me First.txt" inside the disk image explains the
    one-line fix. See INSTALL.md.
NOTE
fi

# --- done --------------------------------------------------------------------

rm -rf "$STAGE"

say "Done"
for artifact in "$DMG" "$ZIP"; do
  printf '    %s\n' "$artifact"
  printf '    sha256  %s\n' "$(shasum -a 256 "$artifact" | cut -d' ' -f1)"
done
