// swift-tools-version: 6.2
import PackageDescription

/// In-app support for a small app: a contact form that attaches the context a developer needs,
/// the person's own requests and replies, and help articles to search before writing.
/// Replies are drafted on the server and reviewed by the developer before they are sent.
///
/// **No external dependencies.**
let package = Package(
    name: "swift-app-support",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // The API client, the owner token in the Keychain, the attached context, help search and
        // an observable store for the views. Foundation, Security, ImageIO and Observation only.
        .library(name: "SupportCore", targets: ["SupportCore"]),
        // SwiftUI views: the form, the list of requests, a thread with a reply field, and help.
        .library(name: "SupportSwiftUI", targets: ["SupportSwiftUI"])
    ],
    targets: [
        .target(name: "SupportCore"),
        .target(name: "SupportSwiftUI", dependencies: ["SupportCore"]),
        .testTarget(name: "SupportCoreTests", dependencies: ["SupportCore"])
    ]
)
