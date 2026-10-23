import AppKit
import SwiftUI

/// A small markdown renderer for the licenses sheet. `Text` styles the inline runs of an
/// `AttributedString` but ignores block-level intents, so headings, code blocks and rules are laid
/// out here.
struct MarkdownView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(parse().enumerated()), id: \.offset) { _, block in
                view(for: block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum Block {
        case heading(level: Int, text: String)
        case paragraph(AttributedString)
        case codeBlock(String)
        case rule
    }

    private func parse() -> [Block] {
        let lines = markdown.components(separatedBy: "\n")
        var result: [Block] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]

            // A fenced code block; the language hint is ignored.
            if line.hasPrefix("```") {
                index += 1
                var code: [String] = []
                while index < lines.count, !lines[index].hasPrefix("```") {
                    code.append(lines[index])
                    index += 1
                }
                index += 1  // the closing fence, or the end
                result.append(.codeBlock(code.joined(separator: "\n")))
                continue
            }

            if let level = Self.headingLevel(line) {
                result.append(.heading(level: level, text: String(line.dropFirst(level + 1))))
                index += 1
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if Self.isRule(trimmed) {
                result.append(.rule)
                index += 1
                continue
            }
            if trimmed.isEmpty {
                index += 1
                continue
            }

            var paragraph = [line]
            index += 1
            while index < lines.count {
                let next = lines[index]
                let nextTrimmed = next.trimmingCharacters(in: .whitespaces)
                if nextTrimmed.isEmpty || next.hasPrefix("```") || Self.headingLevel(next) != nil || Self.isRule(nextTrimmed) {
                    break
                }
                paragraph.append(next)
                index += 1
            }
            let joined = paragraph.joined(separator: " ")
            result.append(.paragraph((try? AttributedString(markdown: joined)) ?? AttributedString(joined)))
        }
        return result
    }

    private static func headingLevel(_ line: String) -> Int? {
        for level in 1...3 where line.hasPrefix(String(repeating: "#", count: level) + " ") {
            return level
        }
        return nil
    }

    private static func isRule(_ trimmed: String) -> Bool {
        trimmed.count >= 3 && trimmed.allSatisfy { $0 == "-" }
    }

    @ViewBuilder private func view(for block: Block) -> some View {
        switch block {
        case .heading(let level, let text):
            switch level {
            case 1: Text(verbatim: text).font(.title.weight(.bold))
            case 2: Text(verbatim: text).font(.title2.weight(.semibold)).padding(.top, 6)
            default: Text(verbatim: text).font(.title3.weight(.semibold)).padding(.top, 4)
            }
        case .paragraph(let attributed):
            Text(attributed)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        case .codeBlock(let code):
            Text(verbatim: code)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .textBackgroundColor).opacity(0.35)))
        case .rule:
            Divider()
        }
    }
}
