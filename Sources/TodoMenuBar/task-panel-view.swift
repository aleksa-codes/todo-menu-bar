import ServiceManagement
import SwiftUI

struct TaskPanelView: View {
  static let contentSize = CGSize(width: 384, height: 380)

  let store: TaskStore
  @Bindable var preferences: Preferences
  let showAbout: () -> Void
  @State private var newTask = ""
  @State private var listName = ""
  @State private var listEditor = false
  @State private var renamingList = false
  @State private var confirmation: ClearAction?
  @FocusState private var addFocused: Bool

  private enum ClearAction {
    case completed, all, list
    func title(listName: String) -> String {
      switch self {
      case .completed: "Clear completed tasks in “\(listName)”?"
      case .all: "Clear all tasks in “\(listName)”?"
      case .list: "Delete “\(listName)” and its tasks?"
      }
    }
    var button: String {
      switch self {
      case .completed: "Clear completed"
      case .all: "Clear all"
      case .list: "Delete list"
      }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: TaskRowLayout.spacing) {
        Menu {
          Picker(
            "Lists",
            selection: Binding(
              get: { store.selectedListID },
              set: { id in if let id { store.select(id) } }
            )
          ) {
            ForEach(store.lists) { list in
              Text(list.name).tag(Optional(list.id))
            }
          }
          .pickerStyle(.inline)
          .labelsHidden()
          Divider()
          Button {
            openListEditor(renaming: false)
          } label: {
            Label("New list…", systemImage: "plus")
          }
          Button("Rename selected list…") { openListEditor(renaming: true) }
          Button("Delete selected list…", role: .destructive) { confirmation = .list }
            .disabled(store.lists.count < 2)
        } label: {
          Color.clear.frame(height: TaskRowLayout.controlSize)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(maxWidth: .infinity, alignment: .leading)
        // AppKit compacts menu labels, so draw these columns outside its native label layout.
        .overlay(alignment: .leading) {
          HStack(spacing: TaskRowLayout.spacing) {
            Image(systemName: "chevron.down")
              .font(.system(size: TaskRowLayout.leadingSymbolSize, weight: .semibold))
              .foregroundStyle(.secondary)
              .frame(width: TaskRowLayout.handleWidth, height: TaskRowLayout.controlSize)
            Text(store.currentList?.name ?? "Tasks")
              .font(.system(size: 14, weight: .semibold))
              .lineLimit(1)
              .padding(.leading, TaskRowLayout.completionInset)
            Spacer(minLength: 0)
          }
          .allowsHitTesting(false)
          .accessibilityHidden(true)
        }
        .accessibilityLabel("Choose list")
        .accessibilityValue(store.currentList?.name ?? "No list")
        .help("Switch or manage lists")
        .disabled(store.isReadOnly)
        Menu {
          Button("Clear completed…") { confirmation = .completed }
            .disabled(store.currentList?.tasks.contains(where: \.isDone) != true)
          Button("Clear all…", role: .destructive) { confirmation = .all }
            .disabled(store.currentList?.tasks.isEmpty != false)
        } label: {
          Color.clear.frame(width: TaskRowLayout.controlSize, height: TaskRowLayout.controlSize)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: TaskRowLayout.controlSize, height: TaskRowLayout.controlSize)
        .overlay {
          TaskControlIcon(systemName: "ellipsis.circle")
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .help("List actions")
        .accessibilityLabel("List actions")
        Menu {
          Toggle(
            "Launch at login",
            isOn: Binding(
              get: { preferences.launchAtLogin },
              set: { preferences.setLaunchAtLogin($0) }
            ))
          Toggle("Show task count", isOn: $preferences.showTaskCount)
          if preferences.loginStatus == .requiresApproval {
            Text("Launch at login needs approval")
          }
          if preferences.loginError != nil {
            Text("Could not change launch at login")
          }
          if preferences.loginStatus == .requiresApproval || preferences.loginError != nil {
            Button("Open Login Items…") { SMAppService.openSystemSettingsLoginItems() }
          }
          Divider()
          Button("About Todo Menu Bar…", action: showAbout)
          Button("Quit Todo Menu Bar") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
        } label: {
          Color.clear.frame(width: TaskRowLayout.controlSize, height: TaskRowLayout.controlSize)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: TaskRowLayout.controlSize, height: TaskRowLayout.controlSize)
        .overlay {
          TaskControlIcon(systemName: "gearshape")
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .help("Settings")
        .accessibilityLabel("Settings")
      }
      .padding(.horizontal, TaskRowLayout.inset)
      .padding(.vertical, 12)

      Divider()
      ScrollView {
        if let list = store.currentList, !list.tasks.isEmpty {
          LazyVStack(spacing: 0) {
            ForEach(list.tasks) { task in
              TaskRow(task: task, store: store)
            }
            Color.clear.frame(height: 6)
              .contentShape(Rectangle())
              .dropDestination(for: String.self) { values, _ in
                guard let value = values.first, let id = UUID(uuidString: value),
                  list.tasks.contains(where: { $0.id == id })
                else { return false }
                store.moveToEnd(id)
                return true
              }
          }
          .padding(.vertical, 2)
        } else {
          VStack(spacing: 10) {
            Image(systemName: "checklist")
              .font(.system(size: 28, weight: .light))
              .foregroundStyle(.tertiary)
              .accessibilityHidden(true)
            Text(store.isReadOnly ? "Tasks could not be opened" : "No tasks yet")
              .foregroundStyle(.secondary)
            if !store.isReadOnly {
              Text("Add a task below.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
          }
          .frame(maxWidth: .infinity)
          .containerRelativeFrame(.vertical)
        }
      }
      .frame(maxHeight: .infinity)
      .scrollBounceBehavior(.basedOnSize)

      if let error = store.errorMessage {
        VStack(alignment: .leading, spacing: 6) {
          Text(error).font(.caption).textSelection(.enabled)
          if !store.isReadOnly { Button("Retry Save") { store.save() } }
        }
        .foregroundStyle(.red)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
      }

      Divider()
      HStack(spacing: TaskRowLayout.spacing) {
        Image(systemName: "plus")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.secondary)
          .frame(width: TaskRowLayout.handleWidth, height: TaskRowLayout.controlSize)
          .accessibilityHidden(true)
        TextField("Add a task…", text: $newTask)
          .textFieldStyle(.plain)
          .font(.system(size: 13))
          .padding(.leading, TaskRowLayout.completionInset)
          .focused($addFocused)
          .onSubmit(addTask)
          .accessibilityLabel("New task")
        Button(action: addTask) {
          TaskControlIcon(systemName: "return")
        }
        .buttonStyle(.plain)
        .disabled(newTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .help("Add task")
        .accessibilityLabel("Add task")
      }
      .padding(.horizontal, TaskRowLayout.inset)
      .padding(.vertical, 12)
      .disabled(store.isReadOnly)
      if let error = preferences.loginError {
        Text(error)
          .font(.caption)
          .foregroundStyle(.red)
          .textSelection(.enabled)
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .frame(width: Self.contentSize.width, height: Self.contentSize.height)
    .onReceive(NotificationCenter.default.publisher(for: .taskPanelDidClose)) { _ in
      addFocused = false
    }
    .alert(
      renamingList ? "Rename “\(store.currentList?.name ?? "Tasks")”" : "New list",
      isPresented: $listEditor
    ) {
      TextField("List name", text: $listName)
      Button("Cancel", role: .cancel) {}
      Button(renamingList ? "Rename" : "Create") {
        if renamingList { store.renameList(listName) } else { store.addList(listName) }
      }
      .disabled(listName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    } message: {
      Text(renamingList ? "Choose a new name for this list." : "Give your new list a name.")
    }
    .confirmationDialog(
      confirmation?.title(listName: store.currentList?.name ?? "Tasks") ?? "",
      isPresented: Binding(
        get: { confirmation != nil },
        set: { if !$0 { confirmation = nil } }
      ), titleVisibility: .visible
    ) {
      if let action = confirmation {
        Button(action.button, role: .destructive) {
          switch action {
          case .completed: store.clear(completedOnly: true)
          case .all: store.clear(completedOnly: false)
          case .list: store.deleteList()
          }
          confirmation = nil
        }
      }
      Button("Cancel", role: .cancel) { confirmation = nil }
    } message: {
      Text(
        confirmation == .list
          ? "This list and all its tasks will be permanently deleted." : "This cannot be undone.")
    }
  }

  private func addTask() {
    if store.add(newTask) { newTask = "" }
    addFocused = true
  }

  private func openListEditor(renaming: Bool) {
    renamingList = renaming
    listName = renaming ? store.currentList?.name ?? "" : ""
    listEditor = true
  }
}

extension Notification.Name {
  static let taskPanelWillClose = Notification.Name("taskPanelWillClose")
  static let taskPanelDidClose = Notification.Name("taskPanelDidClose")
}
