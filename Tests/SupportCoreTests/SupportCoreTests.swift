import Foundation
@testable import SupportCore
import Testing

/// Records requests and answers from a table of (method path) → (status, body).
final class FakeTransport: SupportTransport, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var requests: [URLRequest] = []
    var answers: [String: (Int, String)] = [:]

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let key = "\(request.httpMethod ?? "GET") \(request.url!.path())"
        let answer = lock.withLock { () -> (Int, String)? in
            requests.append(request)
            return answers[key]
        }
        guard let (status, body) = answer else { throw URLError(.notConnectedToInternet) }
        return (Data(body.utf8), HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }

    func json(_ i: Int) throws -> [String: Any] {
        try JSONSerialization.jsonObject(with: requests[i].httpBody ?? Data()) as! [String: Any]
    }
}

let install = "a1b2c3d4-0000-4000-8000-000000000001"
let ticketJSON = #"{"tickets":[{"ticket_id":"tkt_0123456789abcdef","status":"answered","subject":null,"created_at":1700000000000,"updated_at":1700000100000,"messages":[{"id":"msg_0123456789abcdef","from":"user","body":"解約したい","at":1700000000000},{"id":"msg_fedcba9876543210","from":"support","body":"App Store で解約できます","at":1700000100000}]}]}"#
let articlesJSON = #"{"articles":[{"slug":"cancel-subscription","lang":"ja","title":"サブスクリプションを解約する","summary":"iPhoneはApp Store、AndroidはGoogle Playで解約します。","url":"https://gohobishukan.com/help/cancel-subscription/","tags":["billing"],"updated_at":1},{"slug":"widget","lang":"ja","title":"ウィジェットを置く","summary":"ホーム画面にウィジェットを置きます。","url":"https://gohobishukan.com/help/widget/","tags":[],"updated_at":1}]}"#

func context() -> SupportContext {
    SupportContext(
        appVersion: "3.2.0", build: "120", osVersion: "26.1", deviceModel: "iPhone17,1", channel: .appStore, isPremium: true, screen: "settings",
        recentEvents: (0 ..< 25).map { _ in SupportRecentEvent(name: "habit_achieved", at: Date(timeIntervalSince1970: 1_700_000_000), props: ["streak_days": 3, "category": "health"]) },
        campaignsShown: [SupportCampaignShown(campaign: "trial-offer", setVersion: 3, at: Date(timeIntervalSince1970: 1_700_000_000))]
    )
}

