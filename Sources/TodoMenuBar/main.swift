import AppKit
import Observation
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSPopoverDelegate {
  private let store = TaskStore()
  private let preferences = Preferences()
  private var statusItem: NSStatusItem?
  private let popover = NSPopover()
  private var aboutWindow: NSWindow?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    installMenu()
    let status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem = status
    status.button?.image = NSImage(
      systemSymbolName: "checklist", accessibilityDescription: "Todo Menu Bar")
    status.button?.imagePosition = .imageLeft
    status.button?.target = self
    status.button?.action = #selector(togglePopover)
    status.button?.toolTip = "Todo Menu Bar"

    popover.behavior = .transient
    popover.delegate = self
    popover.contentViewController = NSHostingController(
      rootView: TaskPanelView(
        store: store,
        preferences: preferences,
        showAbout: { [weak self] in
          self?.showAbout()
        }))
    popover.contentSize = TaskPanelView.contentSize
    updateMotionPreference()

    observeCount()

    NSWorkspace.shared.notificationCenter.addObserver(
      self, selector: #selector(updateMotionPreference),
      name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil)
    NSWorkspace.shared.notificationCenter.addObserver(
      self, selector: #selector(deactivated), name: NSWorkspace.activeSpaceDidChangeNotification,
      object: nil)
  }

  private func observeCount() {
    withObservationTracking {
      let count = store.unfinishedCount
      statusItem?.button?.title = preferences.showTaskCount && count > 0 ? " \(count)" : ""
    } onChange: { [weak self] in
      // Observation fires before the write. Read the new count and re-arm on the next run-loop turn.
      DispatchQueue.main.async { self?.observeCount() }
    }
  }

  @objc private func togglePopover() {
    guard let button = statusItem?.button else { return }
    updateMotionPreference()
    if popover.isShown {
      popover.performClose(nil)
      return
    }
    NSApp.activate()
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
  }

  func popoverWillShow(_ notification: Notification) {
    preferences.refresh()
    let view = popover.contentViewController?.view
    view?.window?.initialFirstResponder = view
    view?.window?.makeFirstResponder(nil)
  }

  func popoverDidShow(_ notification: Notification) {
    let window = popover.contentViewController?.view.window
    window?.makeKey()
    window?.makeFirstResponder(nil)
  }

  func popoverDidClose(_ notification: Notification) {
    NotificationCenter.default.post(name: .taskPanelDidClose, object: nil)
  }

  func popoverWillClose(_ notification: Notification) {
    NotificationCenter.default.post(name: .taskPanelWillClose, object: nil)
  }

  @objc private func updateMotionPreference() {
    popover.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
  }

  @objc private func deactivated() { popover.performClose(nil) }

  @objc private func showAbout() {
    popover.performClose(nil)
    if aboutWindow == nil {
      let window = NSWindow(
        contentRect: .zero,
        styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
      window.title = "About Todo Menu Bar"
      let content = NSHostingView(rootView: AboutView())
      window.contentView = content
      window.setContentSize(content.fittingSize)
      window.initialFirstResponder = window.contentView
      window.isReleasedWhenClosed = false
      window.delegate = self
      window.center()
      aboutWindow = window
    }
    NSApp.setActivationPolicy(.regular)
    NSApp.activate()
    if aboutWindow?.isMiniaturized == true { aboutWindow?.deminiaturize(nil) }
    aboutWindow?.makeKeyAndOrderFront(nil)
    aboutWindow?.makeFirstResponder(nil)
  }

  func windowWillClose(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
  }

  @objc private func closeWindow() {
    if popover.isShown, NSApp.keyWindow === popover.contentViewController?.view.window {
      popover.performClose(nil)
    } else {
      NSApp.keyWindow?.performClose(nil)
    }
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool
  {
    if aboutWindow?.isVisible == true || aboutWindow?.isMiniaturized == true {
      showAbout()
    } else if !popover.isShown {
      togglePopover()
    }
    return false
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    NotificationCenter.default.post(name: .taskPanelWillClose, object: nil)
    guard store.errorMessage != nil, !store.isReadOnly else { return .terminateNow }
    let alert = NSAlert()
    alert.messageText = "Some changes have not been saved"
    alert.informativeText =
      "Cancel and use Retry Save to keep your changes, or quit without saving them."
    alert.addButton(withTitle: "Cancel")
    alert.addButton(withTitle: "Quit Without Saving")
    return alert.runModal() == .alertSecondButtonReturn ? .terminateNow : .terminateCancel
  }

  private func installMenu() {
    let main = NSMenu()
    let application = NSMenu()
    let about = NSMenuItem(
      title: "About Todo Menu Bar…", action: #selector(showAbout), keyEquivalent: "")
    about.target = self
    application.addItem(about)
    application.addItem(.separator())
    application.addItem(
      withTitle: "Quit Todo Menu Bar", action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q")
    let appItem = NSMenuItem()
    appItem.submenu = application
    main.addItem(appItem)

    let edit = NSMenu(title: "Edit")
    edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
    let redo = edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
    redo.keyEquivalentModifierMask = [.command, .shift]
    edit.addItem(.separator())
    edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    edit.addItem(
      withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    let editItem = NSMenuItem()
    editItem.submenu = edit
    main.addItem(editItem)

    let windows = NSMenu(title: "Window")
    let close = NSMenuItem(
      title: "Close Window", action: #selector(closeWindow), keyEquivalent: "w")
    close.target = self
    windows.addItem(close)
    let windowItem = NSMenuItem()
    windowItem.submenu = windows
    main.addItem(windowItem)
    NSApp.mainMenu = main
    NSApp.windowsMenu = windows
  }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
