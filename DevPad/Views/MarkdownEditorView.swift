import SwiftUI

struct MarkdownEditorView: View {
    @ObservedObject var viewModel: MarkdownViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Mini toolbar
            HStack {
                Spacer()

                Button(action: viewModel.save) {
                    Image(systemName: "opticaldiscdrive.fill")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.currentFileURL == nil)
                .help("Save")

                Button(action: viewModel.saveAs) {
                    Image(systemName: "document.on.document")
                }
                .buttonStyle(.borderless)
                .help("Save as...")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
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
