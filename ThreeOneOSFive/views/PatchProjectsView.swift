import SwiftUI
import UIKit

struct PatchProjectsView: View {
    @StateObject private var store = PatchProjectStore()
    @State private var selectedGame: GameVersion = .normal
    @State private var activePatchName: String? = nil
    @State private var isApplying: Bool = false
    @State private var alertMessage: String? = nil
    @State private var showAlert: Bool = false

    // ESP placeholder toggles
    @State private var espGreen: Bool = false
    @State private var espCyan: Bool = false

    enum GameVersion: String, CaseIterable {
        case normal = "Free Fire"
        case max = "FF Max"
    }

    // Aimbot items configuration
    private let aimbotList: [(id: String, title: String, patchProjectName: String)] = [
        ("drag",    "Drag",      "AIM DRAG"),
        ("neck",    "Neck",      "AIM NECK"),
        ("body100", "Body 100%", "AIM BODY 100%"),
        ("body80",  "Body 80%",  "AIM BODY 80%"),
        ("magic",   "Magic",     "AIM MGIC")
    ]

    var body: some View {
        ZStack {
            // Dark Futuristic Background
            Color(red: 0.05, green: 0.06, blue: 0.08)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {

                    // ── Top Header ──────────────────────────────────────────
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PATCHES")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)

                            HStack(spacing: 6) {
                                Text("external - iOS")
                                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)

                                Text("SINKO")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.yellow.opacity(0.2))
                                    .foregroundColor(.yellow)
                                    .cornerRadius(4)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // ── Game Segmented Selector ──────────────────────────────
                    HStack(spacing: 0) {
                        ForEach(GameVersion.allCases, id: \.self) { game in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedGame = game
                                }
                            } label: {
                                Text(game.rawValue)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(selectedGame == game ? .black : .gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedGame == game ? Color.white : Color.clear
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(24)
                    .padding(.horizontal, 20)

                    // ── Status / Hero Card ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(selectedGame == .normal ? "FREE FIRE" : "FREE FIRE MAX")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.gray)

                            Spacer()

                            HStack(spacing: 5) {
                                Circle()
                                    .fill(activePatchName != nil ? Color.green : Color.gray)
                                    .frame(width: 7, height: 7)
                                Text(activePatchName != nil ? "ACTIVE" : "READY")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(activePatchName != nil ? .green : .gray)
                            }
                        }

                        Text(activePatchName != nil ? activePatchName! : "Choose aim")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(activePatchName != nil ? "1-Tap Applied Successfully" : "Select an aimbot to apply instantly")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(18)
                    .padding(.horizontal, 20)

                    // ── AIMBOTS Section ─────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Text("AIMBOTS")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.8))
                            .padding(.horizontal, 24)

                        ForEach(aimbotList, id: \.id) { aim in
                            let isSelected = (activePatchName == aim.patchProjectName)

                            Button {
                                toggleAimbot(aim.patchProjectName)
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isSelected ? Color.green : Color.gray.opacity(0.5), lineWidth: 1.5)
                                            .frame(width: 22, height: 22)

                                        if isSelected {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.green)
                                                .frame(width: 14, height: 14)
                                        }
                                    }

                                    Text(aim.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : .gray.opacity(0.9))

                                    Spacer()

                                    if isApplying && isSelected {
                                        ProgressView()
                                            .tint(.green)
                                            .scaleEffect(0.8)
                                    } else if isSelected {
                                        Text("ON")
                                            .font(.system(size: 11, weight: .heavy))
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.green.opacity(0.15))
                                            .cornerRadius(6)
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(isSelected ? 0.09 : 0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isSelected ? Color.green.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }
                    }

                    // ── ESP Section ─────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ESP")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.8))
                            .padding(.horizontal, 24)

                        espRow(label: "Green", color: .green, isOn: $espGreen)
                        espRow(label: "Cyan",  color: .cyan,  isOn: $espCyan)
                    }

                    // ── Safety Tip ──────────────────────────────────────────
                    VStack(spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 11))
                                .foregroundColor(.orange.opacity(0.7))
                            Text("ACCOUNT SAFETY TIP")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange.opacity(0.7))
                        }

                        Text("If you want to play on your main account, use Aim Drag — it has the lowest detection risk.")
                            .font(.system(size: 11))
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 30)
                }
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

    // ── ESP Row Builder ─────────────────────────────────────────────────────
    @ViewBuilder
    private func espRow(label: String, color: Color, isOn: Binding<Bool>) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isOn.wrappedValue ? color : Color.gray.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    if isOn.wrappedValue {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: 14, height: 14)
                    }
                }

                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isOn.wrappedValue ? .white : .gray.opacity(0.9))

                Spacer()

                if isOn.wrappedValue {
                    Text("ON")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(color.opacity(0.15))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color.white.opacity(isOn.wrappedValue ? 0.09 : 0.05))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isOn.wrappedValue ? color.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    // ── 1-Tap Instant Apply ─────────────────────────────────────────────────
    private func toggleAimbot(_ targetPatchName: String) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if activePatchName == targetPatchName { return }

        guard let item = store.items.first(where: { $0.project?.name == targetPatchName }),
              let baseProject = item.project else {
            alertMessage = "Patch \(targetPatchName) not found in library."
            showAlert = true
            return
        }

        isApplying = true
        activePatchName = targetPatchName

        Task.detached(priority: .userInitiated) {
            do {
                let project = item.summary.schemaVersion >= 2
                    ? try PatchProjectLibrary.synchronizeWorkspace(item: item)
                    : baseProject
                _ = try DevicePatchService.apply(project: project)

                await MainActor.run {
                    self.isApplying = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    self.isApplying = false
                    self.alertMessage = "Failed to apply: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
}
