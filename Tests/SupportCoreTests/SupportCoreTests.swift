import Foundation
@testable import SupportCore
import Testing

/// A transport with replies and screenshots that keeps what it was given.
final class FakeTransport: SupportTransport, HelpArticleSource, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var submitted: [(SupportRequest, SupportContext, String)] = []
    var capabilities = SupportCapabilities(replies: true, images: true)
    var ticketList: Result<[SupportTicket], SupportError> = .success([])
    var articleList: [HelpArticle] = []

    func submit(_ request: SupportRequest, context: SupportContext, lang: String) async throws -> String {
        lock.withLock { submitted.append((request, context, lang)) }
        return "tkt_0123456789abcdef"
    }

    func tickets() async throws -> [SupportTicket] { try ticketList.get() }

    func reply(_ body: String, to ticketID: String) async throws -> SupportMessage {
        SupportMessage(id: "msg_1", from: .user, body: body, at: .now)
    }

    func articles(lang: String) async throws -> [HelpArticle] { articleList }
}

let ticketJSON = #"{"tickets":[{"ticket_id":"tkt_0123456789abcdef","status":"answered","subject":null,"created_at":1700000000000,"updated_at":1700000100000,"messages":[{"id":"msg_0123456789abcdef","from":"user","body":"解約したい","at":1700000000000},{"id":"msg_fedcba9876543210","from":"support","body":"App Store で解約できます","at":1700000100000}]}]}"#
let articlesJSON = #"{"articles":[{"slug":"cancel-subscription","lang":"ja","title":"サブスクリプションを解約する","summary":"iPhoneはApp Store、AndroidはGoogle Playで解約します。","url":"https://gohobishukan.com/help/cancel-subscription/","tags":["billing"],"updated_at":1},{"slug":"widget","lang":"ja","title":"ウィジェットを置く","summary":"ホーム画面にウィジェットを置きます。","url":"https://gohobishukan.com/help/widget/","tags":[],"updated_at":1}]}"#

func context() -> SupportContext {
    SupportContext(
        appVersion: "3.2.0", build: "120", osVersion: "26.1", deviceModel: "iPhone17,1", channel: .appStore, isPremium: true, screen: "settings",
        recentEvents: (0 ..< 25).map { _ in SupportRecentEvent(name: "habit_achieved", at: Date(timeIntervalSince1970: 1_700_000_000), props: ["streak_days": 3, "category": "health"]) },
        campaignsShown: [SupportCampaignShown(campaign: "trial-offer", setVersion: 3, at: Date(timeIntervalSince1970: 1_700_000_000))]
    )
}

final class OpenedURLs: @unchecked Sendable {
    private let lock = NSLock()
    private var urls: [URL] = []
    var all: [URL] { lock.withLock { urls } }
    func add(_ url: URL) { lock.withLock { urls.append(url) } }
}

struct MailSupportTransportTests {
    @Test func opensAMailWithTheTextAndTheContext() async throws {
        let opened = OpenedURLs()
        let mail = MailSupportTransport(to: "support@example.com") { url in opened.add(url); return true }
        #expect(mail.capabilities == SupportCapabilities(replies: false, images: false))

        var ctx = context()
        ctx.sessionID = "ses_0123456789abcdef"
        let id = try await mail.submit(SupportRequest(category: .billing, subject: "  ", body: " 解約したい \n"), context: ctx, lang: "ja")
        #expect(id == "mail")
        let url = try #require(opened.all.first)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.scheme == "mailto")
        #expect(components.path == "support@example.com")
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(items["subject"] == "[billing]")
        let body = try #require(items["body"])
        #expect(body.hasPrefix("解約したい\n\n---\n"))
        #expect(body.contains("App: 3.2.0 (120) appstore"))
        #expect(body.contains("Device: ios 26.1 iPhone17,1"))
        #expect(body.contains("Premium: yes"))
        #expect(body.contains("Screen: settings"))
        #expect(body.contains("Session: ses_0123456789abcdef"))
        #expect(body.contains("Campaigns: trial-offer"))
    }

