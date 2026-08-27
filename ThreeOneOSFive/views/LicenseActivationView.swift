import SwiftUI

struct LicenseActivationView: View {
    @ObservedObject var licenseService = LicenseService.shared
    @State private var inputKey: String = ""

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.09),
                    Color(red: 0.06, green: 0.08, blue: 0.14)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 40)

                    // ── Branding ───────────────────────────────────────────
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.blue.opacity(0.35), Color.cyan.opacity(0.15)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 96, height: 96)
                            Circle()
                                .stroke(Color.cyan.opacity(0.25), lineWidth: 1.5)
                                .frame(width: 96, height: 96)

                            Image(systemName: "key.horizontal.fill")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(colors: [.cyan, .blue],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }

                        VStack(spacing: 6) {
                            Text("SINKO")
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)

                            Text("Enter your license key to unlock the app")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                    }

                    // ── Key Input + Activate ────────────────────────────────
                    VStack(spacing: 16) {
                        // Text Field
                        HStack(spacing: 0) {
                            TextField("VIP-XXXX-XXXX-XXXX", text: $inputKey)
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding(14)

                            // Paste button
                            if let clip = UIPasteboard.general.string, !clip.isEmpty, inputKey.isEmpty {
                                Button("Paste") {
                                    inputKey = clip.trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.cyan)
                                .padding(.trailing, 14)
                            }

                            // Clear button
                            if !inputKey.isEmpty {
                                Button {
                                    inputKey = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                                .padding(.trailing, 14)
                            }
                        }
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    inputKey.isEmpty
                                        ? Color.white.opacity(0.12)
                                        : Color.cyan.opacity(0.4),
                                    lineWidth: 1
                                )
                        )

                        // Error
                        if let err = licenseService.errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                Text(err)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.red.opacity(0.85))
                            .padding(.horizontal, 6)
                        }

                        // Activate Button
                        Button {
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
                                Text(licenseService.isChecking ? "Verifying..." : "Activate License")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .foregroundColor(.white)
                            .background(
                                LinearGradient(
                                    colors: inputKey.isEmpty
                                        ? [Color.gray.opacity(0.4), Color.gray.opacity(0.3)]
                                        : [Color.blue, Color.cyan],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: inputKey.isEmpty ? .clear : Color.blue.opacity(0.4),
                                    radius: 12, y: 5)
                        }
                        .disabled(inputKey.isEmpty || licenseService.isChecking)
                    }
                    .padding(.horizontal, 20)

                    // ── Footer ─────────────────────────────────────────────
                    VStack(spacing: 4) {
                        Text("SINKO · Security Engine")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.45))
                        Text("Device Protection · License Lock")
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }
}
