import SwiftUI
import ComposableArchitecture

@main
struct ShioriApp: App {
    private static let store: StoreOf<TripsFeature> = Store(
        initialState: TripsFeature.State()
    ) {
        TripsFeature()
    } withDependencies: {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("UITesting") {
            $0.tripPersistence = .uiTest
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            TripListView(store: Self.store)
        }
    }
}
