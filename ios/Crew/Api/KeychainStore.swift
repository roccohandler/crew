// SPEC: Part IV (Keychain, no third-party dependency) · 8.7 (Keychain-only tokens — static check: no UserDefaults for
// tokens) · C6 (no clever code: four plain Security calls). WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import Security

struct KeychainStore {
    let service: String

    func read(_ key: String) -> String? {
        guard let data = readData(key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func readData(_ key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    func write(_ key: String, _ value: String) {
        writeData(key, Data(value.utf8))
    }

    func writeData(_ key: String, _ data: Data) {
        delete(key)
        let item: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data,
        ]
        SecItemAdd(item as CFDictionary, nil)
    }

    func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