    @Test func noMailAppAndNoReplies() async throws {
        let mail = MailSupportTransport(to: "support@example.com") { _ in false }
        await #expect(throws: SupportError.transport("no mail app")) { try await mail.submit(SupportRequest(category: .bug, body: "x"), context: context(), lang: "ja") }
        #expect(try await mail.tickets().isEmpty)
        await #expect(throws: SupportError.unsupported) { try await mail.reply("x", to: "tkt_x") }
    }
}

struct BundledHelpArticlesTests {
    @Test func picksTheLanguageThenTheBaseThenEnglish() async throws {
        let en = #"{"slug":"widget","lang":"en","title":"Add the widget","summary":"On the Home Screen.","url":"https://x.com/en/help/widget/","tags":[],"updated_at":1}"#
        let zh = #"{"slug":"widget","lang":"zh","title":"小组件","summary":"主屏幕。","url":"https://x.com/zh/help/widget/","tags":[],"updated_at":1}"#
        let bundled = BundledHelpArticles(data: Data(#"{"articles":[\#(en),\#(zh)]}"#.utf8))
        #expect(try await bundled.articles(lang: "zh-Hans").map(\.lang) == ["zh"])
        #expect(try await bundled.articles(lang: "en").map(\.lang) == ["en"])
        #expect(try await bundled.articles(lang: "ja").map(\.lang) == ["en"])
        #expect(try await BundledHelpArticles(data: Data("nope".utf8)).articles(lang: "ja").isEmpty)
        #expect(try await BundledHelpArticles(resource: "missing").articles(lang: "ja").isEmpty)
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
    let tickets: [SupportTicket] = try! JSONDecoder().decode(TicketList.self, from: Data(ticketJSON.utf8)).tickets
    struct TicketList: Decodable { let tickets: [SupportTicket] }

    @Test func refreshLoadsAndCountsUnreadUntilOpened() async throws {
        let transport = FakeTransport()
        transport.ticketList = .success(tickets)
        transport.articleList = HelpSearchTests().articles
        let defaults = UserDefaults(suiteName: "support-tests-\(UUID().uuidString)")!
        let center = SupportCenter(transport: transport, lang: "ja", context: { _ in context() }, seen: defaults)
        await center.refresh()
        #expect(center.tickets.count == 1)
        #expect(center.articles.count == 2)
        #expect(center.unreadCount == 1)
        center.markRead(center.tickets[0])
        #expect(center.unreadCount == 0)
        #expect(center.suggestions(for: "解約の方法").first?.slug == "cancel-subscription")
    }

    @Test func refreshKeepsTheErrorQuietly() async {
        let transport = FakeTransport()
        transport.ticketList = .failure(.transport("offline"))
        let center = SupportCenter(transport: transport, lang: "ja", context: { _ in context() })
        await center.refresh()
        #expect(center.lastError == .transport("offline"))
        #expect(center.tickets.isEmpty)
    }

    @Test func withoutRepliesNoListIsReadAndScreenshotsAreDropped() async throws {
        let transport = FakeTransport()
        transport.capabilities = SupportCapabilities(replies: false, images: false)
        transport.ticketList = .failure(.transport("must not be read"))
        let center = SupportCenter(transport: transport, articles: BundledHelpArticles(articles: HelpSearchTests().articles), lang: "ja", context: { _ in context() })
        await center.refresh()
        #expect(center.lastError == nil)
        #expect(center.articles.count == 2)
        _ = try await center.submit(SupportRequest(category: .bug, body: "x", images: [SupportImage(data: Data([1]), contentType: "image/jpeg")]), screen: "settings")
        #expect(transport.submitted.first?.0.images.isEmpty == true)
        #expect(transport.submitted.first?.2 == "ja")
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
