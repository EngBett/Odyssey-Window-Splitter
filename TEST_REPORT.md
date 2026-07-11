# Odyssey Window Splitter Test Report

## Environment

- Mac: (fill in — e.g. MacBook Pro 14" M-series)
- macOS: 15.6.1 (24G90)
- Xcode: 16.2 (16C5032a)
- Samsung monitor: (fill in — Odyssey model)
- Resolution: (fill in)
- Scaling: (fill in)
- Display arrangement: (fill in)
- Dock position: (fill in)

## Automated Tests

Command:

```bash
xcodebuild \
  -project OdysseyWindowSplitter.xcodeproj \
  -scheme OdysseyWindowSplitter \
  -destination 'platform=macOS' \
  test
```

Result (2026-07-11):

- Tests executed: 23
- Tests passed: 23
- Tests failed: 0

Suites: `LayoutCalculatorTests` (11), `CoordinateConverterTests` (5),
`ScreenSelectionTests` (7). Coverage includes the spec's §9.1–§9.7 cases:
exact thirds/quarters, two-thirds, 25/50/25 coverage, gap spacing and
non-negative sizes, negative screen origins, and rounding of indivisible
widths (5120 ÷ 3).

A launch smoke test was also performed: the Debug build starts, runs as a
menu-bar (LSUIElement) process, and does not crash without Accessibility
permission.

## Manual Tests

To be completed on the Samsung Odyssey hardware.

| Test | Result | Notes |
|---|---|---|
| Accessibility permission flow | Pending | |
| Left third | Pending | |
| Centre third | Pending | |
| Right third | Pending | |
| Quarter 1 | Pending | |
| Quarter 2 | Pending | |
| Quarter 3 | Pending | |
| Quarter 4 | Pending | |
| Left two-thirds | Pending | |
| Right two-thirds | Pending | |
| 25/50/25 layout | Pending | |
| Centre half | Pending | |
| Maximize visible area | Pending | |
| Samsung monitor selection | Pending | |
| MacBook display selection | Pending | |
| Window overlapping monitors | Pending | |
| Dock left/right/bottom | Pending | |
| Global shortcuts | Pending | |
| Minimum-size window | Pending | |
| Full-screen window handling | Pending | |
| Minimized window handling | Pending | |

Applications to test: Finder, Safari, Google Chrome, Visual Studio Code,
Xcode, Terminal, Notes, Slack (or another Electron app).

## Known Limitations

- Accessibility permission must be re-granted after rebuilding, because the
  ad-hoc signature changes with each build.
- Full-screen windows are refused with an explanatory message rather than
  resized.
- Applications with minimum sizes larger than the target region keep their
  minimum size; the app reports that the frame was adjusted.

## Conclusion

- All automated layout, coordinate-conversion, and screen-selection tests pass.
  Manual verification on the Samsung Odyssey monitor is pending.
