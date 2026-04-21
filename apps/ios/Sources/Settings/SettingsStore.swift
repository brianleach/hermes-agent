import Foundation
import Observation
import Security

@MainActor
@Observable
final class SettingsStore {
    var baseURLString: String {
        didSet { UserDefaults.standard.set(baseURLString, forKey: Self.baseURLKey) }
    }

    var model: String {
        didSet { UserDefaults.standard.set(model, forKey: Self.modelKey) }
    }

    var apiKey: String? {
        didSet {
            if let apiKey, !apiKey.isEmpty {
                Keychain.save(value: apiKey, for: Self.apiKeyKeychainKey)
            } else {
                Keychain.delete(for: Self.apiKeyKeychainKey)
            }
        }
    }

    var baseURL: URL? {
        URL(string: baseURLString)
    }

    private static let baseURLKey = "hermes.baseURL"
    private static let modelKey = "hermes.model"
    private static let apiKeyKeychainKey = "hermes.apiKey"

    init() {
        self.baseURLString = UserDefaults.standard.string(forKey: Self.baseURLKey)
            ?? "http://localhost:8642"
        self.model = UserDefaults.standard.string(forKey: Self.modelKey)
            ?? "hermes-agent"
        self.apiKey = Keychain.load(for: Self.apiKeyKeychainKey)
    }
}

enum Keychain {
    @discardableResult
    static func save(value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = data
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    static func load(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let str = String(data: data, encoding: .utf8)
        else { return nil }
        return str
    }

    @discardableResult
    static func delete(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
