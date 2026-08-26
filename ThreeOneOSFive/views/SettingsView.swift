import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                // ── App Branding ────────────────────────────────────────────
                Section {
                    HStack(spacing: 14) {
                        AppLogo()

                        VStack(alignment: .leading, spacing: 3) {
                            Text("3105")
                                .font(.headline)
                            Text("Version \(appVersion)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // ── License Info ─────────────────────────────────────────────
                Section("License") {
                    LabeledContent("Status",
                        value: LicenseService.shared.isActivated ? "Active ✅" : "Inactive ❌"
                    )
                    if !LicenseService.shared.activeKey.isEmpty {
                        LabeledContent("Key", value: LicenseService.shared.activeKey)
                        if !LicenseService.shared.expiryString.isEmpty {
                            LabeledContent("Expires", value: LicenseService.shared.expiryString)
                        }
                        // ── Expiry countdown ────────────────────────────────
                        if let expDate = LicenseService.shared.expiryDate {
                            ExpiryCountdownRow(expiryDate: expDate)
                        }
                    }
                }

                // ── Device ───────────────────────────────────────────────────
                Section("Device") {
                    LabeledContent("Model", value: AppInfo.displayMachineName)
                    LabeledContent("iOS Version", value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                }

                // ── Supported Versions ───────────────────────────────────────
                Section {
                    HStack {
                        Text("Current Version")
                        Spacer()
                        Text(appState.isSupported ? "Supported" : "Not Supported")
                            .foregroundStyle(appState.isSupported ? Color.green : Color.red)
                    }
                    LabeledContent("iOS 17", value: ExploitSupportPolicy.verifiedIOS17Range)
                    LabeledContent("iOS 18", value: ExploitSupportPolicy.verifiedIOS18Range)
                    LabeledContent("iOS 26", value: ExploitSupportPolicy.verifiedIOS26Range)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iOS 27.0")
                            .font(.body)
                        ForEach(ExploitSupportPolicy.verifiedIOS27Builds, id: \.build) { version in
                            Text(versionLabel(version))
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("Supported Versions")
                } footer: {
                    Text("Only listed versions are verified to work correctly.")
                }

                // ── Contact ──────────────────────────────────────────────────
                Section("Contact") {
                    creditsRow(
                        name: "Telegram",
                        role: "@Sinko_z1",
                        url: "https://t.me/Sinko_z1"
                    )
                }
            }
            .tint(AppTheme.accent)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0"
    }

    private func versionLabel(
        _ version: (beta: Int, publicBeta: Int?, build: String)
    ) -> String {
        if let publicBeta = version.publicBeta {
            return language.text(
                "settings.developer_public_beta_build",
                Int64(version.beta),
                Int64(publicBeta),
                version.build
            )
        }
        return language.text(
            "settings.developer_beta_build",
            Int64(version.beta),
            version.build
        )
    }

    @ViewBuilder
    private func creditsRow(name: String, role: String, url: String) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 28, height: 28)
                }
                .contentShape(Rectangle())
            }
        }
    }
}

// ── Live countdown row ────────────────────────────────────────────────────────
private struct ExpiryCountdownRow: View {
    let expiryDate: Date
    @State private var now: Date = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        LabeledContent("Time Left", value: countdown)
            .onReceive(timer) { _ in now = Date() }
    }

    private var countdown: String {
        let diff = expiryDate.timeIntervalSince(now)
        if diff <= 0 { return "Expired" }
        let totalMinutes = Int(diff / 60)
        let days    = totalMinutes / 1440
        let hours   = (totalMinutes % 1440) / 60
        let minutes = totalMinutes % 60
        if days > 0 { return "\(days)d \(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
