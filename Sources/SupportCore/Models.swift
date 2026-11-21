import Foundation

/// What a request is about. The person picks one in the form.
public enum SupportCategory: String, Codable, Sendable, CaseIterable, Hashable {
    case bug, billing, account, question, request, other
}

/// The state the person sees. `waiting` covers received, drafted and in review.
public enum SupportTicketStatus: String, Codable, Sendable, Hashable {
    case waiting, answered, resolved
}

/// A value of an event's property. Keeps its type: an `Int` stays an integer.
public enum SupportValue: Sendable, Hashable, Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    public init(from decoder: any Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let i = try? c.decode(Int.self) { self = .int(i) }
        else if let d = try? c.decode(Double.self) { self = .double(d) }
        else { self = .string(try c.decode(String.self)) }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(String(s.prefix(200)))
        case .int(let i): try c.encode(i)
        case .double(let d): try c.encode(d)
        case .bool(let b): try c.encode(b)
        }
    }
}

extension SupportValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, ExpressibleByBooleanLiteral {
    public init(stringLiteral value: String) { self = .string(value) }
    public init(integerLiteral value: Int) { self = .int(value) }
    public init(floatLiteral value: Double) { self = .double(value) }
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}

/// One of the person's recent events, attached so the developer sees what happened before the request.
/// Never put text the person wrote (a habit's name, a note) in `props`.
public struct SupportRecentEvent: Sendable, Hashable, Codable {
    public var name: String
    public var at: Date
    public var props: [String: SupportValue]

    public init(name: String, at: Date, props: [String: SupportValue] = [:]) {
        self.name = name
        self.at = at
        self.props = props
    }

    enum CodingKeys: String, CodingKey { case name, at, props }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        at = Date(epochMilliseconds: try c.decode(Int64.self, forKey: .at))
        props = try c.decode([String: SupportValue].self, forKey: .props)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(at.epochMilliseconds, forKey: .at)
        try c.encode(props, forKey: .props)
    }
}

/// An in-app campaign shown recently (from swift-app-campaign's `campaign_shown`).
public struct SupportCampaignShown: Sendable, Hashable, Codable {
    public var campaign: String
    public var setVersion: Int
    public var at: Date

    public init(campaign: String, setVersion: Int, at: Date) {
        self.campaign = campaign
        self.setVersion = setVersion
        self.at = at
    }

    enum CodingKeys: String, CodingKey { case campaign, setVersion = "set_version", at }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        campaign = try c.decode(String.self, forKey: .campaign)
        setVersion = try c.decode(Int.self, forKey: .setVersion)
        at = Date(epochMilliseconds: try c.decode(Int64.self, forKey: .at))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(campaign, forKey: .campaign)
        try c.encode(setVersion, forKey: .setVersion)
        try c.encode(at.epochMilliseconds, forKey: .at)
    }
}

/// A help article in the product's index. The text itself is on the product's website at `url`.
public struct HelpArticle: Sendable, Hashable, Codable, Identifiable {
    public var slug: String
    public var lang: String
    public var title: String
    public var summary: String
    public var url: URL
    public var tags: [String]
    public var updatedAt: Date

    public var id: String { "\(slug)/\(lang)" }

    public init(slug: String, lang: String, title: String, summary: String, url: URL, tags: [String] = [], updatedAt: Date) {
        self.slug = slug
        self.lang = lang
        self.title = title
        self.summary = summary
        self.url = url
        self.tags = tags
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey { case slug, lang, title, summary, url, tags, updatedAt = "updated_at" }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        slug = try c.decode(String.self, forKey: .slug)
        lang = try c.decode(String.self, forKey: .lang)
        title = try c.decode(String.self, forKey: .title)
        summary = try c.decode(String.self, forKey: .summary)
        url = try c.decode(URL.self, forKey: .url)
        tags = try c.decode([String].self, forKey: .tags)
        updatedAt = Date(epochMilliseconds: try c.decode(Int64.self, forKey: .updatedAt))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(slug, forKey: .slug)
        try c.encode(lang, forKey: .lang)
        try c.encode(title, forKey: .title)
        try c.encode(summary, forKey: .summary)
        try c.encode(url, forKey: .url)
        try c.encode(tags, forKey: .tags)
        try c.encode(updatedAt.epochMilliseconds, forKey: .updatedAt)
    }
}

