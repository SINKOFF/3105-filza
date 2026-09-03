import SwiftUI
import UIKit
import AudioToolbox

struct PatchProjectsView: View {
    @StateObject private var store = PatchProjectStore()
    @State private var selectedGame: GameVersion = .normal

    // Independent multi-category active states
    @State private var activeAimbotName: String? = nil
    @State private var active3DName: String? = nil
    @State private var is144FPSActive: Bool = false

    // Active transaction receipts for clean restoration of original files
    @State private var activeReceipts: [String: PatchTransactionReceipt] = [:]

    // Applying / Restoring state per patch
    @State private var applyingPatchName: String? = nil
    @State private var isRestoringAll: Bool = false

    // Activation notification toast & message
    @State private var toastMessage: String? = nil
    @State private var toastIsRestore: Bool = false
    @State private var showToast: Bool = false
    @State private var alertMessage: String? = nil
    @State private var showAlert: Bool = false

    private var hasAnyActive: Bool {
        activeAimbotName != nil || active3DName != nil || is144FPSActive
    }

    enum GameVersion: String, CaseIterable {
        case normal = "Free Fire"
        case max = "FF Max"

        var bundleID: String {
            switch self {
            case .normal: return "com.dts.freefireth"
            case .max:    return "com.dts.freefiremax"
            }
        }
    }

    // Aimbot items configuration (Only AIM DRAG visible in UI)
    private let aimbotList: [(id: String, title: String, patchProjectName: String, isRisk: Bool)] = [
        ("drag", "AIM DRAG", "AIM DRAG", false)
    ]

    // ESP / 3D items configuration
    private let esp3DList: [(id: String, title: String, patchProjectName: String, color: Color)] = [
        ("cyan_white",    "3d Cyan and white",       "3d Cyan and white",       Color(red: 0.20, green: 0.85, blue: 0.95)),
        ("yellow_green",  "3d Yellow and green",     "3d Yellow and green",     Color(red: 0.85, green: 0.90, blue: 0.20)),
        ("blue",          "3d blue",                 "3d blue",                 Color(red: 0.25, green: 0.55, blue: 1.00)),
        ("hologram_blue", "Character Hologram Blue", "Character Hologram Blue", Color(red: 0.35, green: 0.70, blue: 1.00))
    ]

