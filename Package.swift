// swift-tools-version: 6.2
import PackageDescription

/// In-app support for a small app: a contact form that attaches the context a developer needs and
/// help articles to search before writing. Requests go to a transport: a mail to you
/// (`MailSupportTransport`), or a support server that also brings the replies into the app.
///
/// **No external dependencies.**
let package = Package(
    name: "swift-app-support",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // The transport protocol, the mail transport, the attached context, bundled help articles,
        // help search and an observable store for the views. Foundation, ImageIO, Observation, and
        // UIKit / AppKit only to open the mail.
        .library(name: "SupportCore", targets: ["SupportCore"]),
        // SwiftUI views: the form, the list of requests, a thread with a reply field, and help.
        .library(name: "SupportSwiftUI", targets: ["SupportSwiftUI"])
    ],
    targets: [
        .target(name: "SupportCore"),
        .target(name: "SupportSwiftUI", dependencies: ["SupportCore"]),
        .testTarget(name: "SupportCoreTests", dependencies: ["SupportCore"]),
        .testTarget(name: "SupportSwiftUITests", dependencies: ["SupportSwiftUI"])
    ]
)
