import AppKit
import SwiftUI

struct AboutView: View {
  var body: some View {
    VStack(spacing: 12) {
      Image(nsImage: NSApp.applicationIconImage)
        .renderingMode(.original)
        .resizable()
        .frame(width: 80, height: 80)
        .accessibilityHidden(true)
      Text("Todo Menu Bar").font(.title2.weight(.semibold))
      Text(
        "Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")"
      )
      .font(.caption)
      .foregroundStyle(.secondary)
      Text("Tasks stay on this Mac.\nNo account or sync.")
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      Link("Made by aleksa.codes", destination: URL(string: "https://aleksa.codes")!)
    }
    .padding(28)
    .frame(width: 320)
    .fixedSize(horizontal: false, vertical: true)
  }
}
