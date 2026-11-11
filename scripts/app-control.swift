import AppKit

guard CommandLine.arguments.count == 3,
  ["check", "stop"].contains(CommandLine.arguments[1])
else {
  fputs("Usage: app-control.swift check|stop /path/to/app\n", stderr)
  exit(1)
}
let command = CommandLine.arguments[1]
let path = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
  .resolvingSymlinksInPath()
let apps = NSRunningApplication.runningApplications(
  withBundleIdentifier: "codes.aleksa.todo-menu-bar"
)
.filter { $0.bundleURL?.standardizedFileURL.resolvingSymlinksInPath() == path }
if command == "check", !apps.isEmpty {
  fputs("This app is running. Use make run to quit, rebuild, and reopen it safely.\n", stderr)
  exit(1)
}
if command == "stop" {
  for app in apps {
    guard app.terminate() else {
      fputs("Could not quit the development app. Build cancelled.\n", stderr)
      exit(1)
    }
  }
  let deadline = Date(timeIntervalSinceNow: 10)
  while apps.contains(where: { !$0.isTerminated }), Date() < deadline {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
  }
  guard apps.allSatisfy(\.isTerminated) else {
    fputs("The app is still running. Resolve any save warning before rebuilding.\n", stderr)
    exit(1)
  }
}
