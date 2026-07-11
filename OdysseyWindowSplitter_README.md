# Odyssey Window Splitter for macOS

A native macOS menu-bar application that moves and resizes the currently focused window into custom screen regions.

The primary target is a 49-inch Samsung Odyssey ultrawide monitor connected to a MacBook. macOS currently provides common layouts such as left half and right half, but this application must add layouts such as:

- Three equal vertical columns
- Four equal vertical columns
- Two-thirds and one-third layouts
- A 25% / 50% / 25% layout
- Keyboard shortcuts for quickly placing the active window
- Correct behavior on multiple monitors

This document is intended to be given to Codex or another coding agent to implement, run, test, and improve the application.

---

## 1. Objective

Build a reliable native macOS application named **Odyssey Window Splitter**.

The application must:

1. Run as a menu-bar application.
2. Detect the currently focused application window.
3. Identify the display containing the focused window.
4. Calculate the selected layout region using the display's usable frame.
5. Move and resize the focused window into that region.
6. Support both the Samsung ultrawide monitor and the MacBook display.
7. Request and verify macOS Accessibility permission.
8. Provide menu items and global keyboard shortcuts.
9. Include unit tests for layout calculations.
10. Include a practical manual test checklist for window manipulation.

Do not attempt to modify or inject items into Apple's native green-button menu. macOS does not expose a supported public API for adding custom layout options to that menu.

---

## 2. Technology Requirements

Use:

- Swift
- SwiftUI
- AppKit
- ApplicationServices Accessibility APIs
- XCTest
- Xcode project targeting macOS

Preferred minimum deployment target:

```text
macOS 14.0 or later
```

The app should be designed to work on current macOS releases as well.

Use a menu-bar application based on:

```swift
MenuBarExtra
```

Use macOS Accessibility APIs such as:

```swift
AXIsProcessTrusted()
AXIsProcessTrustedWithOptions(_:)
AXUIElementCreateSystemWide()
AXUIElementCopyAttributeValue(...)
AXUIElementSetAttributeValue(...)
```

Use `NSScreen.visibleFrame` so that the menu bar and Dock are excluded from the calculated layout area.

---

## 3. Project Name and Suggested Structure

Create an Xcode project named:

```text
OdysseyWindowSplitter
```

Suggested structure:

```text
OdysseyWindowSplitter/
├── OdysseyWindowSplitter.xcodeproj
├── OdysseyWindowSplitter/
│   ├── App/
│   │   └── OdysseyWindowSplitterApp.swift
│   ├── Accessibility/
│   │   ├── AccessibilityPermission.swift
│   │   └── AccessibilityError.swift
│   ├── Models/
│   │   ├── WindowLayout.swift
│   │   ├── LayoutRegion.swift
│   │   └── DisplayDescriptor.swift
│   ├── Services/
│   │   ├── FocusedWindowProvider.swift
│   │   ├── ScreenProvider.swift
│   │   ├── WindowManager.swift
│   │   ├── LayoutCalculator.swift
│   │   └── CoordinateConverter.swift
│   ├── Shortcuts/
│   │   └── GlobalShortcutManager.swift
│   ├── Views/
│   │   ├── SplitterMenuView.swift
│   │   ├── LayoutPickerView.swift
│   │   └── PermissionHelpView.swift
│   ├── Utilities/
│   │   └── Logger.swift
│   └── Resources/
│       └── Assets.xcassets
├── OdysseyWindowSplitterTests/
│   ├── LayoutCalculatorTests.swift
│   ├── CoordinateConverterTests.swift
│   └── ScreenSelectionTests.swift
└── README.md
```

Keep layout calculation code independent from Accessibility APIs so that it can be unit-tested without moving real windows.

---

## 4. Functional Requirements

### 4.1 Menu-bar application

The application must run primarily from the macOS menu bar.

The menu should contain:

```text
Odyssey Window Splitter

Three Columns
  Left Third
  Centre Third
  Right Third

Four Columns
  Quarter 1
  Quarter 2
  Quarter 3
  Quarter 4

Wide Layouts
  Left Two Thirds
  Right Two Thirds
  25 / 50 / 25 - Left
  25 / 50 / 25 - Centre
  25 / 50 / 25 - Right

Other
  Left Half
  Right Half
  Centre Half
  Maximize to Visible Area

Settings
  Gap Size
  Request Accessibility Permission
  Open Accessibility Settings

Quit
```

