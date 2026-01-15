import SwiftUI

struct ContentView: View {
    @StateObject private var fileExplorerVM: FileExplorerViewModel
    @StateObject private var terminalVM: TerminalViewModel
    @StateObject private var markdownVM = MarkdownViewModel()

    init(initialDirectory: String? = nil) {
        let dir = initialDirectory ?? FileManager.default.homeDirectoryForCurrentUser.path
        let explorerVM = FileExplorerViewModel(initialDirectory: dir)
        _fileExplorerVM = StateObject(wrappedValue: explorerVM)
        _terminalVM = StateObject(wrappedValue: TerminalViewModel(directory: dir))
    }

    var body: some View {
        VSplitView {
            // Top: Explorer + Markdown Editor
            HSplitView {
                // Left: File Explorer
                FileExplorerView(viewModel: fileExplorerVM)
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 400)

                // Right: Markdown Editor
                MarkdownContainerView(viewModel: markdownVM)
                    .frame(minWidth: 300)
            }
            .frame(minHeight: 200)

            // Bottom: Terminal
            TerminalPanelView(viewModel: terminalVM)
                .frame(minHeight: 150)
        }
        .onChange(of: fileExplorerVM.selectedFile) { _, newFile in
            if let file = newFile, file.url.pathExtension == "md" {
                markdownVM.loadFile(url: file.url)
            }
        }
        .onChange(of: fileExplorerVM.currentDirectory) { _, newDir in
            terminalVM.setWorkingDirectory(newDir.path)
        }
    }
}

struct MarkdownContainerView: View {
    @ObservedObject var viewModel: MarkdownViewModel
    @State private var showPreview = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                if let url = viewModel.currentFileURL {
                    Text(url.lastPathComponent)
                        .font(.headline)
                } else {
                    Text("No file open")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 0) {
                    Button(action: { showPreview = false }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .frame(width: 28, height: 22)
                    }
                    .buttonStyle(.plain)
                    .background(showPreview ? Color.clear : Color.accentColor)
                    .foregroundColor(showPreview ? .secondary : .white)
                    .help("Edit")

                    Button(action: { showPreview = true }) {
                        Image(systemName: "eye")
                            .font(.system(size: 12))
                            .frame(width: 28, height: 22)
                    }
                    .buttonStyle(.plain)
                    .background(showPreview ? Color.accentColor : Color.clear)
                    .foregroundColor(showPreview ? .white : .secondary)
                    .help("Preview")
                }
                .background(Color(NSColor.separatorColor).opacity(0.3))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Editor or Preview
            if showPreview {
                MarkdownPreviewView(viewModel: viewModel)
            } else {
                MarkdownEditorView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
