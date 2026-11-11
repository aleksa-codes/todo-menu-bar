# Todo Menu Bar

Native macOS 14+ menu-bar task app. Swift 6.2, AppKit, SwiftUI, Observation, and ServiceManagement. No dependencies or Xcode project. Build with Xcode Command Line Tools.
The app target defaults to MainActor isolation. Codable value models are explicitly nonisolated.

- `make check`: compile/typecheck, strict Swift formatter lint, shell syntax, and plist validation.
- `make build`: release build and ad-hoc-signed app in `dist/`.
- `make run`: build, gracefully restart, and open the local app.
- `make package`: ad-hoc-signed DMG and ZIP in `dist/` (host architecture).
- `make icon`: regenerate PNG and ICNS from `scripts/draw-icon.swift`.
- `swift format format --in-place --recursive Sources scripts Package.swift`: format Swift.
- No automated tests are configured. Do not add tests unless requested.

`scripts/build.sh` assembles the app bundle. Do not use `swift run` for login-item or icon checks; these need the bundle.
Let macOS load the static app icon from `CFBundleIconFile`, without a runtime override. Keep the build script's bundle timestamp update; otherwise IconServices can retain stale small-size icons across rebuilds.
Data is in `~/Library/Application Support/codes.aleksa.todo-menu-bar/tasks.json`. Never edit or remove real task data during checks. Login registration changes system settings; do not toggle it during automated verification.
The task view uses a transient `NSPopover` with custom drop destinations, not `List.onMove`. Leave its background clear so AppKit draws the native material. Native popover animation is disabled when Reduce Motion is on. The gear opens a native settings menu; only About opens an app window. About temporarily enables the Dock icon and restores accessory mode on close. Do not focus controls automatically on opening.
Manual verification: `agent_docs/verification.md`.
Interface color and control roles: `agent_docs/interface.md`.
