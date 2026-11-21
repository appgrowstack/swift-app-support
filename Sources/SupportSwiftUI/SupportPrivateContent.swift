import SwiftUI

/// The parts of the support views that hold what the person wrote, or what was written to them.
public enum SupportPrivatePart: String, Sendable, CaseIterable {
    /// The subject field of the form.
    case subject
    /// The body field of the form.
    case body
    /// The email field of the form.
    case email
    /// A request's title in the list of requests (its subject or first message).
    case ticketTitle = "ticket_title"
    /// A message of a thread, from the person or from you.
    case message
    /// The reply field of a thread.
    case reply
}

extension EnvironmentValues {
    @Entry var supportPrivateContent: (@MainActor @Sendable (SupportPrivatePart, AnyView) -> AnyView)? = nil
}

extension View {
    /// Wraps every part of the support views that holds a person's words (``SupportPrivatePart``)
    /// in `mark`, so a screen recorder can hide it. This package knows no recorder: the app ties the
    /// parts to its own, once, above the support views.
    ///
    /// ```swift
    /// import SessionsSwiftUI
    ///
    /// SupportTicketsView(center: center)
    ///     .supportPrivateContent { _, content in AnyView(content.sessionMask()) }
    /// ```
    ///
    /// Screens pushed from these views (the form, a thread) read it too.
    public func supportPrivateContent(_ mark: @escaping @MainActor @Sendable (_ part: SupportPrivatePart, _ content: AnyView) -> AnyView) -> some View {
        environment(\.supportPrivateContent, mark)
    }

    /// Marks this view as the part `part` (``supportPrivateContent(_:)``).
    func supportPrivate(_ part: SupportPrivatePart) -> some View {
        modifier(SupportPrivateModifier(part: part))
    }
}

struct SupportPrivateModifier: ViewModifier {
    let part: SupportPrivatePart
    @Environment(\.supportPrivateContent) private var mark

    func body(content: Content) -> some View {
        if let mark {
            mark(part, AnyView(content))
        } else {
            content
        }
    }
}
