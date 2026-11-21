[English](./README.md) | 日本語

# swift-app-support

小さなアプリの中のサポート。開発者が答えるのに要る文脈を添える問い合わせのフォームと、書く前に探せるヘルプの記事。問い合わせは選んだ送り先（transport）へ行きます。サポートのアドレスへのメールか、利用者の問い合わせと返事もアプリの中に持ってくるサポートのサーバーです。

> 非公開のモノリポで作り、ここへ片方向に写しています。Issue は歓迎します。Pull Request は受け付けていません。

## できること

- **書く前に答える。** 入力の途中で、もう答えている記事をフォームに出す（`HelpSearch` は日本語のような空白の無い言葉も探せる）
- **文脈を自動で添える。**アプリのバージョン・ビルド・OS・端末・配布元・Premiumか・フォームを開いた画面・記録したセッション・直近の出来事（型のまま）・出したキャンペーン。アプリの中で利用者が書いた文は入れない
- **単体で動く。** `MailSupportTransport`は本文の下に文脈を読める行で付けたメールを開く。`BundledHelpArticles`はアプリに同梱した記事を読む
- **できることはtransportが決める。** `SupportTransport`はできることを`capabilities`で返す。返事があれば自分の問い合わせの一覧を出し、`SupportCenter.unreadCount`をバッジに使える。画像があれば1件に4枚まで、メタデータを外した5MB以下のJPEGにして送る。できない物は画面が隠す
- **依存なし。** Foundation・ImageIO・Observation（メールを開くのにUIKitかAppKit）。SwiftUIは`SupportSwiftUI`だけ

## 使い方

```swift
import SupportCore
import SupportSwiftUI

let support = SupportCenter(
    transport: MailSupportTransport(to: "support@example.com"),
    articles: BundledHelpArticles(resource: "help"),      // アプリに同梱した help.json
    lang: "ja",
    context: { screen in
        SupportContext.current(channel: .appStore, isPremium: premium.isPremium, screen: screen)
    }
)

NavigationLink("ヘルプ") { HelpArticlesView(center: support, screen: "settings") }
    .badge(support.unreadCount)
```

返事を持つtransportなら、前面に戻ったら`await support.refresh()`で返事を読み直します。

## 文言

`SupportStrings.english` と `.japanese` を持っています。ほかの言語は `.english` を写し、アプリの文字列から差し替えて `strings:` に渡します。

## ライセンス

MIT
