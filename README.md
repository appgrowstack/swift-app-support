English | [日本語](./README.ja.md)

# swift-app-support

In-app support for a small app: a contact form that attaches what the developer needs to answer,
the person's own requests and replies, and help articles to search before writing. Replies are
drafted on the server from the product's help articles and reviewed by the developer before they
are sent, so the person gets an answer inside the app instead of leaving a one-star review.

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

> Developed in a private monorepo and copied here one way. Issues are welcome; pull requests are
> not accepted.

## Features

- **Answers before the request.** While the person types, the form shows help articles that may
  already answer it (`HelpSearch` works for Japanese and other languages without spaces)
- **Context attached.** App version, build, OS, device model, channel, subscription state, the
  screen the form came from, recent events (typed) and in-app campaigns shown. Nothing the person
  typed elsewhere in the app
- **Replies inside the app.** Each install keeps a random owner token in the Keychain; with it the
  app reads its own requests and replies. No account needed. `SupportCenter.unreadCount` gives
  the badge
- **Screenshots.** Up to four per request, re-encoded as JPEG under 5 MB with metadata removed
- **No dependencies.** Foundation, Security, ImageIO and Observation; SwiftUI only in `SupportSwiftUI`

## Quick Start

```swift
import SupportCore
import SupportSwiftUI

let support = SupportCenter(
    client: SupportClient(publicKey: "pk_…", installID: analytics.installID, uid: { auth.uid }),
    lang: "ja",
    context: { screen in
        SupportContext.current(
            channel: .appStore,
            isPremium: premium.isPremium,
            screen: screen,
            recentEvents: analytics.recent(20).map { SupportRecentEvent(name: $0.name, at: $0.at, props: $0.props) }
        )
    }
)

// Settings → Help
NavigationLink("Help") { HelpArticlesView(center: support, screen: "settings") }
    .badge(support.unreadCount)

// Or straight to the form, e.g. from the subscription screen
SupportFormView(center: support, screen: "paywall", category: .billing)
```

Call `await support.refresh()` on return to the foreground to pick up replies. The server also
sends a push notification (campaign `support_reply`) when the developer replies, if the product uses
appgrowstack notifications.

## Strings

`SupportStrings.english` and `.japanese` are built in. For other languages, copy `.english` and
replace the fields from your app's string catalog, then pass it as `strings:`.

## Requirements

- iOS 17+ / macOS 14+
- Swift 6.2+

## License

MIT
