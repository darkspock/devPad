import SwiftUI

struct FileExplorerView: View {
    @ObservedObject var viewModel: FileExplorerViewModel
    @State private var showNewFileDialog = false
    @State private var showNewFolderDialog = false
    @State private var showRenameDialog = false
    @State private var newItemName = ""
    @State private var targetDirectory: URL?
    @State private var itemToRename: FileItem?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button(action: viewModel.goUp) {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.borderless)
                .help("Go to parent folder")

                Text(viewModel.currentDirectory.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button(action: {
                    targetDirectory = viewModel.currentDirectory
                    newItemName = "untitled.md"
                    showNewFileDialog = true
                }) {
                    Image(systemName: "doc.badge.plus")
                }
                .buttonStyle(.borderless)
                .help("New file")

                Button(action: viewModel.openFolder) {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Open folder")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // File list
            List(viewModel.rootItems, id: \.id, selection: $viewModel.selectedFile) { item in
                FileRowView(
                    item: item,
                    viewModel: viewModel,
                    level: 0,
                    onNewFile: { dir in
                        targetDirectory = dir
                        newItemName = "untitled.md"
                        showNewFileDialog = true
                    },
                    onNewFolder: { dir in
                        targetDirectory = dir
                        newItemName = "New Folder"
                        showNewFolderDialog = true
                    },
                    onRename: { item in
                        itemToRename = item
                        newItemName = item.name
                        showRenameDialog = true
                    }
                )
            }
            .listStyle(.sidebar)
            .contextMenu {
                Button("New File...") {
                    targetDirectory = viewModel.currentDirectory
                    newItemName = "untitled.md"
                    showNewFileDialog = true
                }
                Button("New Folder...") {
                    targetDirectory = viewModel.currentDirectory
                    newItemName = "New Folder"
                    showNewFolderDialog = true
                }
            }
        }
        .sheet(isPresented: $showNewFileDialog) {
            NewItemDialog(
                title: "New File",
                placeholder: "File name",
                itemName: $newItemName,
                onCancel: { showNewFileDialog = false },
                onCreate: {
                    viewModel.createFile(named: newItemName, in: targetDirectory)
                    showNewFileDialog = false
                }
            )
        }
        .sheet(isPresented: $showNewFolderDialog) {
            NewItemDialog(
                title: "New Folder",
                placeholder: "Folder name",
                itemName: $newItemName,
                onCancel: { showNewFolderDialog = false },
                onCreate: {
                    viewModel.createFolder(named: newItemName, in: targetDirectory)
                    showNewFolderDialog = false
                }
            )
        }
        .sheet(isPresented: $showRenameDialog) {
            NewItemDialog(
                title: "Rename",
                placeholder: "New name",
                itemName: $newItemName,
                onCancel: { showRenameDialog = false },
                onCreate: {
                    if let item = itemToRename {
                        viewModel.renameItem(item, to: newItemName)
                    }
                    showRenameDialog = false
                }
            )
        }
    }
}

struct NewItemDialog: View {
    let title: String
    let placeholder: String
    @Binding var itemName: String
    let onCancel: () -> Void
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)

            TextField(placeholder, text: $itemName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)
                .onSubmit(onCreate)

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.escape)

                Button("Create", action: onCreate)
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                    .disabled(itemName.isEmpty)
            }
        }
        .padding(24)
    }
}

struct FileRowView: View {
    let item: FileItem
    @ObservedObject var viewModel: FileExplorerViewModel
    let level: Int
    var onNewFile: ((URL) -> Void)?
    var onNewFolder: ((URL) -> Void)?
    var onRename: ((FileItem) -> Void)?

    @State private var children: [FileItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                if item.isDirectory {
                    Image(systemName: viewModel.isExpanded(item) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.toggleExpanded(item)
                                if viewModel.isExpanded(item) && children.isEmpty {
                                    children = viewModel.loadChildren(for: item)
                                }
                            }
                        }
                } else {
                    Spacer()
                        .frame(width: 12)
                }

                Image(systemName: item.icon)
                    .foregroundColor(item.isDirectory ? .accentColor : .secondary)
                    .frame(width: 16)

                Text(item.name)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .padding(.leading, CGFloat(level * 16))
            .background(
                viewModel.selectedFile?.id == item.id
                    ? Color.accentColor.opacity(0.2)
                    : Color.clear
            )
            .cornerRadius(4)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectItem(item)
                if item.isDirectory && children.isEmpty {
                    children = viewModel.loadChildren(for: item)
                }
            }
            .contextMenu {
                if item.isDirectory {
                    Button("New File...") {
                        onNewFile?(item.url)
                    }
                    Button("New Folder...") {
                        onNewFolder?(item.url)
                    }
                    Divider()
                }
                Button("Rename...") {
                    onRename?(item)
                }
                Button("Delete", role: .destructive) {
                    viewModel.deleteItem(item)
                }
            }

            // Children
            if item.isDirectory && viewModel.isExpanded(item) {
                ForEach(children, id: \.id) { child in
                    FileRowView(
                        item: child,
                        viewModel: viewModel,
                        level: level + 1,
                        onNewFile: onNewFile,
                        onNewFolder: onNewFolder,
                        onRename: onRename
                    )
                }
            }
        }
    }
}
