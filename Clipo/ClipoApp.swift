import SwiftUI
import SwiftData

@main
struct ClipoApp: App {
    private let container: ModelContainer
    private let monitor: ClipboardMonitor

    init() {
        let container = try! ModelContainer(for: ClipItem.self)
        self.container = container
        monitor = ClipboardMonitor(context: container.mainContext)
        monitor.start()
    }

    var body: some Scene {
        MenuBarExtra("Clipo", systemImage: "list.clipboard") {
            ContentView()
                .modelContainer(container)
        }
        .menuBarExtraStyle(.window)
    }
}
