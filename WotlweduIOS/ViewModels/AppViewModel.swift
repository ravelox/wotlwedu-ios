import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var config: AppConfig = .default
    @Published var isConfigured = false
    @Published var isAuthenticated = false
    @Published var isSystemAdmin = false
    @Published var isOrganizationAdmin = false
    @Published var isWorkgroupAdmin = false
    @Published var organizationId: String?
    @Published var adminWorkgroupId: String?
    @Published var displayName: String?
    @Published var serverStatus: ServerStatus?
    @Published var unreadNotifications: Int = 0
    @Published var errorMessage: String?
    @Published var activeWorkgroupId: String?

    let sessionStore = SessionStore()
    private let workgroupScopeKey = "wotlwedu-active-workgroup"

    private(set) var apiClient: APIClient?
    private(set) var authService: AuthService?
    private(set) var registerService: RegisterService?
    private(set) var domainService: WotlweduDomainService?
    private let configLoader = ConfigLoader()

    init() {
        displayName = sessionStore.displayName
        isAuthenticated = sessionStore.authToken != nil
        isSystemAdmin = sessionStore.isSystemAdmin
        isOrganizationAdmin = sessionStore.isOrganizationAdmin
        isWorkgroupAdmin = sessionStore.isWorkgroupAdmin
        organizationId = sessionStore.organizationId
        adminWorkgroupId = sessionStore.adminWorkgroupId
        activeWorkgroupId = UserDefaults.standard.string(forKey: workgroupScopeKey)
    }

    func bootstrap() {
        do {
            config = try configLoader.load()
            buildServices()
            isConfigured = true
            if isAuthenticated {
                Task {
                    await refreshStatus()
                    await refreshNotifications()
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func buildServices() {
        let api = APIClient(config: config, sessionStore: sessionStore)
        self.apiClient = api
        self.authService = AuthService(api: api, sessionStore: sessionStore)
        self.registerService = RegisterService(api: api)
        self.domainService = WotlweduDomainService(api: api)
    }

    func login(email: String, password: String) async {
        guard let authService else { return }
        do {
            let tokens = try await authService.login(email: email, password: password)
            applyAuth(tokens: tokens)
            await refreshStatus()
            await refreshNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func verify2FA(verificationToken: String, authToken: String) async {
        guard let authService else { return }
        do {
            let tokens = try await authService.verify2FA(verificationToken: verificationToken, authToken: authToken)
            applyAuth(tokens: tokens)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        authService?.logout()
        isAuthenticated = false
        isSystemAdmin = false
        isOrganizationAdmin = false
        isWorkgroupAdmin = false
        organizationId = nil
        adminWorkgroupId = nil
        displayName = nil
        serverStatus = nil
        unreadNotifications = 0
        setActiveWorkgroupId(nil)
    }

    func refreshStatus() async {
        guard let domainService else { return }
        do {
            serverStatus = try await domainService.serverStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshNotifications() async {
        guard let domainService else { return }
        do {
            unreadNotifications = try await domainService.unreadNotificationCount()
        } catch {
            // keep quiet for badge fetch failures
        }
    }

    func register(_ registration: WotlweduRegistration) async {
        guard let registerService else { return }
        do {
            try await registerService.register(registration)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmRegistration(token: String) async {
        guard let registerService else { return }
        do {
            try await registerService.confirm(token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func enable2FA() async -> TwoFactorBootstrap? {
        guard let authService else { return nil }
        do {
            return try await authService.enable2FA()
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func requestPasswordReset(email: String) async {
        guard let authService else { return }
        do {
            try await authService.requestPasswordReset(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword(userId: String, token: String, newPassword: String) async {
        guard let authService else { return }
        do {
            try await authService.resetPassword(userId: userId, token: token, newPassword: newPassword)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyAuth(tokens: AuthTokens) {
        displayName = [tokens.firstName, tokens.lastName].compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        isSystemAdmin = tokens.systemAdmin ?? (tokens.admin ?? false)
        isOrganizationAdmin = tokens.organizationAdmin ?? false
        isWorkgroupAdmin = tokens.workgroupAdmin ?? false
        organizationId = tokens.organizationId
        adminWorkgroupId = tokens.adminWorkgroupId
        isAuthenticated = true

        // Default active scope for workgroup admins when none has been selected yet.
        if (activeWorkgroupId == nil || activeWorkgroupId == "") && (tokens.workgroupAdmin ?? false), let wg = tokens.adminWorkgroupId {
            setActiveWorkgroupId(wg)
        }
    }

    func setActiveWorkgroupId(_ id: String?) {
        if let id, !id.isEmpty {
            UserDefaults.standard.set(id, forKey: workgroupScopeKey)
            activeWorkgroupId = id
        } else {
            UserDefaults.standard.removeObject(forKey: workgroupScopeKey)
            activeWorkgroupId = nil
        }
    }
}
