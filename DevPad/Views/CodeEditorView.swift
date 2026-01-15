import SwiftUI
import AppKit
import Highlightr

struct CodeEditorView: NSViewRepresentable {
    @Binding var text: String
    let language: String?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.backgroundColor = NSColor(red: 0.12, green: 0.13, blue: 0.15, alpha: 1.0)
        textView.textColor = .white
        textView.insertionPointColor = .white
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isRichText = false

        textView.minSize = NSSize(width: 0, height: scrollView.contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView

        context.coordinator.textView = textView
        context.coordinator.setupHighlighter()
        textView.delegate = context.coordinator

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        context.coordinator.language = language

        if textView.string != text {
            context.coordinator.isUpdating = true
            let selectedRanges = textView.selectedRanges
            textView.string = text
            context.coordinator.applyHighlighting()
            textView.selectedRanges = selectedRanges
            context.coordinator.isUpdating = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeEditorView
        weak var textView: NSTextView?
        var highlightr: Highlightr?
        var language: String?
        var isUpdating = false
        private var highlightTimer: Timer?

        init(_ parent: CodeEditorView) {
            self.parent = parent
            self.language = parent.language
        }

        func setupHighlighter() {
            highlightr = Highlightr()
            highlightr?.setTheme(to: "atom-one-dark")
        }

        func applyHighlighting() {
            guard let textView = textView,
                  let highlightr = highlightr,
                  let textStorage = textView.textStorage else { return }

            let text = textView.string
            guard !text.isEmpty else { return }

            if let highlighted = highlightr.highlight(text, as: language) {
                let mutable = NSMutableAttributedString(attributedString: highlighted)
                let fullRange = NSRange(location: 0, length: mutable.length)
                mutable.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: fullRange)

                let selectedRanges = textView.selectedRanges
                textStorage.beginEditing()
                textStorage.setAttributedString(mutable)
                textStorage.endEditing()
                textView.selectedRanges = selectedRanges
            }
        }

        func scheduleHighlighting() {
            highlightTimer?.invalidate()
            highlightTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.applyHighlighting()
                }
            }
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? NSTextView else { return }

            parent.text = textView.string
            scheduleHighlighting()
        }
    }
}

extension String {
    var detectedLanguage: String? {
        let ext = (self as NSString).pathExtension.lowercased()
        let languageMap: [String: String] = [
            "swift": "swift",
            "m": "objectivec", "mm": "objectivec", "h": "objectivec",
            "c": "c", "cpp": "cpp", "cc": "cpp", "cxx": "cpp", "hpp": "cpp",
            "js": "javascript", "jsx": "javascript", "mjs": "javascript",
            "ts": "typescript", "tsx": "typescript",
            "py": "python", "pyw": "python",
            "rb": "ruby",
            "java": "java",
            "kt": "kotlin", "kts": "kotlin",
            "go": "go",
            "rs": "rust",
            "php": "php",
            "html": "xml", "htm": "xml", "xhtml": "xml",
            "css": "css",
            "scss": "scss", "sass": "scss",
            "less": "less",
            "json": "json",
            "xml": "xml", "plist": "xml", "svg": "xml",
            "yaml": "yaml", "yml": "yaml",
            "md": "markdown", "markdown": "markdown",
            "sql": "sql",
            "sh": "bash", "bash": "bash", "zsh": "bash",
            "ps1": "powershell",
            "r": "r",
            "lua": "lua",
            "perl": "perl", "pl": "perl",
            "scala": "scala",
            "groovy": "groovy",
            "dart": "dart",
            "ex": "elixir", "exs": "elixir",
            "erl": "erlang",
            "hs": "haskell",
            "clj": "clojure",
            "vim": "vim",
            "dockerfile": "dockerfile",
            "makefile": "makefile",
            "cmake": "cmake",
            "toml": "toml",
            "ini": "ini", "conf": "ini", "cfg": "ini",
            "diff": "diff", "patch": "diff",
            "cs": "csharp",
            "fs": "fsharp",
            "vb": "vbnet",
        ]

        // Handle special filenames
        let filename = (self as NSString).lastPathComponent.lowercased()
        if filename == "dockerfile" { return "dockerfile" }
        if filename == "makefile" || filename == "gnumakefile" { return "makefile" }
        if filename == ".gitignore" || filename == ".env" { return "bash" }

        return languageMap[ext]
    }
}
