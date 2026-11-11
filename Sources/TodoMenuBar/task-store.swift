import Foundation
import Observation

nonisolated enum Priority: String, Codable, CaseIterable, Identifiable {
  case none, low, medium, high

  var id: Self { self }
  var title: String { rawValue.capitalized }
}

nonisolated struct Todo: Codable, Identifiable, Equatable {
  let id: UUID
  var text: String
  var isDone = false
  var priority: Priority = .none
}

nonisolated struct TaskList: Codable, Identifiable, Equatable {
  let id: UUID
  var name: String
  var tasks: [Todo] = []
}

nonisolated private struct SavedState: Codable {
  let version: Int
  var lists: [TaskList]
  var selectedListID: UUID
}

@Observable
final class TaskStore {
  private(set) var lists: [TaskList] = []
  private(set) var selectedListID: UUID?
  private(set) var errorMessage: String?
  private(set) var isReadOnly = false
  private let fileURL: URL

  var currentList: TaskList? { lists.first { $0.id == selectedListID } }
  var unfinishedCount: Int {
    lists.reduce(0) { count, list in
      count + list.tasks.count(where: { !$0.isDone })
    }
  }

  init(
    fileURL: URL = URL.applicationSupportDirectory
      .appending(path: "codes.aleksa.todo-menu-bar/tasks.json")
  ) {
    self.fileURL = fileURL
    do {
      if FileManager.default.fileExists(atPath: fileURL.path) {
        let saved = try JSONDecoder().decode(SavedState.self, from: Data(contentsOf: fileURL))
        let tasks = saved.lists.flatMap(\.tasks)
        guard saved.version == 1, !saved.lists.isEmpty,
          Set(saved.lists.map(\.id)).count == saved.lists.count,
          Set(tasks.map(\.id)).count == tasks.count
        else { throw CocoaError(.fileReadCorruptFile) }
        lists = saved.lists
        selectedListID =
          lists.contains { $0.id == saved.selectedListID }
          ? saved.selectedListID : lists.first?.id
      } else {
        let list = TaskList(id: UUID(), name: "Tasks")
        lists = [list]
        selectedListID = list.id
      }
    } catch {
      isReadOnly = true
      errorMessage =
        "Could not open tasks. Your file has not been changed. Check \(fileURL.path), then reopen the app.\n\n\(error.localizedDescription)"
    }
  }

  func select(_ id: UUID) {
    guard !isReadOnly, id != selectedListID, lists.contains(where: { $0.id == id }) else { return }
    selectedListID = id
    save()
  }

  func addList(_ name: String) {
    let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !isReadOnly, !name.isEmpty else { return }
    let list = TaskList(id: UUID(), name: name)
    lists.append(list)
    selectedListID = list.id
    save()
  }

  func renameList(_ name: String) {
    let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !isReadOnly, !name.isEmpty, let index = currentIndex else { return }
    lists[index].name = name
    save()
  }

  func deleteList() {
    guard !isReadOnly, lists.count > 1, let index = currentIndex else { return }
    lists.remove(at: index)
    selectedListID = lists[min(index, lists.count - 1)].id
    save()
  }

  @discardableResult
  func add(_ text: String) -> Bool {
    let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !isReadOnly, !text.isEmpty, let index = currentIndex else { return false }
    lists[index].tasks.append(Todo(id: UUID(), text: text))
    save()
    return true
  }

  func update(_ id: UUID, _ change: (inout Todo) -> Void) {
    guard !isReadOnly,
      let list = lists.firstIndex(where: { $0.tasks.contains(where: { $0.id == id }) }),
      let task = lists[list].tasks.firstIndex(where: { $0.id == id })
    else { return }
    change(&lists[list].tasks[task])
    save()
  }

  func remove(_ id: UUID) {
    guard !isReadOnly, let index = currentIndex else { return }
    lists[index].tasks.removeAll { $0.id == id }
    save()
  }

  func clear(completedOnly: Bool) {
    guard !isReadOnly, let index = currentIndex else { return }
    lists[index].tasks.removeAll { !completedOnly || $0.isDone }
    save()
  }

  func move(_ id: UUID, before target: UUID) {
    guard !isReadOnly, id != target, let index = currentIndex,
      let source = lists[index].tasks.firstIndex(where: { $0.id == id }),
      let destination = lists[index].tasks.firstIndex(where: { $0.id == target })
    else { return }
    let task = lists[index].tasks.remove(at: source)
    lists[index].tasks.insert(task, at: source < destination ? destination - 1 : destination)
    save()
  }

  func moveToEnd(_ id: UUID) {
    guard !isReadOnly, let index = currentIndex,
      let source = lists[index].tasks.firstIndex(where: { $0.id == id })
    else { return }
    let task = lists[index].tasks.remove(at: source)
    lists[index].tasks.append(task)
    save()
  }

  func move(_ id: UUID, by offset: Int) {
    guard !isReadOnly, let index = currentIndex,
      let source = lists[index].tasks.firstIndex(where: { $0.id == id }),
      lists[index].tasks.indices.contains(source + offset)
    else { return }
    lists[index].tasks.swapAt(source, source + offset)
    save()
  }

  func save() {
    guard !isReadOnly, let selectedListID else { return }
    do {
      try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(
        SavedState(version: 1, lists: lists, selectedListID: selectedListID))
      try data.write(to: fileURL, options: .atomic)
      errorMessage = nil
    } catch {
      errorMessage =
        "Changes are only in memory. Check available disk space and permissions, then choose Retry Save before quitting.\n\n\(error.localizedDescription)"
    }
  }

  private var currentIndex: Int? { lists.firstIndex { $0.id == selectedListID } }
}
