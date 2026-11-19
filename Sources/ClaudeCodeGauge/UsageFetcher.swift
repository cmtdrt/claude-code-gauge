import Foundation

struct Usage: Codable, Equatable {
    struct Window: Codable, Equatable {
        var percent: Int
        var resetsAt: Date?
    }

    var session: Window
    var week: Window
}

enum UsageError: Error {
    case claudeNotFound
    case failed
    /// `/usage` answered but without quota lines (e.g. API key instead of a subscription).
    case noQuota
}

/// Reads quotas with Claude Code's `/usage` command: it never calls the model, so it costs no tokens.
enum UsageFetcher {
    static func fetch(completion: @escaping (Result<Usage, UsageError>) -> Void) {
        guard let claude = ClaudeLocator.resolve() else {
            completion(.failure(.claudeNotFound))
            return
        }
        DispatchQueue.global(qos: .utility).async {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: claude)
            p.arguments = ["-p", "--output-format", "json", "--no-session-persistence"]
            p.currentDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())
            p.environment = ClaudeLocator.environment(claudePath: claude)
            let stdin = Pipe(), stdout = Pipe()
            p.standardInput = stdin
            p.standardOutput = stdout
            p.standardError = FileHandle.nullDevice

            let result: Result<Usage, UsageError>
            if (try? p.run()) == nil {
                result = .failure(.failed)
            } else {
                stdin.fileHandleForWriting.write(Data("/usage".utf8))
                try? stdin.fileHandleForWriting.close()
                let data = stdout.fileHandleForReading.readDataToEndOfFile()
                p.waitUntilExit()
                if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = obj["result"] as? String {
                    result = parse(text).map { .success($0) } ?? .failure(.noQuota)
                } else {
                    result = .failure(.failed)
                }
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    /// Parses lines such as:
    /// `Current session: 5% used · resets Nov 19 at 1:29pm (Europe/Paris)`
    /// `Current week (all models): 15% used · resets Nov 22 at 12:59pm (Europe/Paris)`
    static func parse(_ text: String, now: Date = Date()) -> Usage? {
        guard let session = window(in: text, label: "Current session", now: now),
              let week = window(in: text, label: "Current week (all models)", now: now)
        else { return nil }
        return Usage(session: session, week: week)
    }

    private static func window(in text: String, label: String, now: Date) -> Usage.Window? {
        guard let line = text.split(whereSeparator: \.isNewline).first(where: { $0.hasPrefix(label + ":") }) else {
            return nil
        }
        let s = String(line)
        guard let percent = groups(#"(\d+)%\s*used"#, in: s)?[0].flatMap({ Int($0) }) else { return nil }
        var resetsAt: Date?
        if let reset = groups(#"resets (.+?) at (\d{1,2}(?::\d{2})?\s*[ap]m)(?: \(([^)]+)\))?"#, in: s),
           let day = reset[0], let time = reset[1] {
            resetsAt = date(day: day, time: time, zone: reset[2], now: now)
        }
        return Usage.Window(percent: percent, resetsAt: resetsAt)
    }

    /// Capture groups of the first match (nil for a group that didn't participate).
    private static func groups(_ pattern: String, in s: String) -> [String?]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let m = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) else { return nil }
        return (1..<m.numberOfRanges).map { i in
            Range(m.range(at: i), in: s).map { String(s[$0]) }
        }
    }

    /// "Nov 19" + "1:29pm" (+ time zone) → the next matching date. The year is not given.
    private static func date(day: String, time: String, zone: String?, now: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = zone.flatMap(TimeZone.init(identifier:)) ?? .current
        let compactTime = time.replacingOccurrences(of: " ", with: "")
        formatter.dateFormat = compactTime.contains(":") ? "yyyy MMM d h:mma" : "yyyy MMM d ha"
        let year = Calendar.current.component(.year, from: now)
        for y in [year, year + 1] {
            if let d = formatter.date(from: "\(y) \(day) \(compactTime.uppercased())"),
               d > now.addingTimeInterval(-86_400) {
                return d
            }
        }
        return nil
    }
}

/// Finds the `claude` binary. Apps launched from Finder don't get the terminal's PATH,
/// so check the usual locations, then ask the user's login shell.
enum ClaudeLocator {
    private static var cached: String?

    static func resolve() -> String? {
        if let cached, FileManager.default.isExecutableFile(atPath: cached) { return cached }
        let home = NSHomeDirectory()
        let candidates = [
            "\(home)/.local/bin/claude",
            "\(home)/.claude/local/claude",
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
        ]
        cached = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) ?? fromLoginShell()
        return cached
    }

    private static func fromLoginShell() -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh")
        p.arguments = ["-l", "-c", "command -v claude"]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = FileHandle.nullDevice
        guard (try? p.run()) != nil else { return nil }
        p.waitUntilExit()
        let path = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return FileManager.default.isExecutableFile(atPath: path) ? path : nil
    }

    /// The app's environment with an extended PATH so Claude finds its tools.
    static func environment(claudePath: String) -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let extra = [
            (claudePath as NSString).deletingLastPathComponent,
            "\(NSHomeDirectory())/.local/bin", "/opt/homebrew/bin", "/usr/local/bin",
            "/usr/bin", "/bin", "/usr/sbin", "/sbin",
        ]
        let current = (env["PATH"] ?? "").split(separator: ":").map(String.init)
        var seen = Set<String>()
        env["PATH"] = (extra + current).filter { seen.insert($0).inserted }.joined(separator: ":")
        return env
    }
}
