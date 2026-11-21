English | [日本語](./README.ja.md)

# swift-app-support

In-app support for a small app: a contact form that attaches what the developer needs to answer,
and help articles to search before writing. Requests go to a transport you choose: a mail to your
support address, or a support server that also brings the person's requests and replies into the app.

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

> Developed in a private monorepo and copied here one way. Issues are welcome; pull requests are
> not accepted.

## Features

- **Answers before the request.** While the person types, the form shows help articles that may
  already answer it (`HelpSearch` works for Japanese and other languages without spaces)
- **Context attached.** App version, build, OS, device model, channel, subscription state, the
  screen the form came from, the recorded session, recent events (typed) and in-app campaigns
  shown. Nothing the person typed elsewhere in the app
- **Works on its own.** `MailSupportTransport` opens a mail to you with the context as readable
  lines below the text; `BundledHelpArticles` reads the articles shipped in the app
- **A transport decides the rest.** `SupportTransport` says what it can do (`capabilities`): with
  replies, the app lists the person's requests and `SupportCenter.unreadCount` gives the badge; with
  images, the form takes up to four screenshots, re-encoded as JPEG under 5 MB with metadata removed.
  The views hide what the transport cannot do
- **No dependencies.** Foundation, ImageIO and Observation (UIKit or AppKit only to open the mail);
  SwiftUI only in `SupportSwiftUI`

## Quick Start

```swift
import SupportCore
import SupportSwiftUI

let support = SupportCenter(
    transport: MailSupportTransport(to: "support@example.com"),
    articles: BundledHelpArticles(resource: "help"),      // help.json in the app bundle
    lang: "ja",
    context: { screen in
        SupportContext.current(channel: .appStore, isPremium: premium.isPremium, screen: screen)
    }
)

// Settings → Help
NavigationLink("Help") { HelpArticlesView(center: support, screen: "settings") }
    .badge(support.unreadCount)

// Or straight to the form, e.g. from the subscription screen
SupportFormView(center: support, screen: "paywall", category: .billing)
```

With a transport that has replies, call `await support.refresh()` on return to the foreground to
pick up replies.

## Strings

`SupportStrings.english` and `.japanese` are built in. For other languages, copy `.english` and
replace the fields from your app's string catalog, then pass it as `strings:`.

## Requirements

- iOS 17+ / macOS 14+
- Swift 6.2+

## License

MIT
