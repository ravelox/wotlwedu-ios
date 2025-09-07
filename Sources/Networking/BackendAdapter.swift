import Foundation

protocol Backend {
    func login(email: String, password: String) async throws -> AuthTokens
    func register(email: String, password: String, name: String?) async throws -> AuthTokens
    func me() async throws -> UserProfile
    func listElections() async throws -> [Election]
    func getElection(id: Int) async throws -> Election
    func createElection(name: String, description: String?) async throws -> Election
    func createItem(electionId: Int, name: String, description: String?) async throws -> ElectionItem
    func vote(electionId: Int, itemId: Int) async throws
    func uploadElectionImage(electionId: Int, data: Data, filename: String, mime: String) async throws
    func uploadItemImage(electionId: Int, itemId: Int, data: Data, filename: String, mime: String) async throws
}

final class ManualBackend: Backend {
    private let api: APIClient
    init(tokenProvider: @escaping () -> String?) {
        let cfg = ConfigStore()
        let eps = Endpoints(baseURLString: cfg.baseURLString, timeout: cfg.timeout)
        self.api = APIClient(endpoints: eps, tokenProvider: tokenProvider)
    }
    func login(email: String, password: String) async throws -> AuthTokens { try await api.login(email: email, password: password) }
    func register(email: String, password: String, name: String?) async throws -> AuthTokens { try await api.register(email: email, password: password, name: name) }
    func me() async throws -> UserProfile { try await api.me() }
    func listElections() async throws -> [Election] { try await api.listElections() }
    func getElection(id: Int) async throws -> Election { try await api.getElection(id: id) }
    func createElection(name: String, description: String?) async throws -> Election { try await api.createElection(name: name, description: description) }
    func createItem(electionId: Int, name: String, description: String?) async throws -> ElectionItem { try await api.createItem(electionId: electionId, name: name, description: description) }
    func vote(electionId: Int, itemId: Int) async throws { try await api.vote(electionId: electionId, itemId: itemId) }
    func uploadElectionImage(electionId: Int, data: Data, filename: String, mime: String) async throws { try await api.uploadElectionImage(electionId: electionId, data: data, filename: filename, mime: mime) }
    func uploadItemImage(electionId: Int, itemId: Int, data: Data, filename: String, mime: String) async throws { try await api.uploadItemImage(electionId: electionId, itemId: itemId, data: data, filename: filename, mime: mime) }
}