    // Neon & Dark Purple Theme Colors
    private let bgGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.03, blue: 0.09),
            Color(red: 0.08, green: 0.04, blue: 0.14),
            Color(red: 0.03, green: 0.02, blue: 0.06)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let purpleAccent = Color(red: 0.65, green: 0.35, blue: 0.98)
    private let purpleDark = Color(red: 0.13, green: 0.08, blue: 0.22)
    private let purpleGlow = Color(red: 0.75, green: 0.45, blue: 1.00)

    var body: some View {
        ZStack {
            // Background
            bgGradient
                .ignoresSafeArea()

            // Ambient background lighting
            VStack {
                Circle()
                    .fill(purpleAccent.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -100, y: -150)
                Spacer()
                Circle()
                    .fill(Color.purple.opacity(0.08))
                    .frame(width: 350, height: 350)
                    .blur(radius: 90)
                    .offset(x: 120, y: 150)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {

                    // ── Top Header ──────────────────────────────────────────
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.shield.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(purpleAccent)
                                Text("VIP INJECTOR & PATCHES")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(purpleGlow.opacity(0.9))
                            }

                            HStack(spacing: 8) {
                                Text("SINKO")
                                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)

                                Text("EXTERNAL iOS")
                                    .font(.system(size: 11, weight: .heavy))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.purple.opacity(0.4), purpleAccent.opacity(0.3)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(purpleAccent.opacity(0.6), lineWidth: 1)
                                    )
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // ── Game Selector ───────────────────────────────────────
                    HStack(spacing: 0) {
                        ForEach(GameVersion.allCases, id: \.self) { game in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedGame = game
                                }
                            } label: {
                                Text(game.rawValue)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(selectedGame == game ? .white : .gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedGame == game
                                            ? LinearGradient(
                                                colors: [purpleAccent, Color(red: 0.50, green: 0.20, blue: 0.85)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
                                    )
                                    .cornerRadius(18)
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(purpleAccent.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    // ── Live Status Dashboard ───────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(selectedGame == .normal ? "FREE FIRE" : "FREE FIRE MAX")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)

                            Spacer()

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(hasAnyActive ? Color.green : purpleAccent)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: hasAnyActive ? Color.green.opacity(0.8) : purpleAccent.opacity(0.5), radius: 4)

                                Text(hasAnyActive ? "ONLINE & ACTIVE" : "READY TO INJECT")
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .foregroundColor(hasAnyActive ? .green : purpleAccent)
                            }
                        }

                        // Summary badges for currently active features
                        HStack(spacing: 8) {
                            statusBadge(
                                label: "AIM",
                                value: activeAimbotName ?? "OFF",
                                isActive: activeAimbotName != nil,
                                color: purpleAccent
                            )
                            statusBadge(
                                label: "ESP 3D",
                                value: active3DName ?? "OFF",
                                isActive: active3DName != nil,
                                color: Color.pink
                            )
                            statusBadge(
                                label: "FPS",
                                value: is144FPSActive ? "144 FPS" : "OFF",
                                isActive: is144FPSActive,
                                color: Color.cyan
                            )
                        }

                        // Restore Originals Action Bar (Appears when any feature is active)
                        if hasAnyActive {
                            Button {
                                restoreAllPatches()
                            } label: {
                                HStack(spacing: 8) {
                                    if isRestoringAll {
                                        ProgressView()
                                            .tint(.orange)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.counterclockwise.circle.fill")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.orange)
                                    }

                                    Text("RESTORE ALL ORIGINAL FILES")
                                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                        .foregroundColor(.orange)

                                    Spacer()

                                    Text("Clean Revert")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.orange.opacity(0.8))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(Color.orange.opacity(0.12))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isRestoringAll || applyingPatchName != nil)
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(red: 0.09, green: 0.06, blue: 0.15).opacity(0.85))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: [purpleAccent.opacity(0.5), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .padding(.horizontal, 20)

                    // ── AIMBOTS SECTION ─────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "scope")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(purpleAccent)
                            Text("AIMBOT CATEGORY")
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .foregroundColor(.gray.opacity(0.9))

                            Spacer()

                            Text("Single Selection")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(purpleGlow.opacity(0.7))
                        }
                        .padding(.horizontal, 24)

                        ForEach(aimbotList, id: \.id) { aim in
                            let isSelected = (activeAimbotName == aim.patchProjectName)
                            let isCurrentlyApplying = (applyingPatchName == aim.patchProjectName)

                            patchRow(
                                title: aim.title,
                                isSelected: isSelected,
                                isApplying: isCurrentlyApplying,
                                tintColor: purpleAccent,
                                isRisk: aim.isRisk,
                                onToggle: {
                                    togglePatch(name: aim.patchProjectName, category: .aimbot)
                                }
                            )
                        }
                    }

                    // ── ESP & 3D SECTION ────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "eye.trianglebadge.exclamationmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.pink)
                            Text("ESP & 3D SHADERS")
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .foregroundColor(.gray.opacity(0.9))

                            Spacer()

                            Text("3D Shaders")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color.pink.opacity(0.7))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 6)

                        ForEach(esp3DList, id: \.id) { esp in
                            let isSelected = (active3DName == esp.patchProjectName)
                            let isCurrentlyApplying = (applyingPatchName == esp.patchProjectName)

                            patchRow(
                                title: esp.title,
                                isSelected: isSelected,
                                isApplying: isCurrentlyApplying,
                                tintColor: esp.color,
                                isRisk: false,
                                onToggle: {
                                    togglePatch(name: esp.patchProjectName, category: .esp3d)
                                }
                            )
                        }

                        // 144 FPS Row
                        let is144Applying = (applyingPatchName == "144 FPS")
                        patchRow(
                            title: "144 FPS (Ultra Smooth)",
                            isSelected: is144FPSActive,
                            isApplying: is144Applying,
                            tintColor: Color.cyan,
                            isRisk: false,
                            onToggle: {
                                togglePatch(name: "144 FPS", category: .fps)
                            }
                        )
                    }

                    // ── Account Safety & Instructions Card ───────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        // Safety tip
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("ACCOUNT SAFETY TIP")
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.orange)
                                Text("If you want to play on your main account, use Aim Drag — it has the lowest detection risk.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray.opacity(0.9))
                            }
                        }

                        Divider()
                            .background(Color.white.opacity(0.08))

                        // How to use
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(purpleAccent)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("HOW TO USE")
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    .foregroundColor(purpleGlow)
                                Text("1. Open the game first and wait until you reach the Login / Lobby screen.\n2. Open SINKO and activate your desired features.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray.opacity(0.9))
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(red: 0.10, green: 0.07, blue: 0.16).opacity(0.85))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(purpleAccent.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    Spacer(minLength: 40)
                }
            }

            // ── Floating Activation / Restore Toast HUD ─────────────────────
            if showToast, let message = toastMessage {
                VStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(toastIsRestore ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: toastIsRestore ? "arrow.counterclockwise.circle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(toastIsRestore ? .orange : .green)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(toastIsRestore ? "RESTORED ORIGINALS" : "ACTIVATED")
                                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                            Text(message)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Image(systemName: toastIsRestore ? "shield.fill" : "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(toastIsRestore ? .orange : purpleAccent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.10, green: 0.07, blue: 0.18).opacity(0.95))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(toastIsRestore ? Color.orange.opacity(0.6) : purpleAccent.opacity(0.6), lineWidth: 1.5)
                    )
                    .shadow(color: (toastIsRestore ? Color.orange : purpleAccent).opacity(0.35), radius: 16, y: 6)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()
                }
                .zIndex(10)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Status"),
                message: Text(alertMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // ── Status Sub-badge ────────────────────────────────────────────────────
    @ViewBuilder
    private func statusBadge(label: String, value: String, isActive: Bool, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundColor(.gray)

            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isActive ? color : .gray.opacity(0.6))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? color.opacity(0.12) : Color.black.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? color.opacity(0.4) : Color.white.opacity(0.04), lineWidth: 1)
        )
    }

    // ── Patch Item Row ──────────────────────────────────────────────────────
    @ViewBuilder
    private func patchRow(
        title: String,
        isSelected: Bool,
        isApplying: Bool,
        tintColor: Color,
        isRisk: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: 14) {
                // Checkbox / Status Indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(isSelected ? tintColor : Color.gray.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(tintColor)
                            .frame(width: 14, height: 14)
                            .shadow(color: tintColor.opacity(0.6), radius: 3)
                    }
                }

                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .gray.opacity(0.9))

                    if isRisk {
                        Text("RISK")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                            .shadow(color: Color.red.opacity(0.5), radius: 3)
                    }
                }

                Spacer()

                if isApplying {
                    ProgressView()
                        .tint(tintColor)
                        .scaleEffect(0.8)
                } else if isSelected {
                    Text("ON")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(tintColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(tintColor.opacity(0.18))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(tintColor.opacity(0.4), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isSelected
                            ? Color(red: 0.13, green: 0.08, blue: 0.22).opacity(0.9)
                            : Color.white.opacity(0.04)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected
                            ? tintColor.opacity(0.6)
                            : Color.white.opacity(0.06),
                        lineWidth: isSelected ? 1.2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    // ── Patch Toggle, Apply & Restore Engine ──────────────────────────────
    enum PatchCategory {
        case aimbot
        case esp3d
        case fps
    }

    private func togglePatch(name: String, category: PatchCategory) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AudioServicesPlaySystemSound(1057)

        switch category {
        case .aimbot:
            if activeAimbotName == name {
                // Tapped active patch -> Restore Originals & Deactivate
                restoreSinglePatch(name: name, category: .aimbot)
                return
            }
            // If another aimbot was active, restore it first before applying new one
            if let previous = activeAimbotName {
                restoreSinglePatch(name: previous, category: .aimbot, autoDeactivateOnly: true)
            }
            activeAimbotName = name
            applySinglePatch(targetPatchName: name, category: .aimbot)

        case .esp3d:
            if active3DName == name {
                // Tapped active patch -> Restore Originals & Deactivate
                restoreSinglePatch(name: name, category: .esp3d)
                return
            }
            if let previous = active3DName {
                restoreSinglePatch(name: previous, category: .esp3d, autoDeactivateOnly: true)
            }
            active3DName = name
            applySinglePatch(targetPatchName: name, category: .esp3d)

        case .fps:
            if is144FPSActive {
                restoreSinglePatch(name: "144 FPS", category: .fps)
                return
            }
            is144FPSActive = true
            applySinglePatch(targetPatchName: "144 FPS", category: .fps)
        }
    }

    private func applySinglePatch(targetPatchName: String, category: PatchCategory) {
        guard let item = store.items.first(where: { $0.project?.name == targetPatchName }),
              let baseProject = item.project else {
            alertMessage = "Patch \(targetPatchName) not found in library."
            showAlert = true
            return
        }

        applyingPatchName = targetPatchName
        let targetBundle = selectedGame.bundleID

        Task.detached(priority: .userInitiated) {
            do {
                let synced = item.summary.schemaVersion >= 2
                    ? try PatchProjectLibrary.synchronizeWorkspace(item: item)
                    : baseProject

                // Retarget project to selected game bundle
                let project = Self.retargetProject(synced, to: targetBundle)
                let receipt = try DevicePatchService.apply(project: project)

                await MainActor.run {
                    self.applyingPatchName = nil
                    self.activeReceipts[targetPatchName] = receipt

                    // Success notification
                    AudioServicesPlayAlertSound(1054)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)

                    self.showToastMessage("\(targetPatchName) Applied Successfully", isRestore: false)
                }
            } catch {
                await MainActor.run {
                    self.applyingPatchName = nil
                    // Revert active status on failure
                    switch category {
                    case .aimbot: if self.activeAimbotName == targetPatchName { self.activeAimbotName = nil }
                    case .esp3d:  if self.active3DName == targetPatchName { self.active3DName = nil }
                    case .fps:    if targetPatchName == "144 FPS" { self.is144FPSActive = false }
                    }
                    self.alertMessage = "Failed to apply patch: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }

    private func restoreSinglePatch(name: String, category: PatchCategory, autoDeactivateOnly: Bool = false) {
        applyingPatchName = name

        Task.detached(priority: .userInitiated) {
            // Find active receipt or lookup latest receipt in library
            let item = await MainActor.run { store.items.first(where: { $0.project?.name == name }) }
            var receiptToRestore = await MainActor.run { activeReceipts[name] }

            if receiptToRestore == nil, let item, let project = item.project {
                receiptToRestore = DevicePatchService.latestReceipt(projectID: project.id)
            }

            if let receipt = receiptToRestore {
                do {
                    try DevicePatchService.restore(receipt: receipt)
                } catch {
                    log("restore error for \(name): \(error)")
                }
            }

            await MainActor.run {
                self.applyingPatchName = nil
                self.activeReceipts.removeValue(forKey: name)

                switch category {
                case .aimbot:
                    if self.activeAimbotName == name { self.activeAimbotName = nil }
                case .esp3d:
                    if self.active3DName == name { self.active3DName = nil }
                case .fps:
                    if name == "144 FPS" { self.is144FPSActive = false }
                }

                if !autoDeactivateOnly {
                    AudioServicesPlaySystemSound(1057)
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    self.showToastMessage("Restored Originals for \(name)", isRestore: true)
                }
            }
        }
    }

    private func restoreAllPatches() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        isRestoringAll = true

        Task.detached(priority: .userInitiated) {
            let receipts = await MainActor.run { Array(activeReceipts.values) }

            // Restore all cached receipts
            for receipt in receipts {
                try? DevicePatchService.restore(receipt: receipt)
            }

            // Also check latest receipts for any store items that were active
            let allItems = await MainActor.run { store.items }
            for item in allItems {
                if let project = item.project, let receipt = DevicePatchService.latestReceipt(projectID: project.id) {
                    try? DevicePatchService.restore(receipt: receipt)
                }
            }

            await MainActor.run {
                self.activeReceipts.removeAll()
                self.activeAimbotName = nil
                self.active3DName = nil
                self.is144FPSActive = false
                self.isRestoringAll = false

                AudioServicesPlayAlertSound(1054)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.showToastMessage("All Game Files Restored to Original", isRestore: true)
            }
        }
    }

    private func showToastMessage(_ msg: String, isRestore: Bool) {
        self.toastMessage = msg
        self.toastIsRestore = isRestore
        withAnimation(.spring()) {
            self.showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showToast = false
            }
        }
    }

    private nonisolated static func retargetProject(_ project: PatchProject, to bundleID: String) -> PatchProject {
        var modified = project
        modified.bundleIdentifiers = [bundleID]
        modified.rules = project.rules.map { rule in
            var r = rule
            r.bundleID = bundleID
            return r
        }
        modified.directories = project.directories.map { dir in
            var d = dir
            d.bundleID = bundleID
            return d
        }
        return modified
    }
}
