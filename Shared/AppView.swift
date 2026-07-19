import SwiftUI

/// Shared UI for NumberTwo, used by both the macOS and iOS app targets.
///
/// Presents the native feature hub (`HubView`) which routes to the five
/// Spanish-learning modes. `HubView` owns its own `NavigationStack`, so the
/// platform shells only need to size the window.
struct AppView: View {
    var body: some View {
        #if os(macOS)
        HubView()
            .frame(minWidth: 520, minHeight: 600)
        #else
        HubView()
        #endif
    }
}

#Preview {
    AppView()
}
