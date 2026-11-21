import Foundation

/// Finds help articles for what the person is typing, so the answer can come before the request.
/// Works for languages without spaces: it matches words and, for CJK text, runs of two characters.
public enum HelpSearch {
    /// Articles ranked by how well they match `query`. Articles that don't match are left out.
    public static func search(_ query: String, in articles: [HelpArticle], limit: Int = 5) -> [HelpArticle] {
        let terms = self.terms(query)
        guard !terms.isEmpty else { return [] }
        let scored = articles.compactMap { article -> (HelpArticle, Double)? in
            let title = fold(article.title)
            let body = fold(article.summary + " " + article.tags.joined(separator: " "))
            var score = 0.0
            for t in terms {
                if title.contains(t) { score += 3 }
                if body.contains(t) { score += 1 }
            }
            let ratio = score / Double(terms.count * 4)
            return ratio >= 0.15 ? (article, ratio) : nil
        }
        return scored.sorted { $0.1 > $1.1 || ($0.1 == $1.1 && $0.0.title < $1.0.title) }.prefix(limit).map(\.0)
    }

    static func fold(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }

    /// Words of two or more letters; CJK runs become overlapping pairs (「解約したい」→ 解約・約し).
    static func terms(_ query: String) -> [String] {
        var out: [String] = []
        var word = ""
        var cjk: [Character] = []
        func flushWord() {
            if word.count >= 2 { out.append(word) }
            word = ""
        }
        func flushCJK() {
            if cjk.count == 1 { out.append(String(cjk)) }
            else if cjk.count >= 2 {
                // ひらがなだけの組（した・たい）は文法なので、漢字やカタカナの混じる文では数えない
                let mixed = cjk.contains { !isHiragana($0) }
                for i in 0 ..< cjk.count - 1 where !(mixed && isHiragana(cjk[i]) && isHiragana(cjk[i + 1])) {
                    out.append(String(cjk[i ... i + 1]))
                }
            }
            cjk = []
        }
        for ch in fold(query) {
            if isCJK(ch) {
                flushWord()
                cjk.append(ch)
            } else if ch.isLetter || ch.isNumber {
                flushCJK()
                word.append(ch)
            } else {
                flushWord()
                flushCJK()
            }
        }
        flushWord()
        flushCJK()
        return Array(Set(out)).sorted()
    }

    static func isHiragana(_ ch: Character) -> Bool {
        guard let v = ch.unicodeScalars.first?.value else { return false }
        return (0x3040 ... 0x309F).contains(v)
    }

    static func isCJK(_ ch: Character) -> Bool {
        guard let v = ch.unicodeScalars.first?.value else { return false }
        return (0x3040 ... 0x30FF).contains(v) || (0x3400 ... 0x9FFF).contains(v) || (0xAC00 ... 0xD7AF).contains(v) || (0xF900 ... 0xFAFF).contains(v)
    }
}
