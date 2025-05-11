import SwiftUI

@main
struct EatSipRepeatApp: App {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false

    init() {
        #if DEBUG
        // Always show welcome in Debug
        hasSeenWelcome = false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            if hasSeenWelcome {
                ContentView()
            } else {
                WelcomeView()
            }
        }
    }
}
