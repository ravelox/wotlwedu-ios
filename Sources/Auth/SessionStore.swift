import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    private(set) var tokens: AppTokens? {
        didSet { isAuthenticated = tokens?.accessToken.isEmpty == false }
    }
    private let tokenStore = TokenStore()
    let config = ConfigStore()
    
    init() {}
    
    func signIn(email: String, password: String) async throws {
        let t = try await GeneratedBackend.login(email: email, password: password)
        self.tokens = t
        try tokenStore.save(tokens: t)
        configureGeneratedSDK()
    }
    
    func register(email: String, password: String, name: String?) async throws {
        let t = try await GeneratedBackend.register(email: email, password: password, name: name)
        self.tokens = t
        try tokenStore.save(tokens: t)
        configureGeneratedSDK()
    }
    
    func restore() async {
        if let t = tokenStore.load() { self.tokens = t } else { self.tokens = nil }
        configureGeneratedSDK()
    }
    
    func signOut() {
        tokenStore.clear()
        tokens = nil
        configureGeneratedSDK()
    }
    
    func configureGeneratedSDK() {
        GeneratedSDKConfig.apply(baseURL: config.baseURLString, bearerToken: tokens?.accessToken)
    }
}