The first version may use a text menu. A visual layout picker can be added after the core window-management functionality works.

---

### 4.2 Required layouts

Create a strongly typed layout model.

At minimum, support:

```swift
enum WindowLayout: String, CaseIterable, Identifiable {
    case leftThird
    case centerThird
    case rightThird

    case quarter1
    case quarter2
    case quarter3
    case quarter4

    case leftTwoThirds
    case rightTwoThirds

    case leftHalf
    case rightHalf
    case centerHalf

    case twentyFiveFiftyTwentyFiveLeft
    case twentyFiveFiftyTwentyFiveCenter
    case twentyFiveFiftyTwentyFiveRight

    case maximizeVisibleArea
}
```

Use `center` in source-code identifiers for consistency, but display `Centre` or `Center` in the UI according to the chosen product language.

---

### 4.3 Layout behavior

Given a display's visible frame:

```swift
CGRect(x: originX, y: originY, width: width, height: height)
```

calculate destination frames as follows.

#### Three equal columns

```text
Column width = visible width / 3
```

- Left third: first column
- Centre third: second column
- Right third: third column

#### Four equal columns

```text
Column width = visible width / 4
```

- Quarter 1: first quarter
- Quarter 2: second quarter
- Quarter 3: third quarter
- Quarter 4: fourth quarter

#### Two-thirds layouts

- Left two-thirds: first 2/3 of the visible frame
- Right two-thirds: final 2/3 of the visible frame

#### 25 / 50 / 25 layouts

- Left: first 25%
- Centre: middle 50%
- Right: final 25%

#### Centre half

- Width: 50% of the visible frame
- Horizontal origin: 25% from the left edge

#### Maximize

Use the full `visibleFrame`, not the raw display frame.

---

### 4.4 Gaps

Support a configurable gap between windows and screen edges.

Default:

```text
6 points
```

The gap should be applied carefully so adjacent windows have visually consistent spacing.

Do not use only `CGRect.insetBy(dx:dy:)` for every layout without considering shared boundaries. A better approach is:

- Apply outer margins to the display edges.
- Apply half the configured gap on each side of an internal boundary.
- Ensure the resulting frame never has a negative width or height.

Example for three columns:

```text
| margin | window 1 | gap | window 2 | gap | window 3 | margin |
```

Persist the selected gap size with:

```swift
@AppStorage
```

Suggested options:

```text
0, 4, 6, 8, 12, 16
```

---

### 4.5 Focused window detection

The application must:

1. Obtain the system-wide Accessibility element.
2. Obtain the focused application.
3. Obtain the focused window for that application.
4. Read its current position and size.
5. Return a clear error if no focused window can be found.

Create a protocol so the implementation can be mocked:

```swift
protocol FocusedWindowProviding {
    func focusedWindow() throws -> AXUIElement
}
```

Handle common cases such as:

- No focused application
- No focused window
- Desktop or Finder has focus
- Application does not expose a standard resizable window
- Window is minimized
- Window does not permit resizing
- Accessibility permission is missing

Do not crash when a window cannot be manipulated.

---

### 4.6 Screen detection

The application must move the window within the screen where the window currently resides.

Use the current window frame and determine the best matching display.

Preferred selection algorithm:

1. Calculate the intersection area between the window frame and each screen.
2. Select the screen with the largest intersection area.
3. If no screen intersects, select the screen containing the window center.
4. If still unresolved, fall back to `NSScreen.main`.
5. If `NSScreen.main` is unavailable, return a descriptive error.

This is more reliable than checking only the window center, especially when a window overlaps two monitors.

---

### 4.7 Coordinate conversion

AppKit and Accessibility coordinates can use different vertical origins.

Create a dedicated coordinate-conversion service.

Do not scatter coordinate conversion formulas throughout `WindowManager`.

Example interface:

```swift
protocol CoordinateConverting {
    func appKitToAccessibility(_ frame: CGRect, screens: [NSScreen]) -> CGRect
    func accessibilityToAppKit(_ frame: CGRect, screens: [NSScreen]) -> CGRect
}
```

The implementation must work when:

- The external monitor is left of the MacBook display.
- The external monitor is right of the MacBook display.
- One display is vertically offset.
- The MacBook display is above or below the external monitor.
- Displays use different scaling modes.

Add tests for negative screen origins and vertically offset displays.

---

### 4.8 Resizing the window

When applying a target frame:

