[English](./README.md) | 日本語

# swift-app-support

小さなアプリの中のサポート。開発者が答えるのに要る文脈を添える問い合わせのフォーム、自分の問い合わせと返事の一覧、書く前に探せるヘルプの記事。返事はサーバーが製品のヘルプの記事から下書きし、開発者が確かめてから送ります。利用者は★1のレビューを書く前に、アプリの中で答えを受け取れます。

> 非公開のモノリポで作り、ここへ片方向に写しています。Issue は歓迎します。Pull Request は受け付けていません。

## できること

- **書く前に答える。** 入力の途中で、もう答えている記事をフォームに出す（`HelpSearch` は日本語のような空白の無い言葉も探せる）
- **文脈を自動で添える。** アプリのバージョン・ビルド・OS・端末・配布元・Premium か・フォームを開いた画面・直近の出来事（型のまま）・出したキャンペーン。アプリの中で利用者が書いた文は入れない
- **返事はアプリの中で読める。** install ごとに乱数の鍵（owner token）を Keychain に置き、それで自分の問い合わせと返事を読む。アカウントは要らない。`SupportCenter.unreadCount` をバッジに使う
- **スクリーンショット。** 1件に4枚まで。メタデータを外した5MB 以下の JPEG にして送る
- **依存なし。** Foundation・Security・ImageIO・Observation。SwiftUI は `SupportSwiftUI` だけ

## 使い方

```swift
import SupportCore
import SupportSwiftUI

let support = SupportCenter(
    client: SupportClient(publicKey: "pk_…", installID: analytics.installID, uid: { auth.uid }),
    lang: "ja",
    context: { screen in
        SupportContext.current(channel: .appStore, isPremium: premium.isPremium, screen: screen)
    }
)

NavigationLink("ヘルプ") { HelpArticlesView(center: support, screen: "settings") }
    .badge(support.unreadCount)
```

前面に戻ったら `await support.refresh()` で返事を読み直します。製品が appgrowstack の通知を使っていれば、返事を送ったときにサーバーが通知（施策 `support_reply`）も送ります。

## 文言

`SupportStrings.english` と `.japanese` を持っています。ほかの言語は `.english` を写し、アプリの文字列から差し替えて `strings:` に渡します。

## ライセンス

MIT
