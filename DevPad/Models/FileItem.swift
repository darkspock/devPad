import Foundation
import UniformTypeIdentifiers

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let isDirectory: Bool
    var children: [FileItem]?

    var name: String {
        url.lastPathComponent
    }

    var icon: String {
        if isDirectory {
            return "folder.fill"
        }

        let ext = url.pathExtension.lowercased()
        switch ext {
        case "md", "markdown":
            return "doc.text"
        case "swift":
            return "swift"
        case "js", "ts":
            return "curlybraces"
        case "json":
            return "curlybraces.square"
        case "html", "htm":
            return "globe"
        case "css":
            return "paintbrush"
        case "py":
            return "chevron.left.forwardslash.chevron.right"
        case "txt":
            return "doc.plaintext"
        case "png", "jpg", "jpeg", "gif", "svg":
            return "photo"
        case "pdf":
            return "doc.fill"
        default:
            return "doc"
        }
    }

    static func loadDirectory(at url: URL) -> [FileItem] {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents.compactMap { itemURL in
            let isDirectory = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            return FileItem(
                url: itemURL,
                isDirectory: isDirectory,
                children: isDirectory ? [] : nil
            )
        }.sorted { item1, item2 in
            if item1.isDirectory != item2.isDirectory {
                return item1.isDirectory
            }
            return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
        }
    }
}
