import SwiftUI

/// Shared UI for NumberTwo — a cool-looking random number generator.
/// Used by both the macOS and iOS app targets.
struct AppView: View {
    @StateObject private var generator = RandomGenerator()

    var body: some View {
        #if os(macOS)
        ContentView()
            .environmentObject(generator)
            .frame(minWidth: 420, minHeight: 560)
        #else
        ContentView()
            .environmentObject(generator)
        #endif
    }
}

#Preview {
    AppView()
        .environmentObject(RandomGenerator())
}
