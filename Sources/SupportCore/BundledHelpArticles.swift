import Foundation

/// Help articles shipped in the app: a JSON file in the bundle with the same shape as a support
/// server's article list (`{ "articles": [ { "slug", "lang", "title", "summary", "url", "tags",
/// "updated_at" } ] }`). The text itself is on your website at each `url`.
public struct BundledHelpArticles: HelpArticleSource {
    private let all: [HelpArticle]

    /// Reads `<resource>.json` from `bundle`. A missing or unreadable file is an empty list.
    public init(resource: String, bundle: Bundle = .main) {
        let data = bundle.url(forResource: resource, withExtension: "json").flatMap { try? Data(contentsOf: $0) }
        self.init(data: data ?? Data())
    }

    public init(data: Data) {
        struct List: Decodable { let articles: [HelpArticle] }
        all = (try? JSONDecoder().decode(List.self, from: data))?.articles ?? []
    }

    public init(articles: [HelpArticle]) {
        all = articles
    }

    public func articles(lang: String) async throws -> [HelpArticle] {
        let base = String(lang.split(separator: "-").first ?? Substring(lang))
        for candidate in [lang, base, "en"] {
            let found = all.filter { $0.lang == candidate }
            if !found.isEmpty { return found }
        }
        return []
    }
}
