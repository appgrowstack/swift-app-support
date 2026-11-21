# swift-app-support

小さなアプリにアプリの中のサポートを足す。答えるのに要る情報を添える問い合わせのフォームと、書く前に探せるヘルプの記事。

[English](./README.md)

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

問い合わせは選んだtransportへ送ります。サポートのアドレスへのメールか、利用者の問い合わせと返事もアプリの中に持ってくるサポートのサーバーです。

## 機能

- **書く前に答える。** 入力の途中で、もう答えになっている記事をフォームに出します（`HelpSearch` は日本語のような空白の無い言葉も探せます）
- **情報を添える。** アプリのバージョン・ビルド・OS・端末のモデル・配布元・購読の状態・フォームを開いた画面・記録したセッション・直近の出来事（型のまま）・出したキャンペーン。アプリのほかの所で利用者が書いた文は入れません
- **単体で動く。** `MailSupportTransport` は本文の下に情報を読める行で付けたメールを開きます。`BundledHelpArticles` はアプリに同梱した記事を読みます
- **できることはtransportが決める。** `SupportTransport` はできることを `capabilities` で返します。返事があれば利用者の問い合わせの一覧を出し、`SupportCenter.unreadCount` をバッジに使えます。画像があればフォームでスクリーンショットを4枚まで受け、メタデータを外した5MB以下のJPEGにします。できない物は画面に出しません
- **9つの言語を入れてある。** 画面の文言は英語・日本語・韓国語・簡体字・繁体字・スペイン語・ブラジルのポルトガル語・ドイツ語・フランス語。`SupportStrings.forLanguage` が `SupportCenter.lang` から選びます。ほかの言語は自分の `SupportStrings` を渡します
- **外部の依存なし。** Foundation・ImageIO・Observation（メールを開くときだけUIKitかAppKit）。SwiftUIは `SupportSwiftUI` の中だけです

### 文言

`SupportStrings.english` と `.japanese` を持っていて、`SupportStrings.forLanguage(_:)` がそのどちらかを選びます。
ほかの言語は `.english` をコピーし、アプリの文字列のカタログから項目を差し替えて `strings:` に渡します。

## はじめに

```swift
import SupportCore
import SupportSwiftUI
import SwiftUI

@MainActor let support = SupportCenter(
    transport: MailSupportTransport(to: "support@example.com"),
    articles: BundledHelpArticles(resource: "help"),      // help.json in the app bundle
    lang: "en",
    context: { screen in
        SupportContext.current(channel: .appStore, isPremium: false, screen: screen)
    }
)

struct SettingsView: View {
    var body: some View {
        List {
            NavigationLink("Help") { HelpArticlesView(center: support, screen: "settings") }
                .badge(support.unreadCount)
            // Or straight to the form, e.g. from the subscription screen
            NavigationLink("Contact us") {
                SupportFormView(center: support, screen: "settings", category: .billing)
            }
        }
    }
}
```

返事のあるtransportなら、前面に戻ったときに `await support.refresh()` を呼んで新しい返事を読みます。

### サーバーにつなぐ

このパッケージは単体で使えます。サーバーにつなぐときは、このパッケージで送り先を書く代わりに、コネクターのパッケージ [swift-appgrowstack](https://github.com/appgrowstack/swift-appgrowstack) の対応するtrait（SwiftPMのtraits）を有効にします。

## ドキュメント

APIの説明は `Sources/SupportCore` と `Sources/SupportSwiftUI` のシンボルのドキュメントです。
XcodeのProduct > Build Documentationで開けます。変更は [CHANGELOG.md](./CHANGELOG.md) にあります。

## 入れ方

```swift
.package(url: "https://github.com/appgrowstack/swift-app-support.git", .upToNextMinor(from: "0.3.0"))
```

```swift
.product(name: "SupportSwiftUI", package: "swift-app-support")
```

| プロダクト | 中身 | 依存 |
|---|---|---|
| `SupportCore` | `SupportCenter`・`SupportTransport`・`MailSupportTransport`・`SupportContext`・`BundledHelpArticles`・`HelpSearch` | Foundation・ImageIO・Observation |
| `SupportSwiftUI` | `SupportFormView`・`SupportTicketsView`・`SupportThreadView`・`HelpArticlesView`・`SupportStrings` | SwiftUI |

## 動く環境

- iOS 17.0+ / macOS 14.0+
- Swift 6.2+

## 入れ方

```swift
.package(url: "https://github.com/appgrowstack/swift-app-support.git", .upToNextMinor(from: "0.3.0"))
```

## ライセンス

MIT。[LICENSE](./LICENSE) を見てください。