1. Verify the app has Accessibility permission.
2. Verify that the focused window supports position and size changes.
3. Convert the target frame into Accessibility coordinates.
4. Set the window position.
5. Set the window size.
6. Set the position again if necessary for compatibility.
7. Read the final window position and size.
8. Log a warning if the actual frame differs materially from the requested frame.

Some applications enforce a minimum width or height. Treat this as a recoverable limitation.

Return a result rather than silently failing:

```swift
struct WindowMoveResult {
    let requestedFrame: CGRect
    let actualFrame: CGRect?
    let wasSuccessful: Bool
    let message: String
}
```

---

### 4.9 Accessibility permission

On first launch:

1. Check `AXIsProcessTrusted()`.
2. If not trusted, show a clear explanation.
3. Provide a button to request permission.
4. Provide a button to open:

```text
System Settings → Privacy & Security → Accessibility
```

5. Explain that the user may need to quit and reopen the app after enabling permission.

The app must remain usable enough to show permission instructions even when permission has not yet been granted.

Use a user-friendly error message such as:

```text
Odyssey Window Splitter needs Accessibility permission to move and resize windows from other applications.
```

---

### 4.10 Global keyboard shortcuts

Add configurable global keyboard shortcuts.

Default shortcuts:

```text
Control + Option + 1   Left third
Control + Option + 2   Centre third
Control + Option + 3   Right third

Control + Option + 4   Quarter 1
Control + Option + 5   Quarter 2
Control + Option + 6   Quarter 3
Control + Option + 7   Quarter 4

Control + Option + Left Arrow    Left half
Control + Option + Right Arrow   Right half
Control + Option + Up Arrow      Maximize visible area
```

Avoid overriding common system shortcuts.

The shortcut implementation should:

- Register shortcuts when the app starts.
- Unregister shortcuts when the app exits.
- Report registration conflicts.
- Keep shortcut definitions centralized.
- Allow shortcuts to be disabled.

Use an established, maintainable approach compatible with the target macOS version. Prefer native APIs where practical. If a small third-party package is used, document why it is required and keep dependencies minimal.

---

## 5. User Interface Requirements

### Initial version

Implement a standard `MenuBarExtra` menu.

Each action should:

1. Capture or identify the currently focused window.
2. Apply the selected layout.
3. Display a brief error notification if the operation fails.

Add a settings window containing:

- Gap size
- Launch at login toggle
- Enable global shortcuts toggle
- Accessibility permission status
- Open Accessibility Settings button
- About section
- Version number

### Optional second phase

Add a visual layout picker resembling the style of the macOS Move & Resize menu.

The picker should display:

- A three-column icon
- A four-column icon
- A 25/50/25 icon
- Two-thirds layouts

Clicking a region should place the previously active window into that region.

Be careful: opening the menu-bar app may cause focus to shift away from the target application. Preserve a reference to the previously active application or focused window before showing the picker where possible.

---

## 6. Architecture

Use small, testable components.

Suggested protocols:

```swift
protocol LayoutCalculating {
    func frame(
        for layout: WindowLayout,
        in visibleFrame: CGRect,
        gap: CGFloat
    ) -> CGRect
}

protocol ScreenProviding {
    var screens: [NSScreen] { get }
    func screen(containing windowFrame: CGRect) -> NSScreen?
}

protocol WindowManaging {
    func apply(_ layout: WindowLayout) async -> WindowMoveResult
}

protocol AccessibilityPermissionProviding {
    var isTrusted: Bool { get }
    func requestPermission()
}
```

Avoid placing all logic in one large `WindowManager` class.

Use dependency injection so unit tests can supply fake screen data and fake window frames.

---

## 7. Error Handling

Create a dedicated error type:

```swift
enum WindowManagerError: LocalizedError {
    case accessibilityPermissionDenied
    case focusedApplicationNotFound
    case focusedWindowNotFound
    case positionUnavailable
    case sizeUnavailable
    case screenNotFound
    case windowNotMovable
    case windowNotResizable
    case failedToSetPosition(AXError)
    case failedToSetSize(AXError)

    var errorDescription: String? {
        // Human-readable messages
    }
}
```

Never use force casts for values received from Accessibility APIs unless there is a prior type check.

Validate `AXValueGetType(_:)` before calling `AXValueGetValue`.

Log useful technical details without exposing private window contents.

---

## 8. Logging

Use Apple's unified logging system.

Create a logger using:

```swift
import OSLog
```

Suggested categories:

```text
accessibility
window-management
layout
screen-selection
shortcuts
application
```

