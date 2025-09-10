import Foundation

#if canImport(Security)
import Security

struct TokenStore {
    private let service = "com.example.wotlweduclient.tokens"
    private let account = "auth"

    func save(tokens: AppTokens) throws {
        let data = try JSONEncoder().encode(tokens)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }

    func load() -> AppTokens? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(AppTokens.self, from: data)
    }

    func clear() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
    }
}
#else
// On platforms without the Security framework (e.g. Linux), provide a minimal
// no-op implementation so the codebase can be typechecked.
struct TokenStore {
    func save(tokens: AppTokens) throws {}
    func load() -> AppTokens? { nil }
    func clear() {}
}
#endif

