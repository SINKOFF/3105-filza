import Foundation
import UIKit
import Security

@MainActor
final class LicenseService: ObservableObject {
    static let shared = LicenseService()

    // KeyAuth App Configuration
    private let appName = "Dodisiso123's Application"
    private let ownerID = "a153OigV2p"
    private let appSecret = "e38f088727f95dde738a68c77d311c661ce35af5fe52dda7d1e4cd3333241e67"
    private let appVersion = "1.0"
    private let apiURL = "https://keyauth.win/api/1.3/"

    @Published var isActivated: Bool = false
    @Published var isChecking: Bool = false
    @Published var activeKey: String = ""
    @Published var expiryString: String = ""
    @Published var errorMessage: String?

    private var sessionID: String?
    private let keyStorageKey = "ThreeOneOSFive_SavedKeyAuthKey"

    init() {
        if let savedKey = UserDefaults.standard.string(forKey: keyStorageKey), !savedKey.isEmpty {
            self.activeKey = savedKey
            Task {
                await verify(key: savedKey, silent: true)
            }
        }
    }

    // Persistent Device HWID
    var deviceHWID: String {
        let tag = "com.threeoneosfive.keyauth.hwid"
        if let existing = loadKeychain(key: tag) {
            return existing
        }
        let newID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        saveKeychain(key: tag, value: newID)
        return newID
    }

    // Initialize KeyAuth Session
    private func initializeSession() async throws -> String {
        if let existing = sessionID, !existing.isEmpty {
            return existing
        }

        var components = URLComponents(string: apiURL)!
        components.queryItems = [
            URLQueryItem(name: "type", value: "init"),
            URLQueryItem(name: "name", value: appName),
            URLQueryItem(name: "ownerid", value: ownerID),
            URLQueryItem(name: "secret", value: appSecret),
            URLQueryItem(name: "ver", value: appVersion)
        ]

        guard let url = components.url else {
            throw NSError(domain: "KeyAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "KeyAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Server response error"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "KeyAuth", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }

        guard let success = json["success"] as? Bool, success,
              let sid = json["sessionid"] as? String else {
            let msg = json["message"] as? String ?? "Failed to initialize KeyAuth"
            throw NSError(domain: "KeyAuth", code: -4, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        self.sessionID = sid
        return sid
    }

    // Verify License Key
    func verify(key: String, silent: Bool = false) async -> Bool {
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            if !silent { self.errorMessage = "يرجى إدخال مفتاح الترخيص" }
            return false
        }

        if !silent {
            isChecking = true
            errorMessage = nil
        }

        do {
            let sid = try await initializeSession()
            let hwid = deviceHWID

            var components = URLComponents(string: apiURL)!
            components.queryItems = [
                URLQueryItem(name: "type", value: "license"),
                URLQueryItem(name: "key", value: cleanKey),
                URLQueryItem(name: "hwid", value: hwid),
                URLQueryItem(name: "sessionid", value: sid),
                URLQueryItem(name: "name", value: appName),
                URLQueryItem(name: "ownerid", value: ownerID)
            ]

            guard let url = components.url else {
                if !silent { isChecking = false; errorMessage = "خطأ في تكوين الرابط" }
                return false
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if !silent { isChecking = false; errorMessage = "فشل الاتصال بـ KeyAuth" }
                return false
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                if !silent { isChecking = false; errorMessage = "رد غير صالح من KeyAuth" }
                return false
            }

            let success = json["success"] as? Bool ?? false
            let message = json["message"] as? String ?? "Unknown error"

            if success {
                self.isActivated = true
                self.activeKey = cleanKey
                
                // Parse expiry info if available
                if let info = json["info"] as? [String: Any],
                   let subs = info["subscriptions"] as? [[String: Any]],
                   let firstSub = subs.first,
                   let expTimestampStr = firstSub["expiry"] as? String,
                   let expTimestamp = Double(expTimestampStr) {
                    let expDate = Date(timeIntervalSince1970: expTimestamp)
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .none
                    self.expiryString = formatter.string(from: expDate)
                } else {
                    self.expiryString = "مفعل (Active)"
                }

                UserDefaults.standard.set(cleanKey, forKey: keyStorageKey)
                if !silent { isChecking = false }
                return true
            } else {
                // If session expired, invalidate it for next try
                if message.lowercased().contains("session") {
                    self.sessionID = nil
                }
                
                self.isActivated = false
                UserDefaults.standard.removeObject(forKey: keyStorageKey)
                if !silent {
                    isChecking = false
                    self.errorMessage = translateKeyAuthMessage(message)
                }
                return false
            }
        } catch {
            self.sessionID = nil
            if !silent {
                isChecking = false
                errorMessage = "خطأ في الاتصال: \(error.localizedDescription)"
            }
            return false
        }
    }

    private func translateKeyAuthMessage(_ msg: String) -> String {
        let lower = msg.lowercased()
        if lower.contains("invalid") || lower.contains("not found") {
            return "المفتاح غير موجود أو خاطئ"
        } else if lower.contains("hwid") || lower.contains("device") {
            return "هذا المفتاح مستخدم على جهاز آخر (HWID Mismatch)"
        } else if lower.contains("expired") {
            return "انتهت صلاحية هذا المفتاح"
        } else if lower.contains("paused") || lower.contains("banned") {
            return "المفتاح محظور أو موقوف"
        }
        return msg
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