Log:

- Permission status
- Focused window lookup failures
- Selected display
- Requested frame
- Actual final frame
- Accessibility API errors
- Shortcut registration failures

Do not log window titles by default.

---

## 9. Unit Tests

Create tests for all pure layout calculations.

Use deterministic `CGRect` values.

### 9.1 Three-column tests

For:

```swift
visibleFrame = CGRect(x: 0, y: 0, width: 3000, height: 1200)
gap = 0
```

expect:

```text
Left third:
x = 0
y = 0
width = 1000
height = 1200

Centre third:
x = 1000
width = 1000

Right third:
x = 2000
width = 1000
```

### 9.2 Four-column tests

For:

```swift
visibleFrame = CGRect(x: 100, y: 50, width: 4000, height: 1300)
gap = 0
```

expect quarter widths of `1000` and origins based on the frame's `minX`.

### 9.3 Two-thirds tests

Verify:

- Left two-thirds starts at `minX`.
- Right two-thirds starts one-third from `minX`.
- Both use exactly two-thirds of the available width before gaps.

### 9.4 25 / 50 / 25 tests

Verify:

- Left region is 25%.
- Centre region is 50%.
- Right region is 25%.
- All three regions cover the full width without overlap when gap is zero.

### 9.5 Gap tests

Verify that:

- Outer margins are applied.
- Internal spaces equal the selected gap.
- Adjacent frames do not overlap.
- The final right edge does not exceed `visibleFrame.maxX`.
- Width and height never become negative.
- Gap zero produces exact mathematical divisions.

### 9.6 Non-zero screen origins

Test:

```swift
CGRect(x: -5120, y: 100, width: 5120, height: 1440)
```

This represents an external monitor positioned to the left.

Verify all output frames preserve the negative origin correctly.

### 9.7 Rounding tests

Display widths may not be perfectly divisible by three or four.

For example:

```swift
width = 5120
```

Ensure:

- Frames use pixel-safe or point-safe rounding.
- No visible unallocated strip remains at the far right.
- The final region's maximum X equals the usable frame's maximum X, after accounting for margins.
- Adjacent regions do not overlap.

Prefer calculating boundaries first, then deriving widths from adjacent boundaries.

---

## 10. Integration and Manual Testing

Accessibility APIs cannot be fully tested with ordinary unit tests. Add a manual test plan.

### Test environment

Record:

- Mac model
- macOS version
- Samsung Odyssey model
- Monitor resolution
- Monitor scaling selection
- Whether the MacBook display is enabled
- Relative monitor arrangement
- Dock position
- Whether the menu bar appears on one or multiple displays

### Applications to test

Test with:

- Finder
- Safari
- Google Chrome
- Visual Studio Code
- Xcode
- Terminal
- Notes
- Slack or another Electron app
- A standard SwiftUI app

### Manual test cases

#### Permission flow

- Launch without Accessibility permission.
- Confirm the app explains why permission is required.
- Confirm the Accessibility Settings button opens the correct settings page.
- Grant permission.
- Restart the app.
- Confirm the app detects that permission is now available.

#### Three-column layout

For each supported app:

- Focus the app window.
- Apply Left Third.
- Verify it moves to the left third of the same monitor.
- Apply Centre Third.
- Verify it occupies the centre third.
- Apply Right Third.
- Verify it occupies the right third.

#### Four-column layout

Repeat for Quarter 1 through Quarter 4.

#### Wide layouts

Test:

- Left two-thirds
- Right two-thirds
- 25% left
- 50% centre
- 25% right
- Centre half

#### Multi-monitor behavior

- Place the test window entirely on the Samsung monitor.
- Apply a layout and confirm it remains on that monitor.
- Move the test window to the MacBook display.
- Apply a layout and confirm it remains on the MacBook display.
- Place the window halfway between both displays.
- Confirm the display with the largest intersection area is selected.
- Rearrange displays in System Settings and repeat.

#### Dock behavior

Test with the Dock:

- On the left
- On the right
- At the bottom
- Automatically hidden
- Always visible

Confirm the app uses `visibleFrame`.

#### Menu-bar behavior

- Confirm selecting a menu command affects the previously focused application window, not the app's own settings window.
- Confirm repeated layout commands work.
- Confirm quitting removes registered shortcuts.

#### Minimum-size windows

- Test a window with a minimum width larger than one quarter.
- Confirm the app does not crash.
- Confirm it reports that the application constrained the requested frame.

