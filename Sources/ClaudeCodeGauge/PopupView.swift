import AppKit
import SwiftUI

struct PopupView: View {
    @EnvironmentObject private var store: UsageStore
    @AppStorage(Language.storageKey) private var language: Language = .fr

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(alignment: .leading, spacing: 12) {
                gaugeRow(language.t("Session", "Session"), window: store.usage?.session)
                gaugeRow(language.t("Semaine", "Week"), window: store.usage?.week)
            }

            if let error = store.error {
                Text(message(for: error))
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text(language.t("Rafraîchir toutes les", "Refresh every"))
                    TextField("", value: $store.intervalMinutes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .frame(width: 38)
                    Stepper("", value: $store.intervalMinutes, in: UsageStore.intervalRange)
                        .labelsHidden()
                    Text("min")
                }
                .disabled(store.autoRefreshDisabled)
                .opacity(store.autoRefreshDisabled ? 0.45 : 1)

                Toggle(language.t("Désactiver le suivi automatique", "Turn off automatic refresh"),
                       isOn: $store.autoRefreshDisabled)
                    .toggleStyle(.checkbox)
            }

            Divider()

            HStack {
                Picker("", selection: $language) {
                    ForEach(Language.allCases) { Text($0.label).tag($0) }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .controlSize(.small)
                .fixedSize()
                Spacer()
                Button(language.t("Quitter", "Quit")) { NSApp.terminate(nil) }
                    .controlSize(.small)
            }
        }
        .padding(14)
        .frame(width: 300)
    }

    private var header: some View {
        HStack {
            Text(language.t("Quotas Claude Code", "Claude Code quotas"))
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Button(action: store.refresh) {
                Group {
                    if store.isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13))
                    }
                }
                .frame(width: 22, height: 20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .disabled(store.isRefreshing)
            .help(language.t("Rafraîchir", "Refresh"))
        }
    }

    private func gaugeRow(_ title: String, window: Usage.Window?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 10) {
                Text(title)
                    .frame(width: 58, alignment: .leading)
                GaugeBar(percent: window?.percent)
                    .frame(height: 8)
                Text(window.map { language.t("\($0.percent) %", "\($0.percent)%") } ?? "–")
                    .monospacedDigit()
                    .frame(width: 42, alignment: .trailing)
            }
            if let reset = window?.resetsAt {
                Text(resetText(reset))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 68)
            }
        }
    }

    private func resetText(_ date: Date) -> String {
        let locale = Locale(identifier: language == .fr ? "fr_FR" : "en_US")
        let time = date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale))
        if Calendar.current.isDateInToday(date) {
            return language.t("Remise à zéro aujourd'hui à \(time)", "Resets today at \(time)")
        }
        let day = date.formatted(Date.FormatStyle(locale: locale).weekday(.abbreviated).day().month(.abbreviated))
        return language.t("Remise à zéro \(day) à \(time)", "Resets \(day) at \(time)")
    }

    private func message(for error: UsageError) -> String {
        switch error {
        case .claudeNotFound:
            return language.t("Commande `claude` introuvable. Installe Claude Code.",
                              "Can't find the `claude` command. Install Claude Code.")
        case .noQuota:
            return language.t("Aucun quota trouvé : il faut un abonnement Claude (Pro ou Max).",
                              "No quota found: a Claude subscription (Pro or Max) is required.")
        case .failed:
            return language.t("Impossible de lire les quotas. Réessaie plus tard.",
                              "Couldn't read quotas. Try again later.")
        }
    }
}

struct GaugeBar: View {
    let percent: Int?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.12))
                if let percent, percent > 0 {
                    Capsule()
                        .fill(color(for: Level(percent: percent)))
                        .frame(width: max(geo.size.width * CGFloat(min(percent, 100)) / 100, geo.size.height))
                }
            }
        }
    }

    private func color(for level: Level) -> Color {
        switch level {
        case .normal: return .primary
        case .warning: return .orange
        case .critical: return .red
        }
    }
}
