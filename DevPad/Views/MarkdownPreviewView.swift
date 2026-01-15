import SwiftUI
import WebKit

struct MarkdownPreviewView: View {
    @ObservedObject var viewModel: MarkdownViewModel

    var body: some View {
        WebView(html: MarkdownParser.toHTML(viewModel.content))
    }
}

struct WebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}

#Preview {
    let vm = MarkdownViewModel()
    vm.content = """
    # Hello World

    This is a **bold** and *italic* text.

    ## Code Example

    ```
    let x = 42
    print(x)
    ```

    - Item 1
    - Item 2
    - Item 3

    [Link](https://apple.com)
    """
    return MarkdownPreviewView(viewModel: vm)
}
