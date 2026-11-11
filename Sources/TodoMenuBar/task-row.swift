import SwiftUI

enum TaskRowLayout {
  static let inset: CGFloat = 12
  static let spacing: CGFloat = 10
  static let handleWidth: CGFloat = 12
  static let leadingSymbolSize: CGFloat = 10
  static let controlSize: CGFloat = 24
  static let completionSymbolSize: CGFloat = 19
  static let completionInset = (controlSize - completionSymbolSize) / 2
}

extension Priority {
  var color: Color {
    switch self {
    case .none: .secondary
    case .low: .blue
    case .medium: .orange
    case .high: .red
    }
  }
}

struct TaskRow: View {
  let task: Todo
  let store: TaskStore
  @State private var draft: String?
  @State private var dropTargeted = false
  @FocusState private var editorFocused: Bool

  var body: some View {
    HStack(alignment: .center, spacing: TaskRowLayout.spacing) {
      Image(systemName: "line.3.horizontal")
        .font(.system(size: TaskRowLayout.leadingSymbolSize, weight: .medium))
        .foregroundStyle(.tertiary)
        .frame(width: TaskRowLayout.handleWidth, height: TaskRowLayout.controlSize)
        .contentShape(Rectangle())
        .onDrag { NSItemProvider(object: task.id.uuidString as NSString) }
        .help("Drag to reorder")
        .accessibilityLabel("Reorder \(task.text)")

      Button {
        store.update(task.id) { $0.isDone.toggle() }
      } label: {
        Image(systemName: task.isDone ? "checkmark.circle" : "circle")
          .font(.system(size: TaskRowLayout.completionSymbolSize, weight: .light))
          .foregroundStyle(.secondary)
          .frame(width: TaskRowLayout.controlSize, height: TaskRowLayout.controlSize)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(task.isDone ? "Mark \(task.text) incomplete" : "Complete \(task.text)")

      if let draft = Binding($draft) {
        TextField("Task", text: draft)
          .textFieldStyle(.plain)
          .focused($editorFocused)
          .onSubmit { commit() }
          .onExitCommand { self.draft = nil }
          .onChange(of: editorFocused) { _, focused in
            if !focused { commit() }
          }
          .onDisappear { commit() }
      } else {
        Button(action: edit) {
          Text(task.text)
            .strikethrough(task.isDone)
            .foregroundStyle(task.isDone ? .secondary : .primary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.plain)
        .help("Edit task")
      }

      Menu {
        Section("Priority") {
          Picker(
            "Priority",
            selection: Binding(
              get: { task.priority },
              set: { priority in store.update(task.id) { $0.priority = priority } }
            )
          ) {
            ForEach(Priority.allCases) { priority in
              Label(priority.title, systemImage: priority == .none ? "minus" : "flag.fill")
                .tag(priority)
            }
          }
          .pickerStyle(.inline)
          .labelsHidden()
        }
      } label: {
        Color.clear.frame(width: TaskRowLayout.controlSize, height: TaskRowLayout.controlSize)
      }
      .menuStyle(.borderlessButton)
      .menuIndicator(.hidden)
      .frame(width: TaskRowLayout.controlSize, height: TaskRowLayout.controlSize)
      .overlay {
        TaskControlIcon(
          systemName: task.priority == .none ? "flag" : "flag.fill",
          color: task.priority == .none ? nil : task.priority.color
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
      }
      .help("Priority: \(task.priority.title)")
      .accessibilityLabel("Priority for \(task.text): \(task.priority.title)")

      Button {
        store.remove(task.id)
      } label: {
        TaskControlIcon(systemName: "trash")
      }
      .buttonStyle(.plain)
      .help("Delete task")
      .accessibilityLabel("Delete \(task.text)")
    }
    .font(.system(size: 13))
    .padding(.vertical, 4.5)
    .padding(.horizontal, TaskRowLayout.inset)
    .contentShape(Rectangle())
    .overlay(alignment: .top) {
      if dropTargeted {
        Rectangle().fill(Color.accentColor).frame(height: 2).padding(.horizontal, 12)
      }
    }
    .contextMenu {
      Button("Edit task", action: edit)
      Button("Move up") { store.move(task.id, by: -1) }
        .disabled(store.currentList?.tasks.first?.id == task.id)
      Button("Move down") { store.move(task.id, by: 1) }
        .disabled(store.currentList?.tasks.last?.id == task.id)
      Divider()
      Button("Delete task", role: .destructive) { store.remove(task.id) }
    }
    .accessibilityAction(named: "Move up") { store.move(task.id, by: -1) }
    .accessibilityAction(named: "Move down") { store.move(task.id, by: 1) }
    .onReceive(NotificationCenter.default.publisher(for: .taskPanelWillClose)) { _ in
      commit()
      editorFocused = false
    }
    .dropDestination(for: String.self) { items, _ in
      guard let value = items.first, let id = UUID(uuidString: value),
        store.currentList?.tasks.contains(where: { $0.id == id }) == true
      else { return false }
      store.move(id, before: task.id)
      return true
    } isTargeted: { targeted in
      dropTargeted = targeted
    }
  }

  private func edit() {
    draft = task.text
    editorFocused = true
  }

  private func commit() {
    guard let draft else { return }
    let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    self.draft = nil
    if !text.isEmpty { store.update(task.id) { $0.text = text } }
  }
}