struct SupportClientTests {
    @Test func submitSendsTheContractBodyAndThenTheImages() async throws {
        let transport = FakeTransport()
        transport.answers["POST /v1/support/tickets"] = (201, #"{"ticket_id":"tkt_0123456789abcdef","status":"waiting","created_at":1}"#)
        transport.answers["POST /v1/support/tickets/tkt_0123456789abcdef/attachments"] = (201, #"{"id":"att_0123456789abcdef","content_type":"image/jpeg","bytes":3,"at":1}"#)
        let tokens = MemorySupportTokenStore()
        let client = SupportClient(publicKey: "pk_KUdMabcdefghijklmnopqrst", installID: install, uid: { "user-1" }, transport: transport, tokens: tokens)

        let id = try await client.submit(SupportRequest(category: .billing, subject: "  ", body: " 解約したい \n", email: "", images: [SupportImage(data: Data([1, 2, 3]), contentType: "image/jpeg")]), context: context(), lang: "ja")
        #expect(id == "tkt_0123456789abcdef")

        let first = transport.requests[0]
        #expect(first.url?.absoluteString == "https://api.appgrowstack.com/v1/support/tickets")
        #expect(first.value(forHTTPHeaderField: "Authorization") == "Bearer pk_KUdMabcdefghijklmnopqrst")
        #expect(first.value(forHTTPHeaderField: "X-Support-Token") == nil)
        let body = try transport.json(0)
        #expect(Set(body.keys) == ["install_id", "uid", "owner_token", "lang", "category", "body", "context"])
        #expect(body["body"] as? String == "解約したい")
        #expect(body["category"] as? String == "billing")
        let token = try #require(body["owner_token"] as? String)
        #expect(token.count >= 32 && token.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" })
        #expect(tokens.load() == token)

        let ctx = try #require(body["context"] as? [String: Any])
        #expect(Set(ctx.keys) == ["platform", "app_version", "build", "os_version", "device_model", "channel", "is_premium", "screen", "recent_events", "campaigns_shown"])
        #expect(ctx["channel"] as? String == "appstore")
        let events = try #require(ctx["recent_events"] as? [[String: Any]])
        #expect(events.count == 20)
        #expect(events[0]["at"] as? Int == 1_700_000_000_000)
        #expect((events[0]["props"] as? [String: Any])?["streak_days"] as? Int == 3)
        #expect(((ctx["campaigns_shown"] as? [[String: Any]])?.first)?["set_version"] as? Int == 3)

        let upload = transport.requests[1]
        #expect(upload.url?.path() == "/v1/support/tickets/tkt_0123456789abcdef/attachments")
        #expect(upload.value(forHTTPHeaderField: "Content-Type") == "image/jpeg")
        #expect(upload.value(forHTTPHeaderField: "X-Support-Token") == token)
        #expect(upload.httpBody == Data([1, 2, 3]))
    }

    @Test func ticketsAreEmptyWithoutATokenAndReadWithIt() async throws {
        let transport = FakeTransport()
        transport.answers["GET /v1/support/tickets"] = (200, ticketJSON)
        let tokens = MemorySupportTokenStore()
        let client = SupportClient(publicKey: "pk_KUdMabcdefghijklmnopqrst", installID: install, transport: transport, tokens: tokens)
        #expect(try await client.tickets().isEmpty)
        #expect(transport.requests.isEmpty)

        tokens.save(String(repeating: "t", count: 40))
        let tickets = try await client.tickets()
        #expect(transport.requests[0].value(forHTTPHeaderField: "X-Support-Token") == String(repeating: "t", count: 40))
        #expect(tickets.first?.status == .answered)
        #expect(tickets.first?.latestReply?.body == "App Store で解約できます")
        #expect(tickets.first?.subject == nil)
        #expect(tickets.first?.updatedAt == Date(timeIntervalSince1970: 1_700_000_100))
    }

    @Test func errorsAreTyped() async throws {
        let transport = FakeTransport()
        transport.answers["POST /v1/support/tickets"] = (429, #"{"error":{"code":"rate_limited","message":"x"}}"#)
        transport.answers["POST /v1/support/tickets/tkt_ffffffffffffffff/messages"] = (404, #"{"error":{"code":"not_found","message":"x"}}"#)
        transport.answers["GET /v1/support/articles"] = (400, #"{"error":{"code":"invalid","message":"lang"}}"#)
        let client = SupportClient(publicKey: "pk_KUdMabcdefghijklmnopqrst", installID: install, transport: transport, tokens: MemorySupportTokenStore())
        await #expect(throws: SupportError.rateLimited) { try await client.submit(SupportRequest(category: .bug, body: "x"), context: context(), lang: "ja") }
        await #expect(throws: SupportError.notFound) { try await client.reply("x", to: "tkt_ffffffffffffffff") }
        await #expect(throws: SupportError.rejected(status: 400, code: "invalid", message: "lang")) { try await client.articles(lang: "ja") }
        await #expect(throws: SupportError.self) { try await client.uploadImage(SupportImage(data: Data(), contentType: "image/png"), ticketID: "tkt_x") }
    }

    @Test func articlesAskForTheLanguageAndUseStaging() async throws {
        let transport = FakeTransport()
        transport.answers["GET /v1/support/articles"] = (200, articlesJSON)
        let client = SupportClient(publicKey: "pk_KUdMabcdefghijklmnopqrst", installID: install, endpoint: SupportClient.stagingEndpoint, transport: transport, tokens: MemorySupportTokenStore())
        let articles = try await client.articles(lang: "zh-Hant")
        #expect(transport.requests[0].url?.absoluteString == "https://api-staging.appgrowstack.com/v1/support/articles?lang=zh-Hant")
        #expect(articles.map(\.slug) == ["cancel-subscription", "widget"])
    }
}

struct SupportContextTests {
    @Test func versionIsCutToThreeParts() {
        #expect(SupportContext.normalizedVersion("3.2") == "3.2")
        #expect(SupportContext.normalizedVersion("3.2.0.1") == "3.2.0")
        #expect(SupportContext.normalizedVersion("3.2-beta") == "0.0")
        #expect(SupportContext.normalizedVersion("") == "0.0")
    }

    @Test func currentFillsTheDevice() {
        let c = SupportContext.current(channel: .debug, isPremium: false, screen: String(repeating: "s", count: 80))
        #expect(!c.deviceModel.isEmpty)
        #expect(c.osVersion.split(separator: ".").count == 3)
        #expect(c.screen?.count == 64)
    }

    @Test func typedValuesKeepTheirType() throws {
        let data = try JSONEncoder().encode(["a": SupportValue.int(3), "b": .double(1.5), "c": .bool(true), "d": .string("x")])
        let back = try JSONDecoder().decode([String: SupportValue].self, from: data)
        #expect(back == ["a": .int(3), "b": .double(1.5), "c": .bool(true), "d": .string("x")])
    }
}

struct HelpSearchTests {
    let articles: [HelpArticle] = try! JSONDecoder().decode(ArticleList.self, from: Data(articlesJSON.utf8)).articles
    struct ArticleList: Decodable { let articles: [HelpArticle] }

    @Test func japaneseWithoutSpacesFindsTheArticle() {
        #expect(HelpSearch.search("サブスクを解約したいです", in: articles).map(\.slug) == ["cancel-subscription"])
        #expect(HelpSearch.search("ウィジェットが出ない", in: articles).first?.slug == "widget")
    }

    @Test func grammarAloneMatchesNothing() {
        #expect(HelpSearch.terms("解約したい") == ["約し", "解約"])
        #expect(HelpSearch.search("したい", in: articles).isEmpty)
        #expect(HelpSearch.search("", in: articles).isEmpty)
    }

    @Test func latinWordsIgnoreCase() {
        let en = [HelpArticle(slug: "restore", lang: "en", title: "Restore purchases", summary: "If Premium is missing after reinstalling.", url: URL(string: "https://x.com/en/help/restore/")!, updatedAt: .now)]
        #expect(HelpSearch.search("RESTORE my premium", in: en).count == 1)
        #expect(HelpSearch.search("widget", in: en).isEmpty)
    }
}

@MainActor
struct SupportCenterTests {
    @Test func refreshLoadsAndCountsUnreadUntilOpened() async throws {
        let transport = FakeTransport()
        transport.answers["GET /v1/support/tickets"] = (200, ticketJSON)
        transport.answers["GET /v1/support/articles"] = (200, articlesJSON)
        let defaults = UserDefaults(suiteName: "support-tests-\(UUID().uuidString)")!
        let client = SupportClient(publicKey: "pk_KUdMabcdefghijklmnopqrst", installID: install, transport: transport, tokens: MemorySupportTokenStore(token: String(repeating: "t", count: 40)))
        let center = SupportCenter(client: client, lang: "ja", context: { _ in context() }, seen: defaults)
        await center.refresh()
        #expect(center.tickets.count == 1)
        #expect(center.articles.count == 2)
        #expect(center.unreadCount == 1)
        center.markRead(center.tickets[0])
        #expect(center.unreadCount == 0)
        #expect(center.suggestions(for: "解約の方法").first?.slug == "cancel-subscription")
    }

    @Test func refreshKeepsTheErrorQuietly() async {
        let client = SupportClient(publicKey: "pk_KUdMabcdefghijklmnopqrst", installID: install, transport: FakeTransport(), tokens: MemorySupportTokenStore(token: String(repeating: "t", count: 40)))
        let center = SupportCenter(client: client, lang: "ja", context: { _ in context() })
        await center.refresh()
        #expect(center.lastError != nil)
        #expect(center.tickets.isEmpty)
    }
}

struct SupportImageTests {
    @Test func reencodesAsJPEGAndRejectsNonImages() throws {
        // 2×2 の PNG
        let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGP8z8DAwMDAxMDAwMDAAAANHQEDasKb6QAAAABJRU5ErkJggg==")!
        let jpeg = try #require(SupportImage.jpeg(from: png))
        #expect(jpeg.contentType == "image/jpeg")
        #expect(jpeg.data.starts(with: [0xFF, 0xD8]))
        #expect(SupportImage.jpeg(from: Data("not an image".utf8)) == nil)
    }
}
