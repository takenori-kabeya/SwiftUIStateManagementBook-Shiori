import SwiftUI

@main
struct ShioriApp: App {
    private var tripPersistence: TripPersistence {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("UITesting")
            ? .uiTest
            : .local
        #else
            .local
        #endif
    }


    var body: some Scene {
        WindowGroup {
            TripListView(tripPersistence: tripPersistence)
        }
    }
}
