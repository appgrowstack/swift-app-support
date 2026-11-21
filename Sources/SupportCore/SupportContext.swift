import Foundation

/// The context attached to every request, so the developer can answer without asking
/// "which version? which phone? are you subscribed?". The SDK fills the device and build;
/// the app passes the rest. Nothing the person typed elsewhere in the app goes in here.
public struct SupportContext: Sendable, Hashable, Codable {
    /// Where the build came from. The same values as swift-app-campaign's channel.
    public enum Channel: String, Codable, Sendable, Hashable {
        case appStore = "appstore"
        case testFlight = "testflight"
        case debug
        case play
        case playTest = "play_test"
    }

    public var platform: String
    public var appVersion: String
    public var build: String
    public var osVersion: String
    public var deviceModel: String
    public var channel: Channel
    public var isPremium: Bool?
    /// The screen the form was opened from.
    public var screen: String?
    /// Recent events, newest first. Only the first 20 are sent.
    public var recentEvents: [SupportRecentEvent]
    /// In-app campaigns shown recently, newest first. Only the first 10 are sent.
    public var campaignsShown: [SupportCampaignShown]

    public init(
        platform: String = "ios",
        appVersion: String,
        build: String,
        osVersion: String,
        deviceModel: String,
        channel: Channel,
        isPremium: Bool? = nil,
        screen: String? = nil,
        recentEvents: [SupportRecentEvent] = [],
        campaignsShown: [SupportCampaignShown] = []
    ) {
        self.platform = platform
        self.appVersion = appVersion
        self.build = build
        self.osVersion = osVersion
        self.deviceModel = deviceModel
        self.channel = channel
        self.isPremium = isPremium
        self.screen = screen
        self.recentEvents = recentEvents
        self.campaignsShown = campaignsShown
    }

    /// The context of this device and build. `appVersion` is cut to `x.y.z`.
    public static func current(
        channel: Channel,
        isPremium: Bool? = nil,
        screen: String? = nil,
        recentEvents: [SupportRecentEvent] = [],
        campaignsShown: [SupportCampaignShown] = [],
        bundle: Bundle = .main
    ) -> SupportContext {
        let info = bundle.infoDictionary ?? [:]
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return SupportContext(
            platform: "ios",
            appVersion: normalizedVersion(info["CFBundleShortVersionString"] as? String ?? "0.0"),
            build: String((info["CFBundleVersion"] as? String ?? "0").prefix(32)),
            osVersion: "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)",
            deviceModel: String(hardwareModel().prefix(64)),
            channel: channel,
            isPremium: isPremium,
            screen: screen.map { String($0.prefix(64)) },
            recentEvents: recentEvents,
            campaignsShown: campaignsShown
        )
    }

    /// `3.2` stays `3.2`, `3.2.0.1` becomes `3.2.0`, anything else becomes `0.0`.
    static func normalizedVersion(_ raw: String) -> String {
        let parts = raw.split(separator: ".").prefix(3)
        guard parts.count >= 2, parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isASCIIDigit) }) else { return "0.0" }
        return parts.joined(separator: ".")
    }

    /// `iPhone17,1` on a device, the simulated model in the simulator, `Mac…` on a Mac.
    static func hardwareModel() -> String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulated }
        var info = utsname()
        uname(&info)
        let machine = withUnsafeBytes(of: &info.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
        return machine.isEmpty ? "unknown" : machine
    }

    enum CodingKeys: String, CodingKey {
        case platform, appVersion = "app_version", build, osVersion = "os_version", deviceModel = "device_model", channel
        case isPremium = "is_premium", screen, recentEvents = "recent_events", campaignsShown = "campaigns_shown"
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(platform, forKey: .platform)
        try c.encode(appVersion, forKey: .appVersion)
        try c.encode(String(build.prefix(32)), forKey: .build)
        try c.encode(String(osVersion.prefix(32)), forKey: .osVersion)
        try c.encode(String(deviceModel.prefix(64)), forKey: .deviceModel)
        try c.encode(channel, forKey: .channel)
        try c.encodeIfPresent(isPremium, forKey: .isPremium)
        try c.encodeIfPresent(screen.map { String($0.prefix(64)) }, forKey: .screen)
        try c.encode(Array(recentEvents.prefix(20)), forKey: .recentEvents)
        try c.encode(Array(campaignsShown.prefix(10)), forKey: .campaignsShown)
    }
}

private extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
}
