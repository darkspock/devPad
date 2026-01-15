import Foundation
import SwiftUI
import Combine

class MarkdownViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var currentFileURL: URL?
    @Published var isDirty: Bool = false

    private var originalContent: String = ""
    private var autoSaveTimer: AnyCancellable?
    private var pendingSave = false

    func loadFile(url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            content = text
            originalContent = text
            currentFileURL = url
            isDirty = false
        } catch {
            content = "Error loading file: \(error.localizedDescription)"
        }
    }

    func save() {
        guard let url = currentFileURL else { return }
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            originalContent = content
            isDirty = false
        } catch {
            print("Error saving: \(error)")
        }
    }

    func newFile() {
        content = ""
        originalContent = ""
        currentFileURL = nil
        isDirty = false
    }

    func saveAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.text]
        panel.nameFieldStringValue = "untitled.md"

        if panel.runModal() == .OK, let url = panel.url {
            currentFileURL = url
            save()
        }
    }

    func updateContent(_ newContent: String) {
        content = newContent
        isDirty = content != originalContent

        // Schedule autosave if file exists and content changed
        if isDirty && currentFileURL != nil {
            scheduleAutoSave()
        }
    }

    private func scheduleAutoSave() {
        autoSaveTimer?.cancel()
        autoSaveTimer = Just(())
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.autoSave()
            }
    }

    private func autoSave() {
        guard isDirty, currentFileURL != nil else { return }
        save()
    }
}
