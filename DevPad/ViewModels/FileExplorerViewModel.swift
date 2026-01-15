import Foundation
import SwiftUI

class FileExplorerViewModel: ObservableObject {
    @Published var rootItems: [FileItem] = []
    @Published var selectedFile: FileItem?
    @Published var currentDirectory: URL
    @Published var expandedItems: Set<UUID> = []

    init(initialDirectory: String? = nil) {
        if let dir = initialDirectory {
            self.currentDirectory = URL(fileURLWithPath: dir)
        } else {
            self.currentDirectory = FileManager.default.homeDirectoryForCurrentUser
        }
        loadDirectory()
    }

    func loadDirectory() {
        rootItems = FileItem.loadDirectory(at: currentDirectory)
    }

    func loadDirectory(at url: URL) {
        currentDirectory = url
        loadDirectory()
    }

    func loadChildren(for item: FileItem) -> [FileItem] {
        guard item.isDirectory else { return [] }
        return FileItem.loadDirectory(at: item.url)
    }

    func toggleExpanded(_ item: FileItem) {
        if expandedItems.contains(item.id) {
            expandedItems.remove(item.id)
        } else {
            expandedItems.insert(item.id)
        }
    }

    func isExpanded(_ item: FileItem) -> Bool {
        expandedItems.contains(item.id)
    }

    func selectItem(_ item: FileItem) {
        if item.isDirectory {
            toggleExpanded(item)
        } else {
            selectedFile = item
        }
    }

    func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            loadDirectory(at: url)
        }
    }

    func goUp() {
        let parent = currentDirectory.deletingLastPathComponent()
        loadDirectory(at: parent)
    }

    func createFile(named name: String, in directory: URL? = nil) {
        let dir = directory ?? currentDirectory
        let fileURL = dir.appendingPathComponent(name)

        // Create empty file
        FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)

        // Reload directory
        loadDirectory()
    }

    func createFolder(named name: String, in directory: URL? = nil) {
        let dir = directory ?? currentDirectory
        let folderURL = dir.appendingPathComponent(name)

        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        // Reload directory
        loadDirectory()
    }

    func deleteItem(_ item: FileItem) {
        try? FileManager.default.removeItem(at: item.url)
        loadDirectory()
    }

    func renameItem(_ item: FileItem, to newName: String) {
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(newName)
        try? FileManager.default.moveItem(at: item.url, to: newURL)
        loadDirectory()
    }
}
