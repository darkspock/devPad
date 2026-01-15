import Foundation

struct MarkdownParser {
    static func toHTML(_ markdown: String) -> String {
        var html = markdown

        // Escape HTML
        html = html.replacingOccurrences(of: "&", with: "&amp;")
        html = html.replacingOccurrences(of: "<", with: "&lt;")
        html = html.replacingOccurrences(of: ">", with: "&gt;")

        // Headers
        let headerPatterns: [(String, String, String)] = [
            ("######\\s+(.+)", "<h6>", "</h6>"),
            ("#####\\s+(.+)", "<h5>", "</h5>"),
            ("####\\s+(.+)", "<h4>", "</h4>"),
            ("###\\s+(.+)", "<h3>", "</h3>"),
            ("##\\s+(.+)", "<h2>", "</h2>"),
            ("#\\s+(.+)", "<h1>", "</h1>")
        ]

        for (pattern, openTag, closeTag) in headerPatterns {
            if let regex = try? NSRegularExpression(pattern: "^" + pattern, options: .anchorsMatchLines) {
                html = regex.stringByReplacingMatches(
                    in: html,
                    range: NSRange(html.startIndex..., in: html),
                    withTemplate: "\(openTag)$1\(closeTag)"
                )
            }
        }

        // Bold
        if let regex = try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*", options: []) {
            html = regex.stringByReplacingMatches(
                in: html,
                range: NSRange(html.startIndex..., in: html),
                withTemplate: "<strong>$1</strong>"
            )
        }

        // Italic
        if let regex = try? NSRegularExpression(pattern: "\\*(.+?)\\*", options: []) {
            html = regex.stringByReplacingMatches(
                in: html,
                range: NSRange(html.startIndex..., in: html),
                withTemplate: "<em>$1</em>"
            )
        }

        // Inline code
        if let regex = try? NSRegularExpression(pattern: "`([^`]+)`", options: []) {
            html = regex.stringByReplacingMatches(
                in: html,
                range: NSRange(html.startIndex..., in: html),
                withTemplate: "<code>$1</code>"
            )
        }

        // Code blocks
        if let regex = try? NSRegularExpression(pattern: "```([\\s\\S]*?)```", options: []) {
            html = regex.stringByReplacingMatches(
                in: html,
                range: NSRange(html.startIndex..., in: html),
                withTemplate: "<pre><code>$1</code></pre>"
            )
        }

        // Links
        if let regex = try? NSRegularExpression(pattern: "\\[(.+?)\\]\\((.+?)\\)", options: []) {
            html = regex.stringByReplacingMatches(
                in: html,
                range: NSRange(html.startIndex..., in: html),
                withTemplate: "<a href=\"$2\">$1</a>"
            )
        }

        // Horizontal rule
        if let regex = try? NSRegularExpression(pattern: "^---+$", options: .anchorsMatchLines) {
            html = regex.stringByReplacingMatches(
                in: html,
                range: NSRange(html.startIndex..., in: html),
                withTemplate: "<hr>"
            )
        }

        // Unordered lists
        if let regex = try? NSRegularExpression(pattern: "^[\\*\\-]\\s+(.+)$", options: .anchorsMatchLines) {
            html = regex.stringByReplacingMatches(
                in: html,
                range: NSRange(html.startIndex..., in: html),
                withTemplate: "<li>$1</li>"
            )
        }

        // Paragraphs (simple: add breaks for double newlines)
        html = html.replacingOccurrences(of: "\n\n", with: "</p><p>")

        // Line breaks
        html = html.replacingOccurrences(of: "\n", with: "<br>")

        return wrapHTML(html)
    }

    private static func wrapHTML(_ body: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    padding: 20px;
                    max-width: 800px;
                    margin: 0 auto;
                    color: #333;
                    background: #fff;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #e0e0e0;
                        background: #1e1e1e;
                    }
                    a { color: #6db3f2; }
                    code { background: #2d2d2d; }
                    pre { background: #2d2d2d; }
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 24px;
                    margin-bottom: 16px;
                    font-weight: 600;
                }
                h1 { font-size: 2em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
                h2 { font-size: 1.5em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
                code {
                    background: #f4f4f4;
                    padding: 2px 6px;
                    border-radius: 3px;
                    font-family: 'SF Mono', Monaco, monospace;
                    font-size: 0.9em;
                }
                pre {
                    background: #f4f4f4;
                    padding: 16px;
                    border-radius: 6px;
                    overflow-x: auto;
                }
                pre code {
                    background: none;
                    padding: 0;
                }
                a {
                    color: #0366d6;
                    text-decoration: none;
                }
                a:hover {
                    text-decoration: underline;
                }
                hr {
                    border: none;
                    border-top: 1px solid #eee;
                    margin: 24px 0;
                }
                li {
                    margin: 4px 0;
                }
            </style>
        </head>
        <body>
            <p>\(body)</p>
        </body>
        </html>
        """
    }
}
