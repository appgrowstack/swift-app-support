import SupportCore

/// Every word the views show. English and Japanese are built in; for other languages, start from
/// `.english` and replace the fields from your app's own string catalog.
public struct SupportStrings: Sendable {
    public var formTitle: String
    public var category: String
    public var categoryNames: [SupportCategory: String]
    public var subject: String
    public var body: String
    public var bodyPlaceholder: String
    public var email: String
    public var emailFooter: String
    public var images: String
    public var addImages: String
    public var send: String
    public var sending: String
    public var sent: String
    public var sentDetail: String
    public var maybeHelpful: String
    public var contextFooter: String
    public var requestsTitle: String
    public var noRequests: String
    public var statusNames: [SupportTicketStatus: String]
    public var replyPlaceholder: String
    public var replySend: String
    public var helpTitle: String
    public var searchHelp: String
    public var noHelpMatches: String
    public var contact: String
    public var failed: String
    public var rateLimited: String

    public static let english = SupportStrings(
        formTitle: "Contact us",
        category: "Topic",
        categoryNames: [.bug: "Something isn't working", .billing: "Subscription or payment", .account: "Account or data", .question: "How do I…", .request: "Idea or request", .other: "Other"],
        subject: "Subject (optional)",
        body: "Message",
        bodyPlaceholder: "What happened, and what did you expect?",
        email: "Email (optional)",
        emailFooter: "Replies appear in the app. Add an email only if you also want them there.",
        images: "Screenshots",
        addImages: "Add screenshots",
        send: "Send",
        sending: "Sending…",
        sent: "Sent",
        sentDetail: "The developer reads every message. The reply will appear here in the app.",
        maybeHelpful: "These may answer it right away",
        contextFooter: "Your app version, device, and subscription status are attached so we can help faster.",
        requestsTitle: "Your messages",
        noRequests: "No messages yet.",
        statusNames: [.waiting: "Waiting for a reply", .answered: "Replied", .resolved: "Resolved"],
        replyPlaceholder: "Write a reply",
        replySend: "Send",
        helpTitle: "Help",
        searchHelp: "Search help",
        noHelpMatches: "No articles match.",
        contact: "Contact us",
        failed: "Couldn't send. Check your connection and try again.",
        rateLimited: "You've sent several messages recently. Please wait a little and try again."
    )

    public static let japanese = SupportStrings(
        formTitle: "お問い合わせ",
        category: "種類",
        categoryNames: [.bug: "うまく動かない", .billing: "サブスクリプション・お支払い", .account: "アカウント・データ", .question: "使い方", .request: "要望", .other: "そのほか"],
        subject: "件名（なくても大丈夫です）",
        body: "内容",
        bodyPlaceholder: "何が起きて、どうなってほしかったかを書いてください",
        email: "メールアドレス（なくても大丈夫です）",
        emailFooter: "返事はアプリの中に届きます。メールでも受け取りたいときだけ書いてください。",
        images: "スクリーンショット",
        addImages: "スクリーンショットを添える",
        send: "送る",
        sending: "送っています…",
        sent: "送りました",
        sentDetail: "開発者が全部読んでいます。返事はアプリのこの画面に届きます。",
        maybeHelpful: "この記事で解決するかもしれません",
        contextFooter: "早く答えられるよう、アプリのバージョン・端末・プレミアムかどうかを一緒に送ります。",
        requestsTitle: "お問い合わせの履歴",
        noRequests: "まだお問い合わせはありません。",
        statusNames: [.waiting: "返事を待っています", .answered: "返事が届きました", .resolved: "解決しました"],
        replyPlaceholder: "返事を書く",
        replySend: "送る",
        helpTitle: "ヘルプ",
        searchHelp: "ヘルプを検索",
        noHelpMatches: "当てはまる記事がありません。",
        contact: "お問い合わせ",
        failed: "送れませんでした。通信を確かめて、もう一度送ってください。",
        rateLimited: "続けて送られています。少し時間をおいてから送ってください。"
    )

    /// `.japanese` for `ja`, `.english` otherwise.
    public static func forLanguage(_ lang: String) -> SupportStrings {
        lang.hasPrefix("ja") ? .japanese : .english
    }
}
