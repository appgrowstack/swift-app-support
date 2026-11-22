/// This package's name and version. A connector that talks to a server reports them, so the
/// server can count which versions call.
public enum SupportSDK {
    /// The package name (`swift-app-support`).
    public static let name = "swift-app-support"
    /// The released version: the newest `## [x.y.z]` section of the CHANGELOG (a test checks it).
    public static let version = "0.5.0"
}
