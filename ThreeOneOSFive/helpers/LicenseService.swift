import Foundation
import UIKit
import CryptoKit
import Security

@MainActor
final class LicenseService: ObservableObject {
    static let shared = LicenseService()

    // 🛡️ Change this to your deployed server URL (e.g., https://your-app.vercel.app)
    @Published var serverURL: String = "https://3105-license.vercel.app"

    // 🛡️ Secret HMAC Key matching server
    private let hmacSecret = "3105_SECURE_HMAC_KEY_98F7A12BC83"

    @Published var isActivated: Bool = false
    @Published var isChecking: Bool = false
    @Published var activeKey: String = ""
    @Published var expiryString: String = ""
    @Published var errorMessage: String?

    private let keyStorageKey = "ThreeOneOSFive_SavedLicenseKey"
    private let tokenStorageKey = "ThreeOneOSFive_VerifiedToken"

    init() {
        if let savedKey = UserDefaults.standard.string(forKey: keyStorageKey), !savedKey.isEmpty {
            self.activeKey = savedKey
            // Perform background re-validation
            Task {
                await verify(key: savedKey, silent: true)
            }
        }
    }

    // Persistent Unique Hardware ID
    var deviceHWID: String {
        let tag = "com.threeoneosfive.devicehwid"
        if let existing = loadKeychain(key: tag) {
            return existing
        }
        let newID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        saveKeychain(key: tag, value: newID)
        return newID
    }

    func verify(key: String, silent: Bool = false) async -> Bool {
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanKey.isEmpty else {
            if !silent { self.errorMessage = "يرجى إدخال مفتاح الترخيص" }
            return false
        }

        if !silent {
            isChecking = true
            errorMessage = nil
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let nonce = UUID().uuidString
        let hwid = deviceHWID

        let requestBody: [String: Any] = [
            "key": cleanKey,
            "hwid": hwid,
            "timestamp": timestamp,
            "nonce": nonce
        ]

        guard let url = URL(string: "\(serverURL)/api/verify"),
              let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            if !silent {
                isChecking = false
                errorMessage = "خطأ في الاتصال بالسيرفر"
            }
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if !silent {
                    isChecking = false
                    errorMessage = "فشل الاتصال بالسيرفر (كود \((response as? HTTPURLResponse)?.statusCode ?? 0))"
                }
                return false
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataDict = json["data"] as? [String: Any],
                  let serverSignature = json["signature"] as? String else {
                if !silent {
                    isChecking = false
                    errorMessage = "رد غير صالح من السيرفر"
                }
                return false
            }

            // 🛡️ Cryptographic HMAC Verification (Anti-Tamper & Anti-MITM)
            let serializedData = try JSONSerialization.data(withJSONObject: dataDict)
            let key = SymmetricKey(data: Data(hmacSecret.utf8))
            let calculatedHMAC = HMAC<SHA256>.authenticationCode(for: serializedData, using: key)
            let calculatedHex = calculatedHMAC.map { String(format: "%02hhx", $0) }.joined()

            guard calculatedHex.lowercased() == serverSignature.lowercased() else {
                if !silent {
                    isChecking = false
                    errorMessage = "تم كشف تلاعب بالرد! (Security Tamper Detected)"
                }
                return false
            }

            let success = dataDict["success"] as? Bool ?? false
            if success {
                let expiresAt = dataDict["expiresAt"] as? String ?? "LIFETIME"
                self.isActivated = true
                self.activeKey = cleanKey
                self.expiryString = expiresAt == "LIFETIME" ? "مدى الحياة" : expiresAt
                UserDefaults.standard.set(cleanKey, forKey: keyStorageKey)
                if !silent { isChecking = false }
                return true
            } else {
                let reason = dataDict["reason"] as? String ?? "UNKNOWN"
                self.isActivated = false
                UserDefaults.standard.removeObject(forKey: keyStorageKey)
                if !silent {
                    isChecking = false
                    switch reason {
                    case "INVALID_KEY":
                        self.errorMessage = "المفتاح غير صحيح أو غير موجود"
                    case "HWID_MISMATCH":
                        self.errorMessage = "هذا المفتاح مفعل على جهاز آخر! (HWID Mismatch)"
                    case "EXPIRED":
                        self.errorMessage = "انتهت صلاحية هذا المفتاح"
                    default:
                        self.errorMessage = "فشل التفعيل: \(reason)"
                    }
                }
                return false
            }
        } catch {
            if !silent {
                isChecking = false
                errorMessage = "خطأ في الشبكة: \(error.localizedDescription)"
            }
            return false
        }
    }

    // Keychain Helpers
    private func saveKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
