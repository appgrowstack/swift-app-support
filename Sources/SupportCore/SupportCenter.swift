import Foundation
import Observation

/// The state the support views read: this install's requests, the help articles, and whether a reply
/// is unread. Make one per app and keep it (it is cheap to refresh on return to the foreground).
@MainActor
@Observable
public final class SupportCenter {
    public private(set) var tickets: [SupportTicket] = []
    public private(set) var articles: [HelpArticle] = []
    public private(set) var isLoading = false
    /// The last error from `refresh`, for a quiet notice in the list. Sending errors are thrown instead.
    public private(set) var lastError: SupportError?

    public let client: SupportClient
    /// The language of the person's UI (`ja`, `en`, `zh-Hant`). Requests and articles use it.
    public var lang: String
    private let context: @MainActor (_ screen: String?) -> SupportContext
    private let seen: UserDefaults
    private let seenKey: String

    /// - Parameter context: builds the context at send time (`SupportContext.current(…)` with the
    ///   app's premium state, recent events and campaigns). `screen` is where the form was opened.
    public init(
        client: SupportClient,
        lang: String,
        context: @escaping @MainActor (_ screen: String?) -> SupportContext,
        seen: UserDefaults = .standard
    ) {
        self.client = client
        self.lang = lang
        self.context = context
        self.seen = seen
        self.seenKey = "swift-app-support.seen.\(client.publicKey)"
    }

    /// Requests with a reply the person hasn't opened yet. Show it as a badge on the entry point.
    public var unreadCount: Int {
        tickets.filter(isUnread).count
    }

    public func isUnread(_ ticket: SupportTicket) -> Bool {
        guard let reply = ticket.latestReply else { return false }
        let last = seen.double(forKey: "\(seenKey).\(ticket.id)")
        return reply.at.timeIntervalSince1970 > last
    }

    /// Marks the ticket's replies as read (call when the thread appears).
    public func markRead(_ ticket: SupportTicket) {
        guard let reply = ticket.latestReply else { return }
        seen.set(reply.at.timeIntervalSince1970, forKey: "\(seenKey).\(ticket.id)")
    }

    /// Reloads requests and articles. Errors are kept in `lastError`, not thrown.
    public func refresh() async {
        isLoading = true
        defer { isLoading = false }
        async let t = client.tickets()
        async let a = client.articles(lang: lang)
        do {
            tickets = try await t
            lastError = nil
        } catch let e as SupportError {
            lastError = e
        } catch {
            lastError = .transport(error.localizedDescription)
        }
        if let loaded = try? await a { articles = loaded }
    }

    /// Loads the articles only (for the form's suggestions before anything was sent).
    public func loadArticles() async {
        if let loaded = try? await client.articles(lang: lang) { articles = loaded }
    }

    /// Articles that may already answer what the person is typing.
    public func suggestions(for text: String, limit: Int = 3) -> [HelpArticle] {
        HelpSearch.search(text, in: articles, limit: limit)
    }

    /// Sends the form. Returns the new request's id and reloads the list.
    @discardableResult
    public func submit(_ request: SupportRequest, screen: String? = nil) async throws -> String {
        let id = try await client.submit(request, context: context(screen), lang: lang)
        if let t = try? await client.tickets() { tickets = t }
        return id
    }

    /// Adds a message to a request and reloads it.
    public func reply(_ body: String, to ticket: SupportTicket) async throws {
        _ = try await client.reply(body, to: ticket.id)
        if let t = try? await client.tickets() { tickets = t }
    }
}
