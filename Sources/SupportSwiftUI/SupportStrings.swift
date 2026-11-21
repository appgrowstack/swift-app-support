import SupportCore

/// Every word the views show. Nine languages are built in (English, Japanese, Korean, Simplified and
/// Traditional Chinese, Spanish, Brazilian Portuguese, German, French); ``forLanguage(_:)`` picks one.
/// For another language, start from `.english` and replace the fields from your app's own string catalog.
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

    /// English.
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

    /// Japanese (`ja`).
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

    /// Korean (`ko`).
    public static let korean = SupportStrings(
        formTitle: "문의하기",
        category: "문의 유형",
        categoryNames: [.bug: "제대로 작동하지 않아요", .billing: "구독·결제", .account: "계정·데이터", .question: "사용 방법", .request: "아이디어·요청", .other: "기타"],
        subject: "제목(선택)",
        body: "내용",
        bodyPlaceholder: "무슨 일이 있었는지, 어떻게 되길 바랐는지 적어 주세요",
        email: "이메일(선택)",
        emailFooter: "답변은 앱 안으로 도착해요. 이메일로도 받고 싶을 때만 적어 주세요.",
        images: "스크린샷",
        addImages: "스크린샷 첨부",
        send: "보내기",
        sending: "보내는 중…",
        sent: "보냈어요",
        sentDetail: "개발자가 모든 메시지를 읽어요. 답변은 앱 안의 이 화면에 도착해요.",
        maybeHelpful: "이 도움말로 해결될 수도 있어요",
        contextFooter: "더 빨리 답할 수 있도록 앱 버전, 기기, 구독 상태를 함께 보내요.",
        requestsTitle: "문의 내역",
        noRequests: "아직 보낸 문의가 없어요.",
        statusNames: [.waiting: "답변을 기다려요", .answered: "답변이 왔어요", .resolved: "해결됐어요"],
        replyPlaceholder: "답장 쓰기",
        replySend: "보내기",
        helpTitle: "도움말",
        searchHelp: "도움말 검색",
        noHelpMatches: "맞는 도움말이 없어요.",
        contact: "문의하기",
        failed: "보내지 못했어요. 연결 상태를 확인하고 다시 보내 주세요.",
        rateLimited: "연달아 보내셨어요. 잠시 후에 다시 보내 주세요."
    )

    /// Simplified Chinese (`zh-Hans`).
    public static let chineseSimplified = SupportStrings(
        formTitle: "联系我们",
        category: "类型",
        categoryNames: [.bug: "功能无法正常使用", .billing: "订阅或付款", .account: "账号或数据", .question: "使用方法", .request: "建议或需求", .other: "其他"],
        subject: "标题（可选）",
        body: "内容",
        bodyPlaceholder: "请写下发生了什么，以及你希望的结果",
        email: "邮箱（可选）",
        emailFooter: "回复会显示在应用内。想同时通过邮件收到回复时再填写。",
        images: "截图",
        addImages: "添加截图",
        send: "发送",
        sending: "正在发送…",
        sent: "已发送",
        sentDetail: "开发者会阅读每一条消息。回复会显示在应用的这个页面。",
        maybeHelpful: "这些文章也许能直接解答",
        contextFooter: "为了更快回复，会一并发送应用版本、设备和订阅状态。",
        requestsTitle: "我的反馈",
        noRequests: "还没有反馈。",
        statusNames: [.waiting: "等待回复", .answered: "已回复", .resolved: "已解决"],
        replyPlaceholder: "写回复",
        replySend: "发送",
        helpTitle: "帮助",
        searchHelp: "搜索帮助",
        noHelpMatches: "没有相关文章。",
        contact: "联系我们",
        failed: "发送失败。请检查网络后再试一次。",
        rateLimited: "你最近发送了多条消息。请稍等片刻再试。"
    )

    /// Traditional Chinese (`zh-Hant`), in Taiwan's words.
    public static let chineseTraditional = SupportStrings(
        formTitle: "聯絡我們",
        category: "類型",
        categoryNames: [.bug: "功能無法正常使用", .billing: "訂閱或付款", .account: "帳號或資料", .question: "使用方法", .request: "建議或需求", .other: "其他"],
        subject: "主旨（選填）",
        body: "內容",
        bodyPlaceholder: "請寫下發生了什麼事，以及你原本期待的結果",
        email: "電子郵件（選填）",
        emailFooter: "回覆會顯示在 App 內。如果也想用電子郵件收到回覆，再填寫即可。",
        images: "截圖",
        addImages: "新增截圖",
        send: "傳送",
        sending: "正在傳送…",
        sent: "已傳送",
        sentDetail: "開發者會閱讀每一則訊息。回覆會顯示在 App 的這個畫面。",
        maybeHelpful: "這些文章或許能馬上解答",
        contextFooter: "為了更快回覆，會一併傳送 App 版本、裝置和訂閱狀態。",
        requestsTitle: "我的訊息",
        noRequests: "還沒有訊息。",
        statusNames: [.waiting: "等待回覆", .answered: "已回覆", .resolved: "已解決"],
        replyPlaceholder: "輸入回覆",
        replySend: "傳送",
        helpTitle: "說明",
        searchHelp: "搜尋說明",
        noHelpMatches: "找不到相關文章。",
        contact: "聯絡我們",
        failed: "傳送失敗。請檢查網路後再試一次。",
        rateLimited: "你最近傳送了多則訊息。請稍候再試。"
    )

    /// Spanish (`es`), neutral Latin American.
    public static let spanish = SupportStrings(
        formTitle: "Contáctanos",
        category: "Tema",
        categoryNames: [.bug: "Algo no funciona", .billing: "Suscripción o pago", .account: "Cuenta o datos", .question: "Cómo se usa", .request: "Idea o sugerencia", .other: "Otro"],
        subject: "Asunto (opcional)",
        body: "Mensaje",
        bodyPlaceholder: "¿Qué pasó y qué esperabas que pasara?",
        email: "Correo electrónico (opcional)",
        emailFooter: "Las respuestas llegan a la app. Escribe tu correo solo si también quieres recibirlas por correo.",
        images: "Capturas de pantalla",
        addImages: "Agregar capturas",
        send: "Enviar",
        sending: "Enviando…",
        sent: "Enviado",
        sentDetail: "El desarrollador lee todos los mensajes. La respuesta llegará aquí, en la app.",
        maybeHelpful: "Estos artículos podrían resolverlo ahora mismo",
        contextFooter: "Para ayudarte más rápido, se envían la versión de la app, el dispositivo y el estado de tu suscripción.",
        requestsTitle: "Tus mensajes",
        noRequests: "Aún no hay mensajes.",
        statusNames: [.waiting: "Esperando respuesta", .answered: "Respondido", .resolved: "Resuelto"],
        replyPlaceholder: "Escribe una respuesta",
        replySend: "Enviar",
        helpTitle: "Ayuda",
        searchHelp: "Buscar en la ayuda",
        noHelpMatches: "No hay artículos que coincidan.",
        contact: "Contáctanos",
        failed: "No se pudo enviar. Revisa tu conexión e inténtalo de nuevo.",
        rateLimited: "Enviaste varios mensajes hace poco. Espera un momento e inténtalo de nuevo."
    )

    /// Brazilian Portuguese (`pt-BR`).
    public static let portugueseBrazil = SupportStrings(
        formTitle: "Fale conosco",
        category: "Tema",
        categoryNames: [.bug: "Algo não está funcionando", .billing: "Assinatura ou pagamento", .account: "Conta ou dados", .question: "Como usar", .request: "Ideia ou sugestão", .other: "Outro"],
        subject: "Assunto (opcional)",
        body: "Mensagem",
        bodyPlaceholder: "O que aconteceu e o que você esperava?",
        email: "E-mail (opcional)",
        emailFooter: "As respostas chegam no app. Informe um e-mail só se quiser receber as respostas por e-mail também.",
        images: "Capturas de tela",
        addImages: "Anexar capturas",
        send: "Enviar",
        sending: "Enviando…",
        sent: "Enviado",
        sentDetail: "O desenvolvedor lê todas as mensagens. A resposta vai chegar aqui, no app.",
        maybeHelpful: "Esses artigos podem resolver na hora",
        contextFooter: "Para ajudar mais rápido, enviamos junto a versão do app, o aparelho e o status da sua assinatura.",
        requestsTitle: "Suas mensagens",
        noRequests: "Ainda não há mensagens.",
        statusNames: [.waiting: "Aguardando resposta", .answered: "Respondido", .resolved: "Resolvido"],
        replyPlaceholder: "Escreva uma resposta",
        replySend: "Enviar",
        helpTitle: "Ajuda",
        searchHelp: "Buscar na ajuda",
        noHelpMatches: "Nenhum artigo encontrado.",
        contact: "Fale conosco",
        failed: "Não foi possível enviar. Verifique sua conexão e tente de novo.",
        rateLimited: "Você enviou várias mensagens há pouco. Aguarde um pouco e tente de novo."
    )

    /// German (`de`).
    public static let german = SupportStrings(
        formTitle: "Kontakt",
        category: "Thema",
        categoryNames: [.bug: "Etwas funktioniert nicht", .billing: "Abo oder Zahlung", .account: "Konto oder Daten", .question: "Frage zur Nutzung", .request: "Idee oder Wunsch", .other: "Sonstiges"],
        subject: "Betreff (optional)",
        body: "Nachricht",
        bodyPlaceholder: "Was ist passiert, und was hast du erwartet?",
        email: "E-Mail (optional)",
        emailFooter: "Antworten erscheinen in der App. Gib eine E-Mail-Adresse nur an, wenn du die Antworten auch per E-Mail bekommen möchtest.",
        images: "Screenshots",
        addImages: "Screenshots anhängen",
        send: "Senden",
        sending: "Wird gesendet…",
        sent: "Gesendet",
        sentDetail: "Der Entwickler liest jede Nachricht. Die Antwort erscheint hier in der App.",
        maybeHelpful: "Diese Artikel helfen dir vielleicht sofort",
        contextFooter: "Damit wir schneller helfen können, werden App-Version, Gerät und Abo-Status mitgeschickt.",
        requestsTitle: "Deine Nachrichten",
        noRequests: "Noch keine Nachrichten.",
        statusNames: [.waiting: "Wartet auf Antwort", .answered: "Beantwortet", .resolved: "Gelöst"],
        replyPlaceholder: "Antwort schreiben",
        replySend: "Senden",
        helpTitle: "Hilfe",
        searchHelp: "Hilfe durchsuchen",
        noHelpMatches: "Keine passenden Artikel.",
        contact: "Kontakt",
        failed: "Senden fehlgeschlagen. Prüfe deine Verbindung und versuche es noch einmal.",
        rateLimited: "Du hast gerade mehrere Nachrichten gesendet. Warte kurz und versuche es dann noch einmal."
    )

    /// French (`fr`).
    public static let french = SupportStrings(
        formTitle: "Nous contacter",
        category: "Sujet",
        categoryNames: [.bug: "Quelque chose ne fonctionne pas", .billing: "Abonnement ou paiement", .account: "Compte ou données", .question: "Comment faire\u{202F}?", .request: "Idée ou suggestion", .other: "Autre"],
        subject: "Objet (facultatif)",
        body: "Message",
        bodyPlaceholder: "Qu'est-ce qui s'est passé, et qu'attendais-tu\u{202F}?",
        email: "E-mail (facultatif)",
        emailFooter: "Les réponses arrivent dans l'app. Indique ton adresse e-mail seulement si tu veux aussi recevoir les réponses par e-mail.",
        images: "Captures d'écran",
        addImages: "Ajouter des captures",
        send: "Envoyer",
        sending: "Envoi en cours…",
        sent: "Envoyé",
        sentDetail: "Le développeur lit chaque message. La réponse arrivera ici, dans l'app.",
        maybeHelpful: "Ces articles peuvent t'aider tout de suite",
        contextFooter: "Pour t'aider plus vite, la version de l'app, l'appareil et l'état de ton abonnement sont joints.",
        requestsTitle: "Tes messages",
        noRequests: "Aucun message pour l'instant.",
        statusNames: [.waiting: "En attente de réponse", .answered: "Réponse reçue", .resolved: "Résolu"],
        replyPlaceholder: "Écrire une réponse",
        replySend: "Envoyer",
        helpTitle: "Aide",
        searchHelp: "Rechercher dans l'aide",
        noHelpMatches: "Aucun article ne correspond.",
        contact: "Nous contacter",
        failed: "Envoi impossible. Vérifie ta connexion et réessaie.",
        rateLimited: "Tu as envoyé plusieurs messages récemment. Attends un peu avant de réessayer."
    )

    /// The built-in strings for a language code (`ja`, `zh-Hant`, `pt-BR`, `zh_TW`…). Chinese is
    /// Traditional for `Hant`, Taiwan, Hong Kong and Macau, Simplified otherwise. `.english` for any
    /// language that is not built in.
    public static func forLanguage(_ lang: String) -> SupportStrings {
        let parts = lang.lowercased().replacingOccurrences(of: "_", with: "-").split(separator: "-").map(String.init)
        switch parts.first ?? "" {
        case "ja": return .japanese
        case "ko": return .korean
        case "zh": return parts.dropFirst().contains { ["hant", "tw", "hk", "mo"].contains($0) } ? .chineseTraditional : .chineseSimplified
        case "es": return .spanish
        case "pt": return .portugueseBrazil
        case "de": return .german
        case "fr": return .french
        default: return .english
        }
    }
}
