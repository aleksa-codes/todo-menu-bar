# Manual verification

Use `make run` to open the local app. Do not modify an installed app, register login items, or use real tasks for checks without permission.

- Add several tasks, including a long wrapping task and non-Latin text. Edit, cancel with Escape, and commit by moving focus. Whitespace-only tasks must not be created.
- Drag up and down, drop below the last task, cancel a drag with Escape, and drag outside the panel. After each, add a task and dismiss by clicking outside. Reopen and repeat. Use the context menu and VoiceOver move actions as drag alternatives.
- Verify the popover arrow stays anchored to the menu-bar icon. With Reduce Motion off, check the native opening and closing transition. With it on, check that there is no transition. Change the preference while the app is running and repeat without restarting. Do not change system accessibility settings without permission.
- Open and reopen both the popover and About. No field or control should receive initial focus or flash a focus ring. Clicking a field and Tab navigation must still work. Compare the native popover material over light and dark backgrounds; respect Reduce Transparency and increased contrast without changing either preference during automated checks.
- The gear must open a native menu with launch at login and task-count checkmarks, About, and Quit. Only About opens an app window. Verify task-count updates immediately and persists on relaunch. With explicit permission, verify login approval/error guidance and the Open Login Items action.
- Create, rename, and switch lists. Verify each preserves its own order, completions, and priorities. The menu-bar count covers unfinished tasks across all lists.
- The list menu must show a native selection checkmark beside exactly the current list, including after switching, creating, renaming, deleting, and reopening the app. Management actions must remain separate from list choices. Check empty lists and scrolling with many tasks in the compact popover; the add field must stay visible.
- Set every priority. Priority must be named in the menu and accessibility label, not just represented by color.
- Cancel and confirm clear completed, clear all, and list deletion. Dialog titles must identify the affected list by name. The last list cannot be deleted. Completed clearing must preserve unfinished tasks.
- Check the trash button beside each flag, including Tab focus and its VoiceOver label. Trash and context-menu deletion must remove only that task immediately, without confirmation. The list menu must say “Rename selected list…” and “Delete selected list…”, with the affected list named in the dialogs.
- Quit and reopen to check persistence. Check save errors with isolated data only, never by changing the real task file or directory permissions.
- Edit a task and dismiss the popover or quit without pressing Return. Reopen and verify the edit was saved. A failed save must still block quitting unless explicitly discarded.
- Open About from the gear menu. Check the Dock and Command-Tab icon. Command-W must close About and leave the menu-bar app running. Reopen via the Dock while About is minimized.
- Compare the icon's visual size with Chrome and Ghostty in the Dock and Command-Tab. The icon artwork uses an 824-pixel body on its 1024-pixel canvas, leaving native-style transparent margins.
- Check this comparison with About open after a fresh launch. The running app must use its bundle icon without a runtime `applicationIconImage` override; matching source image dimensions alone is not enough to verify displayed size.
- If an old icon size persists after rebuilding, compare `NSRunningApplication.icon` rendered at 128, 256, and 512 pixels with the bundled ICNS. IconServices can cache small representations separately. Ensure the rebuilt bundle has a current modification timestamp before considering any cache reset.
- Check light and dark appearances, keyboard focus and Tab navigation, VoiceOver labels, empty lists, many tasks, and panel placement on a second display and full-screen Space.
- With explicit permission, install a stable bundle in Applications and check launch at login, including the requires-approval state. Restore the original login setting afterward.

No automatic GUI tests or login-item checks are configured.
