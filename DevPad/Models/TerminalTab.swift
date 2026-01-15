import Foundation
import SwiftTerm

class TerminalTab: Identifiable, ObservableObject {
    let id = UUID()
    @Published var title: String
    @Published var isRunning: Bool = true
    weak var terminalView: LocalProcessTerminalView?
    var initialDirectory: String

    init(title: String = "Terminal", directory: String? = nil) {
        self.title = title
        self.initialDirectory = directory ?? FileManager.default.homeDirectoryForCurrentUser.path
    }
}
