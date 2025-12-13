import Foundation

final class SessionStore: ObservableObject {
    private struct Stored: Codable {
        var id: String?
        var authToken: String?
        var refreshToken: String?
        var displayName: String?
        var admin: Bool?
    }

    @Published private(set) var userId: String?
    @Published private(set) var authToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var displayName: String?
    @Published private(set) var isAdmin: Bool = false

    private let storageKey = "wotlwedu-auth"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func save(id: String?, auth: String?, refresh: String?, displayName: String?, admin: Bool) {
        userId = id
        authToken = auth
        refreshToken = refresh
        self.displayName = displayName
        isAdmin = admin

        let stored = Stored(id: id, authToken: auth, refreshToken: refresh, displayName: displayName, admin: admin)
        if let data = try? JSONEncoder().encode(stored) {
            defaults.set(data, forKey: storageKey)
        }
    }

    func reset() {
        userId = nil
        authToken = nil
        refreshToken = nil
        displayName = nil
        isAdmin = false
        defaults.removeObject(forKey: storageKey)
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode(Stored.self, from: data) else { return }
        userId = stored.id
        authToken = stored.authToken
        refreshToken = stored.refreshToken
        displayName = stored.displayName
        isAdmin = stored.admin ?? false
    }
}
