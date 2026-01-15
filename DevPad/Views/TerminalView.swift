import SwiftUI
import AppKit
import SwiftTerm

struct TerminalPanelView: View {
    @ObservedObject var viewModel: TerminalViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(viewModel.tabs) { tab in
                            TerminalTabButton(
                                tab: tab,
                                isSelected: viewModel.selectedTabId == tab.id,
                                onSelect: { viewModel.selectTab(tab) },
                                onClose: { viewModel.closeTab(tab) },
                                canClose: viewModel.tabs.count > 1
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }

                Spacer()

                // Add tab button
                Button(action: viewModel.addTab) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 8)
                .help("New terminal tab")

                Divider()
                    .frame(height: 16)

                // Toolbar buttons
                Button(action: viewModel.sendInterrupt) {
                    Text("Ctrl+C")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Send interrupt signal")

                Button(action: viewModel.clear) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Clear terminal")

                Button(action: viewModel.restart) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Restart session")
                .padding(.trailing, 8)
            }
            .frame(height: 32)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Terminal content - use ZStack to keep terminals alive
            ZStack {
                ForEach(viewModel.tabs) { tab in
                    SwiftTermTabView(tab: tab)
                        .opacity(viewModel.selectedTabId == tab.id ? 1 : 0)
                        .allowsHitTesting(viewModel.selectedTabId == tab.id)
                }
            }
        }
    }
}

struct TerminalTabButton: View {
    @ObservedObject var tab: TerminalTab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let canClose: Bool

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tab.isRunning ? Color.green : Color.red)
                .frame(width: 6, height: 6)

            Text(tab.title)
                .font(.system(size: 11))
                .lineLimit(1)

            if canClose && (isSelected || isHovering) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .frame(width: 14, height: 14)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.2) : (isHovering ? Color.gray.opacity(0.1) : Color.clear))
        .cornerRadius(4)
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct SwiftTermTabView: NSViewRepresentable {
    @ObservedObject var tab: TerminalTab

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminalView = LocalProcessTerminalView(frame: .zero)

        // Configure appearance
        terminalView.configureNativeColors()
        terminalView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

        // Store reference
        DispatchQueue.main.async {
            tab.terminalView = terminalView
        }

        // Setup delegate
        terminalView.processDelegate = context.coordinator

        // Start shell
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        var envArray: [String] = ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }
        envArray.append("TERM=xterm-256color")
        envArray.append("COLORTERM=truecolor")

        let shellName = "-" + (shell as NSString).lastPathComponent
        terminalView.startProcess(executable: shell, args: ["--login"], environment: envArray, execName: shellName)

        // Change to tab's initial directory
        let initialDir = tab.initialDirectory
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            terminalView.send(txt: "cd \"\(initialDir)\" && clear\n")
        }

        return terminalView
    }

    func updateNSView(_ terminalView: LocalProcessTerminalView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(tab: tab)
    }

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var tab: TerminalTab

        init(tab: TerminalTab) {
            self.tab = tab
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            DispatchQueue.main.async {
                if !title.isEmpty {
                    self.tab.title = title
                }
            }
        }

        func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {}

        func processTerminated(source: SwiftTerm.TerminalView, exitCode: Int32?) {
            DispatchQueue.main.async {
                self.tab.isRunning = false
            }
        }
    }
}

#Preview {
    TerminalPanelView(viewModel: TerminalViewModel())
}
