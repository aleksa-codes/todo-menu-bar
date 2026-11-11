import SwiftUI

struct TaskControlIcon: View {
  let systemName: String
  var color: Color?
  @Environment(\.isEnabled) private var isEnabled

  var body: some View {
    Group {
      if !isEnabled {
        symbol.foregroundStyle(.tertiary)
      } else if let color {
        symbol.symbolRenderingMode(.palette).foregroundStyle(color)
      } else {
        symbol.foregroundStyle(.secondary)
      }
    }
  }

  private var symbol: some View {
    Image(systemName: systemName)
      .font(.system(size: 13))
      .frame(width: TaskRowLayout.controlSize, height: TaskRowLayout.controlSize)
      .contentShape(Rectangle())
  }
}
