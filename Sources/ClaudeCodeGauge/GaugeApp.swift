import SwiftUI

@main
struct GaugeApp: App {
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            PopupView()
                .environmentObject(store)
        } label: {
            Image(nsImage: GaugeIcon.image(for: store.usage))
        }
        .menuBarExtraStyle(.window)
    }
}
