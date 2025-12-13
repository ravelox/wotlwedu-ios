import Foundation

struct AuthTokens: Decodable {
    let userId: String
    let authToken: String
    let refreshToken: String
    let firstName: String?
    let lastName: String?
    let admin: Bool?
}

struct TwoFactorBootstrap: Decodable {
    let secret: String?
    let qrCode: String?
    let verificationToken: String?
}

final class AuthService {
    private let api: APIClient
    private let sessionStore: SessionStore

    init(api: APIClient, sessionStore: SessionStore) {
        self.api = api
        self.sessionStore = sessionStore
    }

    func login(email: String, password: String) async throws -> AuthTokens {
        let payload = ["email": email, "password": password]
        let endpoint = Endpoint(path: "login/", method: .post, body: try JSONEncoder.api.encode(payload))
        let response: APIResponse<AuthTokens> = try await api.send(endpoint)
        guard let data = response.data else { throw APIError.server(message: response.message ?? "Missing auth data", url: nil) }
        save(tokens: data)
        return data
    }

    func refresh() async throws -> AuthTokens {
        guard let refresh = sessionStore.refreshToken else { throw APIError.unauthorized(url: nil) }
        let payload = ["refreshToken": refresh]
        let endpoint = Endpoint(path: "login/refresh", method: .post, body: try JSONEncoder.api.encode(payload))
        let response: APIResponse<AuthTokens> = try await api.send(endpoint)
        guard let data = response.data else { throw APIError.server(message: response.message ?? "Missing auth data", url: nil) }
        save(tokens: data)
        return data
    }

    func enable2FA() async throws -> TwoFactorBootstrap {
        let endpoint = Endpoint(path: "login/2fa", method: .post)
        let response: APIResponse<TwoFactorBootstrap> = try await api.send(endpoint)
        guard let data = response.data else { throw APIError.server(message: response.message ?? "Missing 2FA data", url: nil) }
        return data
    }

    func verify2FA(verificationToken: String, authToken: String) async throws -> AuthTokens {
        let payload = ["verificationToken": verificationToken, "authToken": authToken]
        let endpoint = Endpoint(path: "login/verify2fa", method: .post, body: try JSONEncoder.api.encode(payload))
        let response: APIResponse<AuthTokens> = try await api.send(endpoint)
        guard let data = response.data else { throw APIError.server(message: response.message ?? "Missing auth data", url: nil) }
        save(tokens: data)
        return data
    }

    func requestPasswordReset(email: String) async throws {
        let endpoint = Endpoint(path: "login/resetreq", method: .post, body: try JSONEncoder.api.encode(["email": email]))
        try await api.sendWithoutDecoding(endpoint)
    }

    func resetPassword(userId: String, token: String, newPassword: String) async throws {
        let payload = ["resetToken": token, "newPassword": newPassword]
        let endpoint = Endpoint(path: "login/password/\(userId)", method: .put, body: try JSONEncoder.api.encode(payload))
        try await api.sendWithoutDecoding(endpoint)
    }

    func generate2FAVerificationToken() async throws {
        let endpoint = Endpoint(path: "login/gentoken", method: .post)
        try await api.sendWithoutDecoding(endpoint)
    }

    func logout() {
        sessionStore.reset()
    }

    private func save(tokens: AuthTokens) {
        let display = [tokens.firstName, tokens.lastName].compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        sessionStore.save(id: tokens.userId, auth: tokens.authToken, refresh: tokens.refreshToken, displayName: display, admin: tokens.admin ?? false)
    }
}
