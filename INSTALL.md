# Odyssey Window Splitter — Install Guide

Odyssey Window Splitter is a small menu-bar app that snaps the window you are
working in into a region of your screen: thirds, quarters, halves, 25/50/25, or
full screen. It was built for a 49-inch Samsung Odyssey ultrawide, and works on
any display — including your MacBook's built-in screen.

Requires macOS 14 (Sonoma) or later. Works on Apple Silicon and Intel Macs.

---

## 1. Install the app

1. Open `OdysseyWindowSplitter-1.0.dmg`.
2. Drag **OdysseyWindowSplitter** onto the **Applications** folder shortcut.
3. Eject the disk image.

## 2. Let macOS open it

This app is signed by the person who built it, not by Apple, because Apple
charges an annual fee to developers for that. macOS therefore blocks it the
first time with a message like *"Apple could not verify OdysseyWindowSplitter
is free of malware."*

The quickest fix — open **Terminal** (Spotlight: `Cmd+Space`, type "Terminal")
and paste this line, then press Return:

    xattr -dr com.apple.quarantine /Applications/OdysseyWindowSplitter.app

That removes the download flag macOS attaches to files from the internet, and
the app will open normally from then on. It changes nothing else on your Mac.

If you would rather not use Terminal, you can do it through the interface
instead:

1. Double-click the app in Applications. macOS refuses to open it — click
   **Done**.
2. Open **System Settings → Privacy & Security**.
3. Scroll to the bottom. There is a line about OdysseyWindowSplitter being
   blocked, with an **Open Anyway** button. Click it.
4. Confirm, and authenticate with Touch ID or your password.

## 3. Grant Accessibility permission

To move windows that belong to other apps, macOS requires one permission. There
is no way around this — it is the same permission Rectangle, Magnet, and every
other window manager needs.

1. Open the app. **There is no Dock icon and no window** — look for a small
   split-rectangle icon in the menu bar at the top right of your screen.
2. Click that icon and choose **Request Accessibility Permission**.
3. macOS opens **System Settings → Privacy & Security → Accessibility**. Switch
   **OdysseyWindowSplitter** on.
4. If layouts still do not work, quit the app from its menu and open it again.

## 4. Use it

Click the menu-bar icon and pick a layout. It applies to whichever window you
were last working in, on the display that window is currently on — so the same
menu item does the right thing on the Odyssey and on the MacBook screen.

Or use the keyboard, holding **Control + Option**:

| Shortcut | Layout |
| --- | --- |
| `⌃⌥1` `⌃⌥2` `⌃⌥3` | Left / centre / right third |
| `⌃⌥4` … `⌃⌥7` | Quarters 1–4, left to right |
| `⌃⌥←` `⌃⌥→` | Left / right half |
| `⌃⌥↑` | Maximize |

**Settings** (from the menu-bar icon) lets you change the gap between windows
and screen edges, start the app automatically at login, and turn the global
shortcuts off if they collide with another app.

---

## If something goes wrong

**The menu-bar icon is missing.** With a lot of menu-bar items macOS hides the
overflow, and on a wide display the notch can swallow them. Quit some other
menu-bar apps, or use a menu-bar manager, to check whether it is simply hidden.

**Layouts do nothing.** Accessibility permission is either off or stale. Open
System Settings → Privacy & Security → Accessibility, switch
OdysseyWindowSplitter off and on again, then quit and reopen the app. A stale
entry after an app update is the usual cause.

**A window will not resize all the way.** Some apps declare a minimum window
size larger than the region you picked. The app resizes it as far as that app
permits and tells you the frame was adjusted.

**A full-screen window will not move.** Windows in macOS's native full-screen or
Split View mode cannot be repositioned by any app. Leave full screen first.

**A shortcut does nothing.** Another app has claimed it. Open Settings from the
menu-bar icon — conflicting registrations are listed there — and either quit the
other app or switch the global shortcuts off.
