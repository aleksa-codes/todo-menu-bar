import Foundation
import Observation
import ServiceManagement

@Observable
final class Preferences {
  var showTaskCount: Bool {
    didSet { UserDefaults.standard.set(showTaskCount, forKey: "showTaskCount") }
  }
  private(set) var loginStatus = SMAppService.mainApp.status
  private(set) var loginError: String?

  init() {
    showTaskCount = UserDefaults.standard.object(forKey: "showTaskCount") as? Bool ?? true
  }

  var launchAtLogin: Bool { loginStatus == .enabled || loginStatus == .requiresApproval }

  func refresh() { loginStatus = SMAppService.mainApp.status }

  func setLaunchAtLogin(_ enabled: Bool) {
    do {
      if enabled {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
      loginError = nil
    } catch {
      loginError =
        "Could not change launch at login. Check Login Items in System Settings and try again.\n\n\(error.localizedDescription)"
    }
    refresh()
  }
}
