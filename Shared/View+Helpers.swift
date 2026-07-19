import SwiftUI

/// Cross-platform SwiftUI helpers so the shared feature views compile and
/// behave on both iOS (16+) and macOS (13+) without guarded boilerplate at
/// every call site.

extension View {
    /// Use an inline navigation title on iOS; a no-op on macOS.
    @ViewBuilder
    func inlineTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

/// A lightweight stand-in for `ContentUnavailableView`, which is only available
/// on iOS 17 / macOS 14. This renders a centered icon + title + description and
/// works on our iOS 16 / macOS 13 deployment targets.
struct FeatureEmptyState: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
