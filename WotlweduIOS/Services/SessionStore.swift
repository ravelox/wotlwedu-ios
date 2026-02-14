import Foundation

final class SessionStore: ObservableObject {
    private struct Stored: Codable {
        var id: String?
        var authToken: String?
        var refreshToken: String?
        var displayName: String?
        var admin: Bool?
        var systemAdmin: Bool?
        var organizationId: String?
        var organizationAdmin: Bool?
        var workgroupAdmin: Bool?
        var adminWorkgroupId: String?
    }

    @Published private(set) var userId: String?
    @Published private(set) var authToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var displayName: String?
    @Published private(set) var isAdmin: Bool = false
    @Published private(set) var isSystemAdmin: Bool = false
    @Published private(set) var organizationId: String?
    @Published private(set) var isOrganizationAdmin: Bool = false
    @Published private(set) var isWorkgroupAdmin: Bool = false
    @Published private(set) var adminWorkgroupId: String?

    private let storageKey = "wotlwedu-auth"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func save(
        id: String?,
        auth: String?,
        refresh: String?,
        displayName: String?,
        admin: Bool,
        systemAdmin: Bool,
        organizationId: String?,
        organizationAdmin: Bool,
        workgroupAdmin: Bool,
        adminWorkgroupId: String?
    ) {
        userId = id
        authToken = auth
        refreshToken = refresh
        self.displayName = displayName
        isAdmin = admin
        isSystemAdmin = systemAdmin
        self.organizationId = organizationId
        isOrganizationAdmin = organizationAdmin
        isWorkgroupAdmin = workgroupAdmin
        self.adminWorkgroupId = adminWorkgroupId

        let stored = Stored(
            id: id,
            authToken: auth,
            refreshToken: refresh,
            displayName: displayName,
            admin: admin,
            systemAdmin: systemAdmin,
            organizationId: organizationId,
            organizationAdmin: organizationAdmin,
            workgroupAdmin: workgroupAdmin,
            adminWorkgroupId: adminWorkgroupId
        )
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
        isSystemAdmin = false
        organizationId = nil
        isOrganizationAdmin = false
        isWorkgroupAdmin = false
        adminWorkgroupId = nil
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
        isSystemAdmin = stored.systemAdmin ?? (stored.admin ?? false)
        organizationId = stored.organizationId
        isOrganizationAdmin = stored.organizationAdmin ?? false
        isWorkgroupAdmin = stored.workgroupAdmin ?? false
        adminWorkgroupId = stored.adminWorkgroupId
    }
}
