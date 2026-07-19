import Foundation

/// Shared core for NumberTwo — a cool-looking random number generator.
/// Single codebase used by both the macOS and iOS apps, compiled directly
/// into each app target (see `project.yml`), so there is no separate
/// framework or SwiftPM package to resolve at build time.
public enum AppCore {
    /// Display name of the product.
    public static let appName = "NumberTwo"

    /// Semantic version of the product.
    public static let version = "0.2.0"
}
