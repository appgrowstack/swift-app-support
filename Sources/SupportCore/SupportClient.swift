import Foundation
import Security

/// Keeps the owner token: the random key that lets this install read its own requests and replies.
/// The server stores only its SHA-256.
public protocol SupportTokenStore: Sendable {
    func load() -> String?
    func save(_ token: String)
}

/// The owner token in the Keychain (this device only, readable after the first unlock).
public struct KeychainSupportTokenStore: SupportTokenStore {
    public let service: String
    public let account: String

    public init(service: String = "swift-app-support", account: String = "owner_token") {
        self.service = service
        self.account = account
    }

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }

    public func load() -> String? {
        var q = query
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func save(_ token: String) {
        SecItemDelete(query as CFDictionary)
        var q = query
        q[kSecValueData as String] = Data(token.utf8)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(q as CFDictionary, nil)
    }
}

/// An in-memory store for tests and previews.
public final class MemorySupportTokenStore: SupportTokenStore, @unchecked Sendable {
    private let lock = NSLock()
    private var token: String?

    public init(token: String? = nil) { self.token = token }

    public func load() -> String? { lock.withLock { token } }
    public func save(_ token: String) { lock.withLock { self.token = token } }
}

/// Sends a request. `URLSession.shared` by default; tests pass a fake.
public protocol SupportTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionSupportTransport: SupportTransport {
    public let session: URLSession
    public init(session: URLSession = .shared) { self.session = session }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw SupportError.transport("not an HTTP response") }
        return (data, http)
    }
}

public enum SupportError: Error, Sendable, Equatable {
    /// Too many requests from this install (5 an hour), or more than 4 images on one request.
    case rateLimited
    /// The request isn't this install's, or the product doesn't take requests.
    case notFound
    /// The server rejected what was sent (`code` and `message` from the error body).
    case rejected(status: Int, code: String, message: String)
    /// No network, or the answer could not be read.
    case transport(String)
}

/// The device API for support (`api.appgrowstack.com/v1/support/*`). Stateless apart from the owner token.
public struct SupportClient: Sendable {
    public static let productionEndpoint = URL(string: "https://api.appgrowstack.com")!
    public static let stagingEndpoint = URL(string: "https://api-staging.appgrowstack.com")!

    public let publicKey: String
    public let endpoint: URL
    public let installID: String
    public let uid: @Sendable () -> String?
    let transport: any SupportTransport
    let tokens: any SupportTokenStore

    /// - Parameters:
    ///   - publicKey: the product's `pk_…` key.
    ///   - installID: the install id your analytics and swift-app-campaign use (a lowercase UUID).
    ///   - uid: the signed-in account, if any. Read at each request.
    public init(
        publicKey: String,
        installID: String,
        uid: @escaping @Sendable () -> String? = { nil },
        endpoint: URL = SupportClient.productionEndpoint,
        transport: any SupportTransport = URLSessionSupportTransport(),
        tokens: any SupportTokenStore = KeychainSupportTokenStore()
    ) {
        self.publicKey = publicKey
        self.installID = installID
        self.uid = uid
        self.endpoint = endpoint
        self.transport = transport
        self.tokens = tokens
    }