/// One message in a request: the person's, or the developer's reply.
public struct SupportMessage: Sendable, Hashable, Codable, Identifiable {
    public enum Author: String, Codable, Sendable, Hashable { case user, support }

    public var id: String
    public var from: Author
    public var body: String
    public var at: Date

    public init(id: String, from: Author, body: String, at: Date) {
        self.id = id
        self.from = from
        self.body = body
        self.at = at
    }

    enum CodingKeys: String, CodingKey { case id, from, body, at }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        from = try c.decode(Author.self, forKey: .from)
        body = try c.decode(String.self, forKey: .body)
        at = Date(epochMilliseconds: try c.decode(Int64.self, forKey: .at))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(from, forKey: .from)
        try c.encode(body, forKey: .body)
        try c.encode(at.epochMilliseconds, forKey: .at)
    }
}

/// One of the person's requests with its messages, newest last.
public struct SupportTicket: Sendable, Hashable, Codable, Identifiable {
    public var id: String
    public var status: SupportTicketStatus
    public var subject: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var messages: [SupportMessage]

    public init(id: String, status: SupportTicketStatus, subject: String?, createdAt: Date, updatedAt: Date, messages: [SupportMessage]) {
        self.id = id
        self.status = status
        self.subject = subject
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
    }

    /// The latest reply from the developer, if any.
    public var latestReply: SupportMessage? { messages.last { $0.from == .support } }

    enum CodingKeys: String, CodingKey { case id = "ticket_id", status, subject, createdAt = "created_at", updatedAt = "updated_at", messages }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        status = try c.decode(SupportTicketStatus.self, forKey: .status)
        subject = try c.decodeIfPresent(String.self, forKey: .subject)
        createdAt = Date(epochMilliseconds: try c.decode(Int64.self, forKey: .createdAt))
        updatedAt = Date(epochMilliseconds: try c.decode(Int64.self, forKey: .updatedAt))
        messages = try c.decode([SupportMessage].self, forKey: .messages)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(status, forKey: .status)
        try c.encode(subject, forKey: .subject)
        try c.encode(createdAt.epochMilliseconds, forKey: .createdAt)
        try c.encode(updatedAt.epochMilliseconds, forKey: .updatedAt)
        try c.encode(messages, forKey: .messages)
    }
}

/// An image attached to a request.
public struct SupportAttachment: Sendable, Hashable, Codable, Identifiable {
    public var id: String
    public var contentType: String
    public var bytes: Int
    public var at: Date

    enum CodingKeys: String, CodingKey { case id, contentType = "content_type", bytes, at }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        contentType = try c.decode(String.self, forKey: .contentType)
        bytes = try c.decode(Int.self, forKey: .bytes)
        at = Date(epochMilliseconds: try c.decode(Int64.self, forKey: .at))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(contentType, forKey: .contentType)
        try c.encode(bytes, forKey: .bytes)
        try c.encode(at.epochMilliseconds, forKey: .at)
    }
}

/// What the person wrote in the form.
public struct SupportRequest: Sendable, Hashable {
    public var category: SupportCategory
    public var subject: String?
    public var body: String
    /// Only when the person also wants the reply by email.
    public var email: String?
    /// Images to attach (up to 4). JPEG, PNG, HEIC or WebP, 5 MB each.
    public var images: [SupportImage]

    public init(category: SupportCategory, subject: String? = nil, body: String, email: String? = nil, images: [SupportImage] = []) {
        self.category = category
        self.subject = subject
        self.body = body
        self.email = email
        self.images = images
    }
}

/// An image ready to upload.
public struct SupportImage: Sendable, Hashable {
    public var data: Data
    public var contentType: String

    public init(data: Data, contentType: String) {
        self.data = data
        self.contentType = contentType
    }
}

extension Date {
    init(epochMilliseconds ms: Int64) { self.init(timeIntervalSince1970: Double(ms) / 1000) }
    var epochMilliseconds: Int64 { Int64((timeIntervalSince1970 * 1000).rounded()) }
}
