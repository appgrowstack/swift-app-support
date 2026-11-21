# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-11-21

### Added

- `SupportClient` for `api.appgrowstack.com/v1/support/*`: send a request with its context and
  screenshots, read this install's requests and replies, add a message, and list help articles.
- The owner token (the key to read one's own replies) is made on first use and kept in the
  Keychain (`KeychainSupportTokenStore`); the server stores only its SHA-256.
- `SupportContext.current(channel:isPremium:screen:recentEvents:campaignsShown:)` fills the app
  version, build, OS and device model. Recent events keep their types.
- `HelpSearch` ranks help articles for what the person is typing, including Japanese and other
  languages written without spaces.
- `SupportImage.jpeg(from:)` re-encodes screenshots and photos as JPEG under 5 MB without metadata.
- `SupportCenter`, an observable store with the requests, the articles and the unread count.
- `SupportSwiftUI`: `SupportFormView` (suggests articles while typing), `SupportTicketsView`,
  `SupportThreadView` and `HelpArticlesView`, with English and Japanese strings (`SupportStrings`).
