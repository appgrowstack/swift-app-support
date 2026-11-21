import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Sends a request as a mail to you: the system mail composer (or the mail app) opens with the
/// subject, the person's text and the context below it as readable lines. No server, no replies in
/// the app, no screenshots.
public struct MailSupportTransport: SupportTransport {
    public let to: String
    private let open: @Sendable (URL) async -> Bool

    /// - Parameters:
    ///   - to: your support address.
    ///   - open: opens the `mailto:` URL. The system's by default; tests pass their own.
    public init(to: String, open: @escaping @Sendable (URL) async -> Bool = MailSupportTransport.openWithSystem) {
        self.to = to
        self.open = open
    }

    public var capabilities: SupportCapabilities { SupportCapabilities(replies: false, images: false) }

    public func submit(_ request: SupportRequest, context: SupportContext, lang: String) async throws -> SupportSubmission {
        guard await open(mailtoURL(request, context: context)) else { throw SupportError.transport("no mail app") }
        return SupportSubmission(ticketID: "mail")
    }

    public func tickets() async throws -> [SupportTicket] { [] }

    public func reply(_ body: String, to ticketID: String) async throws -> SupportMessage {
        throw SupportError.unsupported
    }

    func mailtoURL(_ request: SupportRequest, context: SupportContext) -> URL {
        let subject = request.subject?.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = String(request.body.trimmingCharacters(in: .whitespacesAndNewlines).prefix(4000))
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = to
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject?.isEmpty == false ? String(subject!.prefix(120)) : "[\(request.category.rawValue)]"),
            URLQueryItem(name: "body", value: body + "\n\n---\n" + context.readableLines.joined(separator: "\n"))
        ]
        return components.url!
    }

    /// `UIApplication.open` on iOS, `NSWorkspace.open` on macOS.
    public static let openWithSystem: @Sendable (URL) async -> Bool = { @MainActor url in
        #if canImport(UIKit)
        return await UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        return NSWorkspace.shared.open(url)
        #else
        return false
        #endif
    }
}

extension SupportContext {
    /// The context as lines a person can read at the bottom of a mail.
    public var readableLines: [String] {
        var lines = [
            "App: \(appVersion) (\(build)) \(channel.rawValue)",
            "Device: \(platform) \(osVersion) \(deviceModel)"
        ]
        if let isPremium { lines.append("Premium: \(isPremium ? "yes" : "no")") }
        if let screen { lines.append("Screen: \(screen)") }
        if let sessionID { lines.append("Session: \(sessionID)") }
        if !recentEvents.isEmpty { lines.append("Recent: " + recentEvents.prefix(5).map(\.name).joined(separator: ", ")) }
        if !campaignsShown.isEmpty { lines.append("Campaigns: " + campaignsShown.prefix(3).map(\.campaign).joined(separator: ", ")) }
        return lines
    }
}
