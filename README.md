# swift-app-support

Add in-app support to a small app: a contact form that attaches what you need to answer, and help articles the person can search before writing.

[Japanese](./README.ja.md)

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

Requests go to a transport you choose: a mail to your support address, or a support server that
also brings the person's requests and replies into the app.

## Features

- **Answers before the request.** While the person types, the form shows help articles that may
  already answer it (`HelpSearch` also works for Japanese and other languages written without
  spaces)
- **Context attached.** App version, build, OS, device model, channel, subscription state, the
  screen the form came from, the recorded session, recent events (typed) and in-app campaigns
  shown. Nothing the person typed elsewhere in the app
- **Works on its own.** `MailSupportTransport` opens a mail to you with the context as readable
  lines below the text; `BundledHelpArticles` reads the articles shipped in the app
- **The transport decides the rest.** `SupportTransport` says what it can do (`capabilities`). With
  replies, the app lists the person's requests and `SupportCenter.unreadCount` gives the badge. With
  images, the form takes up to four screenshots, re-encoded as JPEG under 5 MB with metadata
  removed. The views hide what the transport cannot do
- **No dependencies.** Foundation, ImageIO and Observation (UIKit or AppKit only to open the mail);
  SwiftUI only in `SupportSwiftUI`

### Strings

`SupportStrings.english` and `.japanese` are built in, and `SupportStrings.forLanguage(_:)` picks one
of them. For other languages, copy `.english`, replace the fields from your app's string catalog,
and pass it as `strings:`.

## Quick Start

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

With a transport that has replies, call `await support.refresh()` on return to the foreground to
pick up new replies.

### Connecting to a server

The package works on its own. To connect it to a server, enable the matching trait of the connector package [swift-appgrowstack](https://github.com/appgrowstack/swift-appgrowstack) (SwiftPM traits) instead of wiring a server here.

## Documentation

The API reference is the symbol documentation in `Sources/SupportCore` and `Sources/SupportSwiftUI`.
Open it in Xcode with Product > Build Documentation. Changes are listed in
[CHANGELOG.md](./CHANGELOG.md).

## Installation

```swift
.package(url: "https://github.com/appgrowstack/swift-app-support.git", .upToNextMinor(from: "0.2.0"))
```

```swift
.product(name: "SupportSwiftUI", package: "swift-app-support")
```

| Product | Contents | Depends on |
|---|---|---|
| `SupportCore` | `SupportCenter`, `SupportTransport`, `MailSupportTransport`, `SupportContext`, `BundledHelpArticles`, `HelpSearch` | Foundation, ImageIO, Observation |
| `SupportSwiftUI` | `SupportFormView`, `SupportTicketsView`, `SupportThreadView`, `HelpArticlesView`, `SupportStrings` | SwiftUI |

## Requirements

- iOS 17.0+ / macOS 14.0+
- Swift 6.2+

## License

MIT. See [LICENSE](./LICENSE).
