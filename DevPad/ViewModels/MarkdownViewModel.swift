import Foundation
import SwiftUI

class MarkdownViewModel: ObservableObject {
    @Published var tabs: [EditorTab] = []
    @Published var selectedTabId: UUID?

    private var autoSaveTimers: [UUID: Timer] = [:]
    private let maxTabs = 10

    var currentTab: EditorTab? {
        tabs.first { $0.id == selectedTabId }
    }

    var content: String {
        get { currentTab?.content ?? "" }
        set { currentTab?.content = newValue }
    }

    var currentFileURL: URL? {
        currentTab?.fileURL
    }

    var isDirty: Bool {
        currentTab?.isDirty ?? false
    }

    func openFile(url: URL) {
        // Check if file is already open
        if let existingTab = tabs.first(where: { $0.fileURL == url }) {
            selectedTabId = existingTab.id
            return
        }

        // Check max tabs
        if tabs.count >= maxTabs {
            return
        }

        let tab = EditorTab(url: url)
        tabs.append(tab)
        selectedTabId = tab.id
    }

    func loadFile(url: URL) {
        openFile(url: url)
    }

    func selectTab(_ tab: EditorTab) {
        selectedTabId = tab.id
    }

    func closeTab(_ tab: EditorTab) {
        // Cancel autosave timer
        autoSaveTimers[tab.id]?.invalidate()
        autoSaveTimers.removeValue(forKey: tab.id)

        tabs.removeAll { $0.id == tab.id }

        // Select another tab if needed
        if selectedTabId == tab.id {
            selectedTabId = tabs.last?.id
        }
    }

    func save() {
        currentTab?.save()
    }

    func newFile() {
        if tabs.count >= maxTabs {
            return
        }

        let tab = EditorTab()
        tabs.append(tab)
        selectedTabId = tab.id
    }

    func saveAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.text]
        panel.nameFieldStringValue = currentTab?.title ?? "untitled.md"

        if panel.runModal() == .OK, let url = panel.url {
            currentTab?.fileURL = url
            currentTab?.save()
        }
    }

    func updateContent(_ newContent: String) {
        guard let tab = currentTab else { return }
        tab.updateContent(newContent)
        objectWillChange.send()

        // Schedule autosave if file exists and content changed
        if tab.isDirty && tab.fileURL != nil {
            scheduleAutoSave(for: tab)
        }
    }

    private func scheduleAutoSave(for tab: EditorTab) {
        autoSaveTimers[tab.id]?.invalidate()
        autoSaveTimers[tab.id] = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self, weak tab] _ in
            DispatchQueue.main.async {
                guard let tab = tab, tab.isDirty, tab.fileURL != nil else { return }
                tab.save()
                self?.objectWillChange.send()
            }
        }
    }
}
