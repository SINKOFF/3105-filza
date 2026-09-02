import Foundation
import UIKit
import Security

@MainActor
final class LicenseService: ObservableObject {
    static let shared = LicenseService()

    // ── Custom License Server Configuration ──
    private let serverURL = "https://3105-license-server.vercel.app"
    private let hmacSecret = "sinko3105_secret_key_abc789xyz"

    @Published var isActivated: Bool = false
    @Published var isChecking: Bool = false
    @Published var activeKey: String = ""
    @Published var expiryString: String = ""
    @Published var expiryDate: Date? = nil
    @Published var errorMessage: String?

    private var sessionID: String?
    // Key and Expiry stored in Keychain so they survive reinstalls and backgrounding
    private let keychainKeyTag = "com.threeoneosfive.saved.licensekey"
    private let keychainExpiryTag = "com.threeoneosfive.saved.licenseexpiry"

    init() {
        // Fast start: if valid saved key and non-expired token exist, start activated immediately
        let savedKey = loadKeychain(key: keychainKeyTag) ?? ""
        let savedExpiry = loadKeychain(key: keychainExpiryTag)
        
        var isLocallyValid = false
        if !savedKey.isEmpty {
            self.activeKey = savedKey
            if let expStr = savedExpiry, let expTs = Double(expStr) {
                if expTs > Date().timeIntervalSince1970 {
                    isLocallyValid = true
                    let expDate = Date(timeIntervalSince1970: expTs)
                    self.expiryDate = expDate
                    self.expiryString = formatExpiryDate(expDate)
                }
            } else if savedExpiry == nil {
                // Lifetime key
                isLocallyValid = true
                self.expiryString = "مدى الحياة (Lifetime)"
            }
        }

        self.isActivated = isLocallyValid
        
        // Background live verification (silent, without locking UI)
        if !savedKey.isEmpty {
            Task {
                _ = await verify(key: savedKey, silent: true)
            }
        }
    }

    // Persistent Device HWID (unique per device, survives reinstalls via Keychain)
    var deviceHWID: String {
        let tag = "com.threeoneosfive.keyauth.hwid"
        if let existing = loadKeychain(key: tag), !existing.isEmpty {
            return existing
        }
        let newID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        saveKeychain(key: tag, value: newID)
        return newID
    }

    // Verify License Key with live server check
    func verify(key: String, silent: Bool = false) async -> Bool {
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanKey.isEmpty else {
            self.isActivated = false
            deleteKeychain(key: keychainKeyTag)
            deleteKeychain(key: keychainExpiryTag)
            if !silent {
                self.isChecking = false
                self.errorMessage = "يرجى إدخال مفتاح التفعيل."
            }
            return false
        }

        if !silent {
            isChecking = true
            errorMessage = nil
        }

        do {
            guard let url = URL(string: "\(serverURL)/api/verify") else {
                throw NSError(domain: "License", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10

            let timestamp = Int(Date().timeIntervalSince1970)
            let nonce = UUID().uuidString
            let payload: [String: Any] = [
                "key": cleanKey,
                "hwid": deviceHWID,
                "timestamp": timestamp,
                "nonce": nonce
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "License", code: -2, userInfo: [NSLocalizedDescriptionKey: "فشل الاتصال بالسيرفر"])
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataObj = json["data"] as? [String: Any] else {
                throw NSError(domain: "License", code: -3, userInfo: [NSLocalizedDescriptionKey: "رد غير صالح من السيرفر"])
            }

            let success = dataObj["success"] as? Bool ?? false
            let reason = dataObj["reason"] as? String ?? ""

            if success {
                self.activeKey = cleanKey
                let expiresAt = dataObj["expiresAt"] as? String ?? "LIFETIME"

                if expiresAt == "LIFETIME" {
                    self.expiryString = "مدى الحياة (Lifetime)"
                    self.expiryDate = nil
                } else {
                    let isoFormatter = ISO8601DateFormatter()
                    if let date = isoFormatter.date(from: expiresAt) {
                        self.expiryDate = date
                        self.expiryString = formatExpiryDate(date)
                    }
                }

                self.isActivated = true
                saveKeychain(key: keychainKeyTag, value: cleanKey)
                if let exp = expiryDate {
                    saveKeychain(key: keychainExpiryTag, value: String(exp.timeIntervalSince1970))
                }
                if !silent { isChecking = false }
                return true
            } else {
                self.isActivated = false
                self.activeKey = ""
                deleteKeychain(key: keychainKeyTag)
                deleteKeychain(key: keychainExpiryTag)
                if !silent {
                    self.isChecking = false
                    self.errorMessage = translateErrorReason(reason)
                }
                return false
            }
        } catch {
            self.isActivated = false
            if !silent {
                isChecking = false
                errorMessage = "خطأ في الاتصال: \(error.localizedDescription)"
            }
            return false
        }
    }

    private func translateErrorReason(_ reason: String) -> String {
        switch reason {
        case "INVALID_KEY":  return "المفتاح غير موجود أو غير صالح."
        case "HWID_MISMATCH": return "هذا المفتاح مربوط بجهاز آيفون آخر."
        case "EXPIRED":      return "انتهت صلاحية هذا المفتاح."
        case "PAUSED":       return "تم إيقاف هذا المفتاح مؤقتاً. تواصل مع الدعم."
        case "BANNED":       return "هذا المفتاح محظور ولا يمكن استخدامه."
        case "INVALID_HWID": return "جهازك غير مدعوم أو يوجد تلاعب في معرف الجهاز."
        default: return "فشل التحقق من الترخيص."
        }
    }

    // Wipe all old KeyAuth Keychain entries — call once on upgrade
    func purgeOldKeyAuthEntries() {
        let oldTags = [
            "com.threeoneosfive.keyauth.hwid"
        ]
        for tag in oldTags {
            deleteKeychain(key: tag)
        }
    }

    private func formatExpiryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func deleteKey() {
        self.isActivated = false
        self.activeKey = ""
        self.expiryDate = nil
        self.expiryString = ""
        self.errorMessage = nil
        self.sessionID = nil
        deleteKeychain(key: keychainKeyTag)
        deleteKeychain(key: keychainExpiryTag)
    }

    private func translateKeyAuthMessage(_ msg: String) -> String {
        let lower = msg.lowercased()
        if lower.contains("invalid") || lower.contains("not found") {
            return "Key not found or invalid."
        } else if lower.contains("hwid") || lower.contains("device") {
            return "This key is locked to another device (HWID Mismatch)."
        } else if lower.contains("expired") {
            return "This key has expired."
        } else if lower.contains("paused") || lower.contains("banned") {
            return "This key is paused or banned in KeyAuth."
        }
        return msg
    }

    // ── Keychain Helpers ───────────────────────────────────────────────────
    private func saveKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let attrs: [String: Any] = [
            kSecClass as String:                 kSecClassGenericPassword,
            kSecAttrAccount as String:           key,
            kSecAttrAccessible as String:        kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String:             data
        ]
        SecItemDelete(attrs as CFDictionary)
        SecItemAdd(attrs as CFDictionary, nil)
    }

    private func loadKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  kCFBooleanTrue!,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    private func deleteKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
