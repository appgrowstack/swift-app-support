import PhotosUI
import SupportCore
import SwiftUI

/// The contact form. While the person types, help articles that may answer it are shown above the
/// send button. The app's version, device, subscription state and recent events are attached.
public struct SupportFormView: View {
    @Bindable var center: SupportCenter
    let strings: SupportStrings
    let screen: String?
    let onSent: (String) -> Void

    @Environment(\.openURL) private var openURL
    @State private var category: SupportCategory
    @State private var subject = ""
    @State private var message = ""
    @State private var email = ""
    @State private var picked: [PhotosPickerItem] = []
    @State private var images: [SupportImage] = []
    @State private var sending = false
    @State private var sentID: String?
    @State private var failure: String?

    /// - Parameters:
    ///   - screen: where the form was opened from (attached to the request).
    ///   - category: the topic to start with (e.g. `.billing` from the subscription screen).
    public init(center: SupportCenter, strings: SupportStrings? = nil, screen: String? = nil, category: SupportCategory = .question, onSent: @escaping (String) -> Void = { _ in }) {
        self.center = center
        self.strings = strings ?? .forLanguage(center.lang)
        self.screen = screen
        self.onSent = onSent
        _category = State(initialValue: category)
    }

    private var canSend: Bool { !sending && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    public var body: some View {
        Form {
            if let sentID {
                Section {
                    Label(strings.sent, systemImage: "checkmark.circle.fill").font(.headline)
                    Text(strings.sentDetail).foregroundStyle(.secondary)
                }
                .onAppear { onSent(sentID) }
            } else {
                Section {
                    Picker(strings.category, selection: $category) {
                        ForEach(SupportCategory.allCases, id: \.self) { c in Text(strings.categoryNames[c] ?? c.rawValue).tag(c) }
                    }
                    TextField(strings.subject, text: $subject)
                }
                Section(strings.body) {
                    TextField(strings.bodyPlaceholder, text: $message, axis: .vertical).lineLimit(5 ... 14)
                }
                let suggestions = center.suggestions(for: subject + " " + message)
                if !suggestions.isEmpty {
                    Section(strings.maybeHelpful) {
                        ForEach(suggestions) { article in
                            Button { openURL(article.url) } label: { HelpArticleRow(article: article) }
                        }
                    }
                }
                Section {
                    let title = images.isEmpty ? strings.addImages : "\(strings.images) \(images.count)"
                    PhotosPicker(selection: $picked, maxSelectionCount: 4, matching: .screenshots) {
                        Label(title, systemImage: "photo.on.rectangle")
                    }
                }
                Section {
                    TextField(strings.email, text: $email)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                    #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    #endif
                } footer: {
                    Text(strings.emailFooter)
                }
                Section {
                    Button(action: send) {
                        HStack {
                            Text(sending ? strings.sending : strings.send)
                            if sending { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(!canSend)
                    if let failure { Text(failure).foregroundStyle(.red) }
                } footer: {
                    Text(strings.contextFooter)
                }
            }
        }
        .navigationTitle(strings.formTitle)
        .task { if center.articles.isEmpty { await center.loadArticles() } }
        .onChange(of: picked) { _, items in
            Task {
                var loaded: [SupportImage] = []
                for item in items.prefix(4) {
                    if let data = try? await item.loadTransferable(type: Data.self), let image = SupportImage.jpeg(from: data) { loaded.append(image) }
                }
                images = loaded
            }
        }
    }

    private func send() {
        sending = true
        failure = nil
        let request = SupportRequest(category: category, subject: subject, body: message, email: email, images: images)
        Task {
            defer { sending = false }
            do {
                sentID = try await center.submit(request, screen: screen)
            } catch SupportError.rateLimited {
                failure = strings.rateLimited
            } catch {
                failure = strings.failed
            }
        }
    }
}

/// The person's requests, newest first, with a link to each thread and a button to write a new one.
public struct SupportTicketsView: View {
    @Bindable var center: SupportCenter
    let strings: SupportStrings
    let screen: String?

    public init(center: SupportCenter, strings: SupportStrings? = nil, screen: String? = nil) {
        self.center = center
        self.strings = strings ?? .forLanguage(center.lang)
        self.screen = screen
    }

    public var body: some View {
        List {
            Section {
                NavigationLink { SupportFormView(center: center, strings: strings, screen: screen) } label: { Label(strings.contact, systemImage: "square.and.pencil") }
            }
            Section(strings.requestsTitle) {
                if center.tickets.isEmpty {
                    Text(strings.noRequests).foregroundStyle(.secondary)
                }
                ForEach(center.tickets) { ticket in
                    NavigationLink { SupportThreadView(center: center, ticket: ticket, strings: strings) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(ticket.subject ?? ticket.messages.first?.body ?? "").lineLimit(1).font(.body.weight(center.isUnread(ticket) ? .semibold : .regular))
                                if center.isUnread(ticket) { Circle().fill(.tint).frame(width: 8, height: 8) }
                            }
                            Text("\(strings.statusNames[ticket.status] ?? ticket.status.rawValue) · \(ticket.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(strings.requestsTitle)
        .refreshable { await center.refresh() }
        .task { await center.refresh() }
    }
}

/// One request: the messages and a field to add one.
public struct SupportThreadView: View {
    @Bindable var center: SupportCenter
    let ticketID: String
    let strings: SupportStrings
    @State private var draft = ""
    @State private var sending = false
    @State private var failure: String?

    public init(center: SupportCenter, ticket: SupportTicket, strings: SupportStrings? = nil) {
        self.center = center
        self.ticketID = ticket.id
        self.strings = strings ?? .forLanguage(center.lang)
    }

    private var ticket: SupportTicket? { center.tickets.first { $0.id == ticketID } }

    public var body: some View {
        List {
            if let ticket {
                ForEach(ticket.messages) { m in
                    VStack(alignment: m.from == .user ? .trailing : .leading, spacing: 4) {
                        Text(m.body)
                            .padding(10)
                            .background(m.from == .user ? AnyShapeStyle(.tint.opacity(0.15)) : AnyShapeStyle(.quaternary), in: RoundedRectangle(cornerRadius: 12))
                            .textSelection(.enabled)
                        Text(m.at.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: m.from == .user ? .trailing : .leading)
                    .listRowSeparator(.hidden)
                }
                if ticket.status != .resolved {
                    Section {
                        TextField(strings.replyPlaceholder, text: $draft, axis: .vertical).lineLimit(2 ... 8)
                        Button(sending ? strings.sending : strings.replySend, action: send)
                            .disabled(sending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if let failure { Text(failure).foregroundStyle(.red) }
                    }
                }
            }
        }
        .navigationTitle(ticket.map { strings.statusNames[$0.status] ?? "" } ?? "")
        .onAppear { if let ticket { center.markRead(ticket) } }
        .onChange(of: ticket?.latestReply?.id) { _, _ in if let ticket { center.markRead(ticket) } }
    }

    private func send() {
        guard let ticket else { return }
        sending = true
        failure = nil
        Task {
            defer { sending = false }
            do {
                try await center.reply(draft, to: ticket)
                draft = ""
            } catch {
                failure = strings.failed
            }
        }
    }
}

/// The help articles with search, and a way to write when nothing answers it.
public struct HelpArticlesView: View {
    @Bindable var center: SupportCenter
    let strings: SupportStrings
    let screen: String?
    @Environment(\.openURL) private var openURL
    @State private var query = ""

    public init(center: SupportCenter, strings: SupportStrings? = nil, screen: String? = nil) {
        self.center = center
        self.strings = strings ?? .forLanguage(center.lang)
        self.screen = screen
    }

    private var shown: [HelpArticle] {
        query.trimmingCharacters(in: .whitespaces).isEmpty ? center.articles : HelpSearch.search(query, in: center.articles, limit: 20)
    }

    public var body: some View {
        List {
            Section {
                if shown.isEmpty { Text(strings.noHelpMatches).foregroundStyle(.secondary) }
                ForEach(shown) { article in
                    Button { openURL(article.url) } label: { HelpArticleRow(article: article) }
                }
            }
            Section {
                NavigationLink { SupportFormView(center: center, strings: strings, screen: screen) } label: { Label(strings.contact, systemImage: "envelope") }
                if !center.tickets.isEmpty {
                    NavigationLink { SupportTicketsView(center: center, strings: strings, screen: screen) } label: {
                        HStack {
                            Text(strings.requestsTitle)
                            if center.unreadCount > 0 { Spacer(); Text("\(center.unreadCount)").font(.caption.bold()).padding(.horizontal, 6).background(.tint, in: Capsule()).foregroundStyle(.white) }
                        }
                    }
                }
            }
        }
        .navigationTitle(strings.helpTitle)
        .searchable(text: $query, prompt: strings.searchHelp)
        .task { await center.refresh() }
    }
}

struct HelpArticleRow: View {
    let article: HelpArticle
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(article.title).foregroundStyle(.primary)
            Text(article.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
        }
    }
}
