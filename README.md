# Odyssey Window Splitter

A native macOS menu-bar application that moves and resizes the currently focused
window into custom screen regions — three columns, four columns, two-thirds,
25/50/25, halves, and maximize — designed for a 49-inch Samsung Odyssey ultrawide
alongside the MacBook display.

The full product specification lives in
[OdysseyWindowSplitter_README.md](OdysseyWindowSplitter_README.md).

## Requirements

- macOS 14.0 or later
- Xcode 16 or later to build

## Building in Xcode

```bash
open OdysseyWindowSplitter.xcodeproj
```

1. Select the `OdysseyWindowSplitter` scheme.
2. Select `My Mac` as the destination.
3. Build with `Command + B`, run with `Command + R`.
4. Grant Accessibility permission when prompted (see below).

## Building from the command line

```bash
xcodebuild \
  -project OdysseyWindowSplitter.xcodeproj \
  -scheme OdysseyWindowSplitter \
  -configuration Debug \
  -destination 'platform=macOS' \
  build
```

Run the unit tests with:

```bash
xcodebuild \
  -project OdysseyWindowSplitter.xcodeproj \
  -scheme OdysseyWindowSplitter \
  -destination 'platform=macOS' \
  test
```

## Accessibility permission

The app moves windows belonging to other applications, which requires macOS
Accessibility permission:

1. Launch the app. A window-splitter icon appears in the menu bar.
2. Choose **Request Accessibility Permission** from the menu (or in Settings),
   or open **System Settings → Privacy & Security → Accessibility** directly
   via the menu item.
3. Enable **OdysseyWindowSplitter** in the list.
4. If layouts still fail, quit and reopen the app.

Note: Accessibility approval is tied to the signed application identity and
path. Rebuilding the app (which re-signs it) or moving the bundle may require
re-granting the permission. For local development the app is signed to run
locally (ad-hoc); this is expected.

## Usage

- Click the menu-bar icon and pick a layout — it is applied to the window that
  was focused before you opened the menu, on the display that window occupies.
- Global shortcuts (Control + Option):
  - `⌃⌥1` / `⌃⌥2` / `⌃⌥3` — left / centre / right third
  - `⌃⌥4` … `⌃⌥7` — quarters 1–4
  - `⌃⌥←` / `⌃⌥→` — left / right half
  - `⌃⌥↑` — maximize to visible area
- The gap between windows and screen edges is configurable (0–16 pt, default 6)
  from the menu or the Settings window, which also offers launch-at-login and a
  global-shortcuts toggle.

## Design and configuration decisions

- **No App Sandbox.** The target has no sandbox entitlement because sandboxed
  processes cannot use the Accessibility API to control other apps' windows.
  This build is for local use and is not Mac App Store ready.
- **Hardened Runtime is off** in this local configuration so the hosted unit
  tests can inject into the app. Enable it (plus real signing) for distribution.
- **Global shortcuts** use the native Carbon `RegisterEventHotKey` API — no
  third-party dependencies. Registration conflicts are reported in Settings.
- **Layout math is pure** (`LayoutCalculator`, `CoordinateConverter`,
  `ScreenSelection`) and fully unit-tested; boundaries are computed first and
  frames derived from adjacent boundaries so indivisible widths (e.g. 5120/3)
  never overlap or leave a stray strip.
- **Layouts never touch Apple's green-button menu**; macOS provides no public
  API for that.

## Known limitations

- Full-screen (native Split View) windows are refused with a clear message.
- Windows with a minimum size larger than the target region are resized as far
  as the app allows; the result message notes that the frame was adjusted.
- After rebuilding, macOS may silently ignore AX calls until Accessibility
  permission is re-granted for the new binary.
- The visual layout picker (spec §5, phase 2) is not yet implemented; the menu
  and shortcuts cover all layouts.

## Testing

Automated results and the manual checklist live in [TEST_REPORT.md](TEST_REPORT.md).
