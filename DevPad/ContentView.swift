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
            if let file = newFile, !file.isDirectory {
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
            // Tab bar
            if !viewModel.tabs.isEmpty {
                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(viewModel.tabs) { tab in
                                EditorTabButton(
                                    tab: tab,
                                    isSelected: viewModel.selectedTabId == tab.id,
                                    onSelect: { viewModel.selectTab(tab) },
                                    onClose: { viewModel.closeTab(tab) }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }

                    Spacer()

                    // Edit/Preview toggle
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
                    .padding(.trailing, 8)
                }
                .frame(height: 32)
                .background(Color(NSColor.controlBackgroundColor))

                Divider()
            }

            // Editor or Preview or Empty state
            if viewModel.tabs.isEmpty {
                VStack {
                    Spacer()
                    Text("No file open")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Select a file from the explorer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.textBackgroundColor))
            } else if showPreview {
                MarkdownPreviewView(viewModel: viewModel)
            } else {
                MarkdownEditorView(viewModel: viewModel)
            }
        }
    }
}

struct EditorTabButton: View {
    @ObservedObject var tab: EditorTab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 4) {
            if tab.isDirty {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }

            Text(tab.title)
                .font(.system(size: 11))
                .lineLimit(1)

            if isSelected || isHovering {
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

#Preview {
    ContentView()
}
