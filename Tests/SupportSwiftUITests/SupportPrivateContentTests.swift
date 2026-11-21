import SupportCore
@testable import SupportSwiftUI
import SwiftUI
import Testing

/// N19: the support views did not let a recorder hide what the person wrote.
@MainActor
struct SupportPrivateContentTests {
    final class Seen: @unchecked Sendable {
        var parts: [SupportPrivatePart] = []
    }

    func render(_ view: some View) {
        let renderer = ImageRenderer(content: view.frame(width: 320, height: 200))
        _ = renderer.cgImage
    }

    @Test func aMarkedPartIsHandedToTheApp() {
        let seen = Seen()
        render(Text("my secret").supportPrivate(.message)
            .supportPrivateContent { part, content in
                seen.parts.append(part)
                return AnyView(content.overlay(Color.black))
            })
        #expect(seen.parts.contains(.message))
    }

    @Test func withoutTheAppsMarkThePartIsShownAsItIs() {
        render(Text("my secret").supportPrivate(.message))
    }

    @Test func partsHaveStableNames() {
        #expect(SupportPrivatePart.allCases.map(\.rawValue) == ["subject", "body", "email", "ticket_title", "message", "reply"])
    }
}
