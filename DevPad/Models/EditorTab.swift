import Foundation

class EditorTab: Identifiable, ObservableObject {
    let id = UUID()
    @Published var content: String = ""
    @Published var fileURL: URL?
    @Published var isDirty: Bool = false

    private var originalContent: String = ""

    var title: String {
        fileURL?.lastPathComponent ?? "Untitled"
    }

    init(url: URL? = nil) {
        self.fileURL = url
        if let url = url {
            loadFile(url: url)
        }
    }

    func loadFile(url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            content = text
            originalContent = text
            fileURL = url
            isDirty = false
        } catch {
            content = "Error loading file: \(error.localizedDescription)"
        }
    }

    func updateContent(_ newContent: String) {
        content = newContent
        isDirty = content != originalContent
    }

    func save() {
        guard let url = fileURL else { return }
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            originalContent = content
            isDirty = false
        } catch {
            print("Error saving: \(error)")
        }
    }

    func markAsSaved() {
        originalContent = content
        isDirty = false
    }
}
