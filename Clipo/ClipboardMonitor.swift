import AppKit
import SwiftData
import os

private let log = Logger(subsystem: "dev.clipo", category: "monitor")

/// Observa o clipboard do sistema e grava o histórico no SwiftData.
@MainActor
final class ClipboardMonitor {
    static let maxItems = 20

    private let context: ModelContext
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?

    init(context: ModelContext) {
        self.context = context
    }

    func start() {
        guard timer == nil else { return }
        log.notice("monitor started, changeCount=\(self.lastChangeCount)")
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func poll() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        let text = pasteboard.string(forType: .string)
        log.notice("changed: count=\(self.lastChangeCount) types=\(pasteboard.types?.map(\.rawValue).joined(separator: ",") ?? "nil") textLength=\(text?.count ?? -1)")

        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        record(text)
    }
    
    private func record(_ text: String) {
        // Texto já existente sobe para o topo em vez de duplicar.
        let existing = FetchDescriptor<ClipItem>(predicate: #Predicate { $0.text == text })
        if let item = try? context.fetch(existing).first {
            item.createdAt = .now
        } else {
            context.insert(ClipItem(text: text))
            trim()
        }
        do {
            try context.save()
            log.notice("saved, total=\((try? self.context.fetchCount(FetchDescriptor<ClipItem>())) ?? -1)")
        } catch {
            log.error("save failed: \(error)")
        }
    }

    private func trim() {
        let all = FetchDescriptor<ClipItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        guard let items = try? context.fetch(all), items.count > Self.maxItems else { return }
        items.dropFirst(Self.maxItems).forEach(context.delete)
    }
}
