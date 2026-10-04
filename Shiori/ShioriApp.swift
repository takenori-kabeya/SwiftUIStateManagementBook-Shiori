import SwiftUI

@main
struct ShioriApp: App {
    private var tripPersistence: TripPersistenceClient {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("UITesting")
            ? .uiTest
            : .liveValue
        #else
            .liveValue
        #endif
    }

    var body: some Scene {
        WindowGroup {
            TripListView(store: Store(initialState: TripsFeature.State()) {
                TripsFeature()
            })
        }
    }
}
