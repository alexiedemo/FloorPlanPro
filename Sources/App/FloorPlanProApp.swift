import SwiftUI

@main
struct FloorPlanProApp: App {
    @StateObject private var store = ProjectStore()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(store)
        }
    }
}
