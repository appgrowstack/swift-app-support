import SupportCore
import Foundation
import Testing

struct SupportSDKTests {
    /// The version a connector reports must be the one released: the newest `## [x.y.z]` section of the CHANGELOG.
    @Test func versionMatchesTheChangelog() throws {
        let changelog = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "CHANGELOG.md")
        let text = try String(contentsOf: changelog, encoding: .utf8)
        let released = try #require(text.firstMatch(of: #/\n## \[(\d+\.\d+\.\d+)\]/#))
        #expect(String(released.1) == SupportSDK.version)
        #expect(SupportSDK.name == "swift-app-support")
    }
}
