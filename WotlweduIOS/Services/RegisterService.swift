import Foundation

final class RegisterService {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func register(_ registration: WotlweduRegistration) async throws {
        let endpoint = Endpoint(path: "register", method: .post, body: try JSONEncoder.api.encode(registration), requiresAuth: false)
        try await api.sendWithoutDecoding(endpoint)
    }

    func confirm(_ token: String) async throws {
        let endpoint = Endpoint(path: "register/confirm/\(token)", method: .get, requiresAuth: false)
        try await api.sendWithoutDecoding(endpoint)
    }
}
