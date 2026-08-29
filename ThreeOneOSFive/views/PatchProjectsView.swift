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

    // Applying state per patch
    @State private var applyingPatchName: String? = nil

    // Activation notification toast & message
    @State private var toastMessage: String? = nil
    @State private var showToast: Bool = false
    @State private var alertMessage: String? = nil
    @State private var showAlert: Bool = false

    // Image preview modal state
    @State private var previewImage: (id: String, title: String, assetName: String)? = nil

    enum GameVersion: String, CaseIterable {
        case normal = "Free Fire"
        case max = "FF Max"
    }

    // Aimbot items configuration
    private let aimbotList: [(id: String, title: String, patchProjectName: String, assetName: String)] = [
        ("drag",    "AIM DRAG",      "AIM DRAG",      "preview_aim_drag"),
        ("neck",    "AIM NECK",      "AIM NECK",      "preview_aim_neck"),
        ("body100", "AIM BODY 100%", "AIM BODY 100%", "preview_aim_body100"),
        ("body80",  "AIM BODY 80%",  "AIM BODY 80%",  "preview_aim_body80"),
        ("magic",   "AIM MGIC",      "AIM MGIC",      "preview_aim_magic")
    ]

    // ESP / 3D items configuration
    private let esp3DList: [(id: String, title: String, patchProjectName: String, assetName: String, color: Color)] = [
        ("roz",   "3D gen roz",   "3D gen roz",   "preview_3d_roz",   Color(red: 0.95, green: 0.40, blue: 0.70)),
        ("read",  "3D gen read",  "3D gen read",  "preview_3d_read",  Color(red: 0.95, green: 0.25, blue: 0.30)),
        ("green", "3D gen green", "3D gen green", "preview_3d_green", Color(red: 0.20, green: 0.85, blue: 0.45))
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

                            let hasAnyActive = (activeAimbotName != nil || active3DName != nil || is144FPSActive)

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
                                assetName: aim.assetName,
                                onToggle: {
                                    togglePatch(name: aim.patchProjectName, category: .aimbot)
                                },
                                onEyeTap: {
                                    withAnimation(.spring()) {
                                        previewImage = (id: aim.id, title: aim.title, assetName: aim.assetName)
                                    }
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
                                assetName: esp.assetName,
                                onToggle: {
                                    togglePatch(name: esp.patchProjectName, category: .esp3d)
                                },
                                onEyeTap: {
                                    withAnimation(.spring()) {
                                        previewImage = (id: esp.id, title: esp.title, assetName: esp.assetName)
                                    }
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
                            assetName: nil,
                            onToggle: {
                                togglePatch(name: "144 FPS", category: .fps)
                            },
                            onEyeTap: nil
                        )
                    }

                    // ── Account Safety Card ─────────────────────────────────
                    HStack(spacing: 12) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 22))
                            .foregroundColor(purpleAccent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("ANTI-BAN & PRO TIPS")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                            Text("يمكنك تشغيل خاصية من خانة Aimbot وخاصية من خانة ESP 3D في نفس الوقت بأمان.")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.purple.opacity(0.08))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(purpleAccent.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    Spacer(minLength: 40)
                }
            }

            // ── Floating Activation Toast HUD ───────────────────────────────
            if showToast, let message = toastMessage {
                VStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.green)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("تم التفعيل بنجاح")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(.white)
                            Text(message)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(purpleAccent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.10, green: 0.07, blue: 0.18).opacity(0.95))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(purpleAccent.opacity(0.6), lineWidth: 1.5)
                    )
                    .shadow(color: purpleAccent.opacity(0.35), radius: 16, y: 6)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()
                }
                .zIndex(10)
            }

            // ── Interactive Eye Image Preview Modal ─────────────────────────
            if let preview = previewImage {
                ZStack {
                    // Dark blurred backdrop
                    Color.black.opacity(0.82)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring()) { previewImage = nil }
                        }

                    VStack(spacing: 16) {
                        // Modal Header
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "eye.fill")
                                    .foregroundColor(purpleAccent)
                                Text(preview.title)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring()) {
                                    previewImage = nil
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                        }

                        // Preview Image Container
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.black.opacity(0.6))
                                .frame(height: 280)

                            if let uiImg = UIImage(named: preview.assetName) {
                                Image(uiImage: uiImg)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 270)
                                    .cornerRadius(12)
                            } else {
                                Image(preview.assetName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 270)
                                    .cornerRadius(12)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(purpleAccent.opacity(0.4), lineWidth: 1)
                        )

                        Text("انقر في أي مكان أو على زر الإغلاق لإخفاء الصورة")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color(red: 0.12, green: 0.08, blue: 0.22).opacity(0.96))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(purpleAccent.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: purpleAccent.opacity(0.4), radius: 24)
                    .padding(.horizontal, 24)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                .zIndex(20)
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
        assetName: String?,
        onToggle: @escaping () -> Void,
        onEyeTap: (() -> Void)?
    ) -> some View {
        HStack(spacing: 12) {
            // Main clickable area for toggling patch
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

                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .gray.opacity(0.9))

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
            }
            .buttonStyle(.plain)

            // Eye Preview Button
            if let onEyeTap = onEyeTap, assetName != nil {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onEyeTap()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                previewImage?.assetName == assetName
                                    ? purpleAccent.opacity(0.3)
                                    : Color.white.opacity(0.06)
                            )
                            .frame(width: 34, height: 34)

                        Image(systemName: previewImage?.assetName == assetName ? "eye.fill" : "eye")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(
                                previewImage?.assetName == assetName
                                    ? purpleGlow
                                    : .gray.opacity(0.8)
                            )
                    }
                }
                .buttonStyle(.plain)
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
        .padding(.horizontal, 20)
    }

    // ── Patch Toggle Logic with Sound & Haptics ─────────────────────────────
    enum PatchCategory {
        case aimbot
        case esp3d
        case fps
    }

    private func togglePatch(name: String, category: PatchCategory) {
        // Haptic feedback & activation chime
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AudioServicesPlaySystemSound(1057) // Keypad/shutter click

        switch category {
        case .aimbot:
            if activeAimbotName == name {
                // Deactivate if tapped again
                activeAimbotName = nil
                return
            }
            activeAimbotName = name
            applySinglePatch(targetPatchName: name)

        case .esp3d:
            if active3DName == name {
                // Deactivate if tapped again
                active3DName = nil
                return
            }
            active3DName = name
            applySinglePatch(targetPatchName: name)

        case .fps:
            if is144FPSActive {
                is144FPSActive = false
                return
            }
            is144FPSActive = true
            applySinglePatch(targetPatchName: "144 FPS")
        }
    }

    private func applySinglePatch(targetPatchName: String) {
        guard let item = store.items.first(where: { $0.project?.name == targetPatchName }),
              let baseProject = item.project else {
            alertMessage = "Patch \(targetPatchName) not found in library."
            showAlert = true
            return
        }

        applyingPatchName = targetPatchName

        Task.detached(priority: .userInitiated) {
            do {
                let project = item.summary.schemaVersion >= 2
                    ? try PatchProjectLibrary.synchronizeWorkspace(item: item)
                    : baseProject
                _ = try DevicePatchService.apply(project: project)

                await MainActor.run {
                    self.applyingPatchName = nil

                    // Play success sound & haptic notification
                    AudioServicesPlayAlertSound(1054) // Payment/action success chime
                    UINotificationFeedbackGenerator().notificationOccurred(.success)

                    // Trigger elegant Toast HUD
                    self.toastMessage = "\(targetPatchName) جاهز الآن في اللعبة"
                    withAnimation(.spring()) {
                        self.showToast = true
                    }

                    // Auto dismiss toast after 2.5s
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.showToast = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.applyingPatchName = nil
                    self.alertMessage = "Failed to apply: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
}
