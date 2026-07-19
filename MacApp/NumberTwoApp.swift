import SwiftUI

/// macOS entry point. The shared UI and logic live in `Shared/` and are
/// compiled directly into this app target, so no module import is needed.
@main
struct NumberTwoApp: App {
    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .windowResizability(.contentSize)
    }
}
