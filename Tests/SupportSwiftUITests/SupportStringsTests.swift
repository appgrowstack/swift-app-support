import SupportCore
import SupportSwiftUI
import Testing

struct SupportStringsTests {
    static let builtIn: [(String, SupportStrings)] = [
        ("en", .english), ("ja", .japanese), ("ko", .korean), ("zh-Hans", .chineseSimplified),
        ("zh-Hant", .chineseTraditional), ("es", .spanish), ("pt-BR", .portugueseBrazil), ("de", .german), ("fr", .french),
    ]

    @Test func picksTheLanguageFromItsCode() {
        let picks: [(String, String)] = [
            ("ja", "お問い合わせ"), ("ja-JP", "お問い合わせ"), ("ko", "문의하기"), ("zh-Hans", "联系我们"), ("zh", "联系我们"),
            ("zh-Hant", "聯絡我們"), ("zh_TW", "聯絡我們"), ("zh-HK", "聯絡我們"), ("zh-Hant-TW", "聯絡我們"),
            ("es-MX", "Contáctanos"), ("pt-BR", "Fale conosco"), ("de", "Kontakt"), ("fr-CA", "Nous contacter"),
            ("en", "Contact us"), ("it", "Contact us"), ("", "Contact us"),
        ]
        for (lang, title) in picks {
            #expect(SupportStrings.forLanguage(lang).formTitle == title, "\(lang)")
        }
    }

    @Test func everyLanguageNamesEveryCategoryAndStatus() {
        for (lang, strings) in Self.builtIn {
            #expect(Set(strings.categoryNames.keys) == Set(SupportCategory.allCases), "\(lang)")
            #expect(Set(strings.statusNames.keys) == [.waiting, .answered, .resolved], "\(lang)")
            var words: [String] = [strings.formTitle, strings.category, strings.subject, strings.body, strings.bodyPlaceholder,
                         strings.email, strings.emailFooter, strings.images, strings.addImages, strings.send, strings.sending,
                         strings.sent, strings.sentDetail, strings.maybeHelpful, strings.contextFooter, strings.requestsTitle,
                         strings.noRequests, strings.replyPlaceholder, strings.replySend, strings.helpTitle, strings.searchHelp,
                         strings.noHelpMatches, strings.contact, strings.failed, strings.rateLimited]
            words += strings.categoryNames.values
            words += strings.statusNames.values
            #expect(words.allSatisfy { !$0.isEmpty }, "\(lang)")
            if lang != "en" { #expect(strings.formTitle != SupportStrings.english.formTitle, "\(lang)") }
        }
    }
}