#### Full-screen windows

- Test a native macOS full-screen window.
- The app may refuse to resize it.
- Confirm the failure is handled gracefully and clearly.

#### Minimized windows

- Test a minimized window.
- Confirm the app does not crash.
- Either restore it before resizing or report that minimized windows are unsupported.

---

## 11. Acceptance Criteria

The first release is complete when all of the following are true:

- [ ] The app builds in Xcode without warnings.
- [ ] The app runs as a menu-bar application.
- [ ] The app requests Accessibility permission.
- [ ] The permission status is visible in the UI.
- [ ] Left, centre, and right thirds work.
- [ ] All four vertical quarters work.
- [ ] Left and right two-thirds work.
- [ ] The 25 / 50 / 25 regions work.
- [ ] Centre half works.
- [ ] Maximize uses the display's visible frame.
- [ ] The currently focused window is manipulated.
- [ ] The window remains on its current monitor.
- [ ] Multi-monitor coordinate conversion works.
- [ ] Negative display origins work.
- [ ] A configurable window gap works.
- [ ] Global shortcuts work.
- [ ] Shortcut conflicts are handled.
- [ ] Layout unit tests pass.
- [ ] Coordinate conversion tests pass.
- [ ] Screen-selection tests pass.
- [ ] Unsupported windows fail gracefully.
- [ ] No force-cast crash paths remain in Accessibility code.
- [ ] The README includes build and permission instructions.
- [ ] Manual testing has been completed on the Samsung Odyssey monitor.

---

## 12. Build Instructions

Codex must update this section with the exact final instructions after creating the project.

Expected workflow:

```bash
git clone <repository-url>
cd OdysseyWindowSplitter
open OdysseyWindowSplitter.xcodeproj
```

Then:

1. Select the `OdysseyWindowSplitter` scheme.
2. Select `My Mac` as the destination.
3. Build with `Command + B`.
4. Run with `Command + R`.
5. Grant Accessibility permission when prompted.
6. Quit and reopen the app if required.

Also provide a command-line build:

```bash
xcodebuild \
  -project OdysseyWindowSplitter.xcodeproj \
  -scheme OdysseyWindowSplitter \
  -configuration Debug \
  -destination 'platform=macOS' \
  build
```

Run tests with:

```bash
xcodebuild \
  -project OdysseyWindowSplitter.xcodeproj \
  -scheme OdysseyWindowSplitter \
  -destination 'platform=macOS' \
  test
```

Codex should execute these commands and fix all compilation or test failures.

---

## 13. Code-signing and Sandbox Notes

For local development:

- Use automatic signing if available.
- Use the developer's local Apple development team.
- Accessibility access is tied to the signed application identity and path.
- Rebuilding or moving the app may require Accessibility permission to be granted again.

Investigate App Sandbox compatibility before finalizing the project configuration.

For the initial local-only build, it is acceptable to disable App Sandbox if required for reliable Accessibility-based window control. Document the decision clearly in the final README.

Do not claim that the app is Mac App Store ready unless that has been verified.

---

## 14. Launch at Login

Add an optional launch-at-login setting using the appropriate modern macOS API.

The setting must:

- Default to off.
- Clearly show whether registration succeeded.
- Fail gracefully if registration is unavailable.
- Be covered by a small service abstraction so it can be tested.

This feature may be completed after the core layout functionality.

---

## 15. Codex Implementation Instructions

Codex should work in small, verifiable phases.

### Phase 1: Project setup

1. Create the macOS SwiftUI project.
2. Add the menu-bar application entry point.
3. Add a basic menu with a Quit button.
4. Build and run.
5. Commit the working baseline.

### Phase 2: Pure layout engine

1. Add `WindowLayout`.
2. Add `LayoutCalculator`.
3. Implement thirds, quarters, halves, two-thirds, 25/50/25, and maximize.
4. Add unit tests.
5. Run all tests.
6. Fix rounding and gap behavior.
7. Commit.

### Phase 3: Accessibility

1. Implement permission checking.
2. Implement focused-window lookup.
3. Implement reading and writing position and size.
4. Add detailed errors.
5. Add logging.
6. Build and perform a manual test.
7. Commit.

### Phase 4: Multi-monitor support

1. Implement screen selection by intersection area.
2. Implement coordinate conversion.
3. Add tests for negative and offset display origins.
4. Test on the Samsung monitor and MacBook display.
5. Commit.

