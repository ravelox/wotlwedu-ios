import Foundation

/// Stores configuration used by the backend client.
enum GeneratedSDKConfig {
    private static var baseURL: String = ConfigStore().baseURLString
    private static var bearerToken: String?

    /// Applies the latest base URL and bearer token. Called whenever the
    /// session changes.
    static func apply(baseURL: String, bearerToken: String?) {
        self.baseURL = baseURL
        self.bearerToken = bearerToken
    }

    /// Creates an ``APIClient`` configured with the current settings.
    fileprivate static func apiClient() -> APIClient {
        let cfg = ConfigStore()
        let eps = Endpoints(baseURLString: baseURL, timeout: cfg.timeout)
        return APIClient(endpoints: eps, tokenProvider: { bearerToken })
    }
}

/// Thin wrapper around ``APIClient`` exposing the functions the rest of the
/// app expects from the generated backend.
enum GeneratedBackend {
    static func login(email: String, password: String) async throws -> AppTokens {
        try await GeneratedSDKConfig.apiClient().login(email: email, password: password)
    }

    static func register(email: String, password: String, name: String?) async throws -> AppTokens {
        try await GeneratedSDKConfig.apiClient().register(email: email, password: password, name: name)
    }

    static func me() async throws -> AppUser {
        try await GeneratedSDKConfig.apiClient().me()
    }

    static func listElections() async throws -> [AppElection] {
        try await GeneratedSDKConfig.apiClient().listElections()
    }

    static func getElection(id: Int) async throws -> AppElection {
        try await GeneratedSDKConfig.apiClient().getElection(id: id)
    }

    static func createElection(name: String, description: String?) async throws -> AppElection {
        try await GeneratedSDKConfig.apiClient().createElection(name: name, description: description)
    }

    static func createItem(electionId: Int, name: String, description: String?) async throws -> AppElectionItem {
        try await GeneratedSDKConfig.apiClient().createItem(electionId: electionId, name: name, description: description)
    }

    static func vote(electionId: Int, itemId: Int) async throws {
        try await GeneratedSDKConfig.apiClient().vote(electionId: electionId, itemId: itemId)
    }
}

