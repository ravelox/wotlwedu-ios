import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    private(set) var tokens: AuthTokens? {
        didSet { isAuthenticated = tokens?.accessToken.isEmpty == false }
    }
    private(set) var api: APIClient?
    private let tokenStore = TokenStore()
    let config = ConfigStore()

    init() {}

    private func makeEndpoints() -> Endpoints {
        Endpoints(baseURLString: config.baseURLString, timeout: config.timeout)
    }

    func signIn(email: String, password: String) async throws {
        let client = APIClient(endpoints: makeEndpoints(), tokenProvider: { [weak self] in self?.tokens?.accessToken })
        let tokens = try await client.login(email: email, password: password)
        self.tokens = tokens
        try tokenStore.save(tokens: tokens)
        self.api = APIClient(endpoints: makeEndpoints(), tokenProvider: { [weak self] in self?.tokens?.accessToken })
        _ = try? await api?.me()
    }

    func register(email: String, password: String, name: String?) async throws {
        let client = APIClient(endpoints: makeEndpoints(), tokenProvider: { [weak self] in self?.tokens?.accessToken })
        let tokens = try await client.register(email: email, password: password, name: name)
        self.tokens = tokens
        try tokenStore.save(tokens: tokens)
        self.api = APIClient(endpoints: makeEndpoints(), tokenProvider: { [weak self] in self?.tokens?.accessToken })
        _ = try? await api?.me()
    }

    func restore() async {
        if let t = tokenStore.load() {
            self.tokens = t
            self.api = APIClient(endpoints: makeEndpoints(), tokenProvider: { [weak self] in self?.tokens?.accessToken })
        } else {
            self.tokens = nil
        }
    }

    func signOut() {
        tokenStore.clear()
        tokens = nil
        api = nil
    }

    func rebuildAPI() {
        self.api = APIClient(endpoints: makeEndpoints(), tokenProvider: { [weak self] in self?.tokens?.accessToken })
    }

    static var preview: SessionStore {
        let s = SessionStore()
        s.tokens = AuthTokens(accessToken: "preview", refreshToken: nil)
        s.api = APIClient(endpoints: s.makeEndpoints(), tokenProvider: { "preview" })
        return s
    }
}