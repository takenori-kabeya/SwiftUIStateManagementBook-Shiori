import SwiftUI

@main
struct ShioriApp: App {
    var body: some Scene {
        WindowGroup {
            TripListView(tripPersistence: TripPersistence.local)
        }
    }
}