### Phase 5: Menu commands

1. Connect every layout to the menu.
2. Preserve the previously active window where necessary.
3. Add settings for gap size.
4. Add permission-status UI.
5. Commit.

### Phase 6: Shortcuts

1. Register global shortcuts.
2. Detect registration conflicts.
3. Add an enable/disable setting.
4. Test every shortcut.
5. Commit.

### Phase 7: Polish

1. Add a visual layout picker.
2. Add launch-at-login support.
3. Add an About section.
4. Remove warnings.
5. Run all tests.
6. Complete the manual test checklist.
7. Update this README with final implementation details.

---

## 16. Rules for Codex

While implementing:

- Do not merely generate code without compiling it.
- Run `xcodebuild` after meaningful changes.
- Run the test suite after changes to layout, screen, or coordinate logic.
- Do not ignore compiler warnings.
- Do not use force unwraps or force casts in Accessibility code.
- Do not place all behavior in one class.
- Do not add unnecessary third-party dependencies.
- Do not modify Apple's native Move & Resize menu.
- Do not assume the external monitor is always the main display.
- Do not assume screen origins are positive.
- Do not assume display widths divide evenly by three or four.
- Do not silently ignore Accessibility errors.
- Keep the repository in a buildable state.
- Update this README when implementation decisions change.

When blocked:

1. State the exact error.
2. Include the failing command.
3. Explain the likely cause.
4. Make the smallest safe correction.
5. Re-run the command.
6. Record unresolved limitations honestly.

---

## 17. Final Deliverables

Codex must provide:

1. A complete Xcode project.
2. A working menu-bar application.
3. All source code.
4. Unit tests.
5. A passing `xcodebuild test` result.
6. Updated build instructions.
7. Accessibility permission instructions.
8. A manual testing report.
9. A list of known limitations.
10. Screenshots or a short screen recording demonstrating:
    - Three-column placement
    - Four-column placement
    - Multi-monitor behavior
    - Gap configuration
    - Keyboard shortcuts

---

## 18. Manual Test Report Template

Codex should create `TEST_REPORT.md` using this template:

```markdown
# Odyssey Window Splitter Test Report

## Environment

- Mac:
- macOS:
- Xcode:
- Samsung monitor:
- Resolution:
- Scaling:
- Display arrangement:
- Dock position:

## Automated Tests

Command:

```bash
xcodebuild ...
```

Result:

- Tests executed:
- Tests passed:
- Tests failed:

## Manual Tests

| Test | Result | Notes |
|---|---|---|
| Accessibility permission flow | Pass/Fail | |
| Left third | Pass/Fail | |
| Centre third | Pass/Fail | |
| Right third | Pass/Fail | |
| Quarter 1 | Pass/Fail | |
| Quarter 2 | Pass/Fail | |
| Quarter 3 | Pass/Fail | |
| Quarter 4 | Pass/Fail | |
| Left two-thirds | Pass/Fail | |
| Right two-thirds | Pass/Fail | |
| 25/50/25 layout | Pass/Fail | |
| Centre half | Pass/Fail | |
| Maximize visible area | Pass/Fail | |
| Samsung monitor selection | Pass/Fail | |
| MacBook display selection | Pass/Fail | |
| Window overlapping monitors | Pass/Fail | |
| Dock left/right/bottom | Pass/Fail | |
| Global shortcuts | Pass/Fail | |
| Minimum-size window | Pass/Fail | |
| Full-screen window handling | Pass/Fail | |
| Minimized window handling | Pass/Fail | |

## Known Limitations

- 

## Conclusion

-
```

---

## 19. Suggested Future Features

Do not implement these until the first release is stable:

- Drag-to-snap zones
- Six-column layouts
- Top and bottom subdivisions within each column
- Custom user-created layouts
- Layout presets per monitor
- Per-application remembered positions
- Window groups
- Restore previous window frame
- Cycle layouts using one shortcut
- Animated window movement
- Sync settings with iCloud
- Automatic detection of ultrawide displays
- Export and import layout profiles

---

## 20. Definition of Success

The project is successful when a user can focus any ordinary resizable macOS window and, using either the menu-bar app or a keyboard shortcut, place it accurately into:

- One of three vertical sections
- One of four vertical sections
- One-third or two-thirds of the monitor
- One of the 25 / 50 / 25 regions

The placement must work reliably on both the Samsung Odyssey ultrawide monitor and the MacBook display without requiring the user to manually calculate coordinates.
