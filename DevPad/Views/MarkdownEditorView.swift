import SwiftUI

struct MarkdownEditorView: View {
    @ObservedObject var viewModel: MarkdownViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Editor toolbar
            HStack {
                if viewModel.isDirty {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Unsaved changes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: viewModel.save) {
                    Image(systemName: "opticaldiscdrive.fill")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.currentFileURL == nil && viewModel.content.isEmpty)
                .help("Save")

                Button(action: viewModel.saveAs) {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.borderless)
                .help("Save as...")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Text editor
            TextEditor(text: Binding(
                get: { viewModel.content },
                set: { viewModel.updateContent($0) }
            ))
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .background(Color(NSColor.textBackgroundColor))
        }
    }
}

#Preview {
    MarkdownEditorView(viewModel: MarkdownViewModel())
}
