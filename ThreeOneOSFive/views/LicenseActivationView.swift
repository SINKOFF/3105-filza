import SwiftUI
import AVKit
import AVFoundation
import UIKit

// ── Looping Video Player for Background / Header ────────────────────────────
struct LoopingVideoPlayer: UIViewControllerRepresentable {
    let videoURL: URL?
    var isMuted: Bool

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.view.backgroundColor = .clear

        if let url = videoURL {
            let player = AVPlayer(url: url)
            player.isMuted = isMuted
            player.actionAtItemEnd = .none

            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                player.seek(to: .zero)
                player.play()
            }

            controller.player = player
            player.play()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player?.isMuted = isMuted
        if uiViewController.player?.rate == 0 {
            uiViewController.player?.play()
        }
    }
}

// ── License Activation View ─────────────────────────────────────────────────
struct LicenseActivationView: View {
    @ObservedObject var licenseService = LicenseService.shared
    @State private var inputKey: String = ""
    @State private var isMuted: Bool = true

    // Resolve local video URL
    private var videoURL: URL? {
        if let url = Bundle.main.url(forResource: "bg", withExtension: "mp4") {
            return url
        }
        if let url = Bundle.main.url(forResource: "bg", withExtension: "mp4", subdirectory: "login vd") {
            return url
        }
        return nil
    }

    // Color Palette
    private let purpleAccent = Color(red: 0.65, green: 0.35, blue: 0.98)
    private let cyanAccent = Color(red: 0.15, green: 0.78, blue: 0.98)
    private let pinkAccent = Color(red: 0.95, green: 0.30, blue: 0.65)
    private let darkBg = Color(red: 0.04, green: 0.03, blue: 0.07)
    private let cardBg = Color(red: 0.08, green: 0.06, blue: 0.12)

    var body: some View {
        ZStack {
            // Background
            darkBg
                .ignoresSafeArea()

            // Ambient background glow
            VStack {
                Circle()
                    .fill(purpleAccent.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 90)
                    .offset(y: -120)
                Spacer()
                Circle()
                    .fill(pinkAccent.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .blur(radius: 80)
                    .offset(y: 100)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // ── Header Title & Badge ────────────────────────────────
                    VStack(spacing: 12) {
                        Text("PROXY FF VIP")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [cyanAccent, purpleAccent, pinkAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: purpleAccent.opacity(0.5), radius: 12)

                        // Secure Gateway Badge
                        HStack(spacing: 7) {
                            Circle()
                                .fill(purpleAccent)
                                .frame(width: 7, height: 7)
                                .shadow(color: purpleAccent, radius: 4)

                            Text("SECURE GATEWAY")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.9))
                                .tracking(1.2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.14, green: 0.08, blue: 0.24).opacity(0.85))
                        )
                        .overlay(
                            Capsule()
                                .stroke(purpleAccent.opacity(0.55), lineWidth: 1.2)
                        )
                    }
                    .padding(.top, 20)

                    // ── Video Container with Audio Toggle ───────────────────
                    ZStack(alignment: .topTrailing) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.black)

                            if let url = videoURL {
                                LoopingVideoPlayer(videoURL: url, isMuted: isMuted)
                                    .cornerRadius(18)
                            } else {
                                // Fallback static image/poster if video resource path differs
                                Image("SINKOPhoto")
                                    .resizable()
                                    .scaledToFill()
                                    .cornerRadius(18)
                            }
                        }
                        .frame(height: 310)
                        .clipped()
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    LinearGradient(
                                        colors: [purpleAccent.opacity(0.6), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: purpleAccent.opacity(0.3), radius: 18, y: 6)

                        // Sound Toggle Button
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            isMuted.toggle()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .frame(width: 38, height: 38)
                                Circle()
                                    .stroke(
                                        isMuted ? purpleAccent.opacity(0.6) : Color.green.opacity(0.8),
                                        lineWidth: 1.5
                                    )
                                    .frame(width: 38, height: 38)
                                    .shadow(color: isMuted ? purpleAccent.opacity(0.5) : Color.green.opacity(0.6), radius: 6)

                                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(isMuted ? .white.opacity(0.8) : .green)
                            }
                        }
                        .padding(14)
                    }
                    .padding(.horizontal, 20)

                    // ── Enter Key Card ──────────────────────────────────────
                    VStack(spacing: 16) {
                        Text("ENTER KEY")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(2.5)

                        // Input Field
                        HStack(spacing: 0) {
                            TextField("", text: $inputKey)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .placeholder(when: inputKey.isEmpty) {
                                    Text("ENTER LICENSE KEY")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.gray.opacity(0.6))
                                        .padding(.horizontal, 16)
                                }

                            // Paste helper
                            if let clip = UIPasteboard.general.string, !clip.isEmpty, inputKey.isEmpty {
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    inputKey = clip.trimmingCharacters(in: .whitespacesAndNewlines)
                                } label: {
                                    Text("PASTE")
                                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                        .foregroundColor(cyanAccent)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(cyanAccent.opacity(0.12))
                                        .cornerRadius(6)
                                }
                                .padding(.trailing, 12)
                            }

                            if !inputKey.isEmpty {
                                Button {
                                    inputKey = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                                .padding(.trailing, 14)
                            }
                        }
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    inputKey.isEmpty
                                        ? Color.white.opacity(0.08)
                                        : purpleAccent.opacity(0.65),
                                    lineWidth: 1.2
                                )
                        )

                        // Error message
                        if let err = licenseService.errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                Text(err)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.red.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                        }

                        // Activate Button
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            AudioServicesPlaySystemSound(1057)
                            Task {
                                _ = await licenseService.verify(key: inputKey)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if licenseService.isChecking {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.85)
                                }
                                Text(licenseService.isChecking ? "VERIFYING..." : "ACTIVATE")
                                    .font(.system(size: 15, weight: .heavy, design: .monospaced))
                                    .tracking(1.5)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundColor(.white)
                            .background(
                                LinearGradient(
                                    colors: inputKey.isEmpty
                                        ? [Color.purple.opacity(0.3), Color.blue.opacity(0.2)]
                                        : [purpleAccent, Color(red: 0.45, green: 0.15, blue: 0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(purpleAccent.opacity(inputKey.isEmpty ? 0.3 : 0.8), lineWidth: 1.2)
                            )
                            .shadow(color: inputKey.isEmpty ? .clear : purpleAccent.opacity(0.4), radius: 14, y: 4)
                        }
                        .disabled(inputKey.isEmpty || licenseService.isChecking)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(cardBg.opacity(0.95))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [purpleAccent.opacity(0.4), Color.white.opacity(0.06)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .padding(.horizontal, 20)

                    // ── Footer ──────────────────────────────────────────────
                    VStack(spacing: 4) {
                        Text("SINKO VIP · ADVANCED BYPASS ENGINE")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("iOS 17 – iOS 26+ Compatible")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                    .padding(.bottom, 25)
                }
            }
        }
    }
}

// ── Placeholder View Extension Helper ───────────────────────────────────────
private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
