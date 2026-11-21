import Foundation

/// What a transport can do. The views hide what it cannot (the list of replies, the screenshots).
public struct SupportCapabilities: Sendable, Hashable {
    /// The person can read their requests and the replies inside the app.
    public var replies: Bool
    /// Screenshots can be attached.
    public var images: Bool

    public init(replies: Bool, images: Bool) {
        self.replies = replies
        self.images = images
    }
}

/// Where a request goes. ``MailSupportTransport`` opens a mail to you; a transport that talks to a
/// support server can also list the person's requests and replies.
public protocol SupportTransport: Sendable {
    var capabilities: SupportCapabilities { get }

    /// Sends a request with its images (when ``SupportCapabilities/images``). Returns its id.
    func submit(_ request: SupportRequest, context: SupportContext, lang: String) async throws -> String

    /// This install's requests, newest first. Empty when the transport has no replies.
    func tickets() async throws -> [SupportTicket]

    /// Adds a message to one of this install's requests.
    func reply(_ body: String, to ticketID: String) async throws -> SupportMessage
}

/// The help articles to search before writing.
public protocol HelpArticleSource: Sendable {
    /// The articles in `lang`, falling back to the base language, then English.
    func articles(lang: String) async throws -> [HelpArticle]
}

public enum SupportError: Error, Sendable, Equatable {
    /// Too many requests from this install, or too many images on one request.
    case rateLimited
    /// The request isn't this install's, or the product doesn't take requests.
    case notFound
    /// The request was rejected (`code` and `message` from the answer).
    case rejected(status: Int, code: String, message: String)
    /// No network, no mail app, or the answer could not be read.
    case transport(String)
    /// The transport cannot do this (replying by mail).
    case unsupported
}
