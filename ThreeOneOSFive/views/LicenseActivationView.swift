import SwiftUI

struct LicenseActivationView: View {
    @ObservedObject var licenseService = LicenseService.shared
    @State private var inputKey: String = ""
    @State private var copiedHWID: Bool = false

    var body: some View {
        ZStack {
            // Dark futuristic background
            Color(red: 0.05, green: 0.07, blue: 0.10)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Header Icon & Title
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 90, height: 90)

                        Image(systemName: "key.horizontal.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }

                    Text("تفعيل تطبيق 3105")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)

                    Text("أدخل مفتاح الترخيص الخاص بك للوصول إلى كافة الميزات")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }

                // Device ID (HWID) Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "iphone.gen3")
                            .foregroundColor(.cyan)
                        Text("معرف جهازك (Device HWID)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.gray)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = licenseService.deviceHWID
                            copiedHWID = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copiedHWID = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: copiedHWID ? "checkmark" : "doc.on.doc")
                                Text(copiedHWID ? "تم النسخ" : "نسخ")
                            }
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cyan.opacity(0.15))
                            .cornerRadius(6)
                        }
                    }

                    Text(licenseService.deviceHWID)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(8)
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(14)
                .padding(.horizontal, 20)

                // Key Input Field
                VStack(spacing: 12) {
                    HStack {
                        TextField("VIP-XXXX-XXXX-XXXX", text: $inputKey)
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding(14)

                        if let clip = UIPasteboard.general.string, !clip.isEmpty {
                            Button("لصق") {
                                inputKey = clip
                            }
                            .font(.caption.weight(.bold))
                            .foregroundColor(.cyan)
                            .padding(.trailing, 14)
                        }
                    }
                    .background(Color.white.opacity(0.07))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )

                    // Error Message
                    if let err = licenseService.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(err)
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                    }

                    // Activate Button
                    Button {
                        Task {
                            _ = await licenseService.verify(key: inputKey)
                        }
                    } label: {
                        HStack {
                            if licenseService.isChecking {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 6)
                            }
                            Text(licenseService.isChecking ? "جاري التحقق..." : "تفعيل المفتاح الآن")
                                .font(.headline.weight(.bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.4), radius: 10, y: 5)
                    }
                    .disabled(inputKey.isEmpty || licenseService.isChecking)
                    .opacity(inputKey.isEmpty ? 0.6 : 1.0)
                }
                .padding(.horizontal, 20)

                Spacer()

                Text("3105 Security Engine • Cryptographic Verification")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.bottom, 10)
            }
        }
    }
}
