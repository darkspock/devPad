import Foundation
import SwiftUI
import SwiftTerm

class TerminalViewModel: ObservableObject {
    @Published var tabs: [TerminalTab] = []
    @Published var selectedTabId: UUID?
    var workingDirectory: String

    var selectedTab: TerminalTab? {
        tabs.first { $0.id == selectedTabId }
    }

    init(directory: String? = nil) {
        self.workingDirectory = directory ?? FileManager.default.homeDirectoryForCurrentUser.path
        addTab()
    }

    func setWorkingDirectory(_ directory: String) {
        self.workingDirectory = directory
    }

    func addTab() {
        let newTab = TerminalTab(title: "Terminal \(tabs.count + 1)", directory: workingDirectory)
        tabs.append(newTab)
        selectedTabId = newTab.id
    }

    func closeTab(_ tab: TerminalTab) {
        guard tabs.count > 1 else { return }

        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs.remove(at: index)

            if selectedTabId == tab.id {
                let newIndex = min(index, tabs.count - 1)
                selectedTabId = tabs[newIndex].id
            }
        }
    }

    func selectTab(_ tab: TerminalTab) {
        selectedTabId = tab.id
    }

    func clear() {
        selectedTab?.terminalView?.send(txt: "\u{0C}")
    }

    func restart() {
        guard let tab = selectedTab, let terminalView = tab.terminalView else { return }

        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        var envArray: [String] = ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }
        envArray.append("TERM=xterm-256color")
        envArray.append("COLORTERM=truecolor")

        let shellName = "-" + (shell as NSString).lastPathComponent
        terminalView.startProcess(executable: shell, args: ["--login"], environment: envArray, execName: shellName)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            terminalView.send(txt: "cd \"\(tab.initialDirectory)\" && clear\n")
        }
        tab.isRunning = true
    }

    func sendInterrupt() {
        selectedTab?.terminalView?.send(txt: "\u{03}")
    }
}