    /// The owner token, made on first use (43 URL-safe characters from 32 random bytes).
    public func ownerToken() -> String {
        if let t = tokens.load(), t.count >= 32 { return t }
        var bytes = [UInt8](repeating: 0, count: 32)
        if SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) != errSecSuccess {
            var rng = SystemRandomNumberGenerator()
            bytes = bytes.map { _ in UInt8.random(in: .min ... .max, using: &rng) }
        }
        let token = Data(bytes).base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        tokens.save(token)
        return token
    }

    /// Whether this install has ever sent a request (and so may have replies to read).
    public var hasOwnerToken: Bool { (tokens.load()?.count ?? 0) >= 32 }

    // MARK: - Calls

    /// Sends a request and then its images. Returns the new request's id.
    @discardableResult
    public func submit(_ request: SupportRequest, context: SupportContext, lang: String) async throws -> String {
        struct Body: Encodable {
            let install_id: String
            let uid: String?
            let owner_token: String
            let lang: String
            let email: String?
            let category: SupportCategory
            let subject: String?
            let body: String
            let context: SupportContext
        }
        struct Created: Decodable { let ticket_id: String }
        let subject = request.subject?.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = request.email?.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = Body(
            install_id: installID,
            uid: uid(),
            owner_token: ownerToken(),
            lang: lang,
            email: email?.isEmpty == false ? email : nil,
            category: request.category,
            subject: subject?.isEmpty == false ? String(subject!.prefix(120)) : nil,
            body: String(request.body.trimmingCharacters(in: .whitespacesAndNewlines).prefix(4000)),
            context: context
        )
        let created: Created = try await call("POST", "/v1/support/tickets", json: body, token: false)
        for image in request.images.prefix(4) {
            _ = try await uploadImage(image, ticketID: created.ticket_id)
        }
        return created.ticket_id
    }

    /// This install's requests, newest first. Empty until the first request.
    public func tickets() async throws -> [SupportTicket] {
        guard hasOwnerToken else { return [] }
        struct List: Decodable { let tickets: [SupportTicket] }
        let list: List = try await call("GET", "/v1/support/tickets", token: true)
        return list.tickets
    }

    /// Adds a message to one of this install's requests.
    public func reply(_ body: String, to ticketID: String) async throws -> SupportMessage {
        struct Body: Encodable { let body: String }
        return try await call("POST", "/v1/support/tickets/\(ticketID)/messages", json: Body(body: String(body.prefix(4000))), token: true)
    }

    public func uploadImage(_ image: SupportImage, ticketID: String) async throws -> SupportAttachment {
        var req = request("POST", "/v1/support/tickets/\(ticketID)/attachments", token: true)
        req.setValue(image.contentType, forHTTPHeaderField: "Content-Type")
        req.httpBody = image.data
        return try await decode(req)
    }

    /// The product's help articles in `lang` (falling back to the base language, then English).
    public func articles(lang: String) async throws -> [HelpArticle] {
        struct List: Decodable { let articles: [HelpArticle] }
        var components = URLComponents(url: endpoint.appending(path: "/v1/support/articles"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "lang", value: lang)]
        var req = URLRequest(url: components.url!)
        req.setValue("Bearer \(publicKey)", forHTTPHeaderField: "Authorization")
        let list: List = try await decode(req)
        return list.articles
    }

    // MARK: - HTTP

    func request(_ method: String, _ path: String, token: Bool) -> URLRequest {
        var req = URLRequest(url: endpoint.appending(path: path))
        req.httpMethod = method
        req.setValue("Bearer \(publicKey)", forHTTPHeaderField: "Authorization")
        if token { req.setValue(ownerToken(), forHTTPHeaderField: "X-Support-Token") }
        return req
    }

    private func call<T: Decodable>(_ method: String, _ path: String, token: Bool) async throws -> T {
        try await decode(request(method, path, token: token))
    }

    private func call<T: Decodable, B: Encodable>(_ method: String, _ path: String, json: B, token: Bool) async throws -> T {
        var req = request(method, path, token: token)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(json)
        return try await decode(req)
    }

    private func decode<T: Decodable>(_ req: URLRequest) async throws -> T {
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport.send(req)
        } catch let error as SupportError {
            throw error
        } catch {
            throw SupportError.transport(error.localizedDescription)
        }
        switch response.statusCode {
        case 200 ..< 300:
            do { return try JSONDecoder().decode(T.self, from: data) } catch { throw SupportError.transport("unreadable answer: \(error)") }
        case 404: throw SupportError.notFound
        case 429: throw SupportError.rateLimited
        default:
            let e = try? JSONDecoder().decode(ErrorBody.self, from: data)
            throw SupportError.rejected(status: response.statusCode, code: e?.error.code ?? "unknown", message: e?.error.message ?? "")
        }
    }
}

/// `{ "error": { "code", "message" } }`
private struct ErrorBody: Decodable {
    struct Inner: Decodable {
        let code: String
        let message: String
    }
    let error: Inner
}
