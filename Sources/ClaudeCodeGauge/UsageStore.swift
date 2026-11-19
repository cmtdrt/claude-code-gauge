import AppKit

@MainActor
final class UsageStore: ObservableObject {
    @Published private(set) var usage: Usage?
    @Published private(set) var isRefreshing = false
    @Published private(set) var error: UsageError?

    @Published var intervalMinutes: Int {
        didSet {
            let clamped = min(max(intervalMinutes, Self.intervalRange.lowerBound), Self.intervalRange.upperBound)
            if clamped != intervalMinutes { intervalMinutes = clamped; return }
            defaults.set(intervalMinutes, forKey: Key.interval)
            schedule()
        }
    }

    @Published var autoRefreshDisabled: Bool {
        didSet {
            defaults.set(autoRefreshDisabled, forKey: Key.autoRefreshDisabled)
            schedule()
        }
    }

    static let intervalRange = 1...60

    private enum Key {
        static let interval = "intervalMinutes"
        static let autoRefreshDisabled = "autoRefreshDisabled"
        static let lastUsage = "lastUsage"
    }

    private let defaults = UserDefaults.standard
    private var timer: Timer?

    init() {
        intervalMinutes = defaults.object(forKey: Key.interval) as? Int ?? 5
        autoRefreshDisabled = defaults.bool(forKey: Key.autoRefreshDisabled)
        // Show the last known values right away, even with automatic refresh turned off.
        if let data = defaults.data(forKey: Key.lastUsage) {
            usage = try? JSONDecoder().decode(Usage.self, from: data)
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, !self.autoRefreshDisabled else { return }
                self.refresh()
            }
        }

        schedule()
        if !autoRefreshDisabled { refresh() }
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        UsageFetcher.fetch { [weak self] result in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.isRefreshing = false
                switch result {
                case .success(let usage):
                    self.usage = usage
                    self.error = nil
                    if let data = try? JSONEncoder().encode(usage) {
                        self.defaults.set(data, forKey: Key.lastUsage)
                    }
                case .failure(let error):
                    self.error = error
                }
            }
        }
    }

    private func schedule() {
        timer?.invalidate()
        timer = nil
        guard !autoRefreshDisabled else { return }
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalMinutes * 60), repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
    }
}

/// Gauge color rule shared by the menu bar icon and the popup.
enum Level {
    case normal, warning, critical

    init(percent: Int) {
        switch percent {
        case 90...: self = .critical
        case 70...: self = .warning
        default: self = .normal
        }
    }
}
