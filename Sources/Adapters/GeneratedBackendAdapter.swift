import Foundation
#if canImport(WotlweduAPI)
import WotlweduAPI
#endif

enum GeneratedSDKConfig {
    static func apply(baseURL: String, bearerToken: String?) {
        #if canImport(WotlweduAPI)
        WotlweduAPI.Configuration.basePath = baseURL
        let token = (bearerToken ?? "")
        let keys = ["BearerAuth", "bearerAuth", "HTTPBearer", "bearer", "Authorization"]
        if token.isEmpty {
            for k in keys { WotlweduAPI.Configuration.apiKey[k] = nil; WotlweduAPI.Configuration.apiKeyPrefix[k] = nil }
        } else {
            for k in keys { WotlweduAPI.Configuration.apiKey[k] = token; WotlweduAPI.Configuration.apiKeyPrefix[k] = "Bearer" }
        }
        #endif
    }
}

enum GeneratedBackend {
    enum NotReady: Error, LocalizedError {
        case sdkNotGenerated
        var errorDescription: String? { "Generated SDK not found. Run `make generate-api`." }
    }
    
    static func login(email: String, password: String) async throws -> AppTokens {
        #if canImport(WotlweduAPI)
        let body = WotlweduAPI.LoginRequest(email: email, password: password)
        let resp = try await AuthAPI.login(body: body)
        return AppTokens(accessToken: resp.accessToken, refreshToken: resp.refreshToken)
        #else
        throw NotReady.sdkNotGenerated
        #endif
    }
    
    static func register(email: String, password: String, name: String?) async throws -> AppTokens {
        #if canImport(WotlweduAPI)
        let body = WotlweduAPI.RegisterRequest(email: email, password: password, name: name)
        let resp = try await AuthAPI.register(body: body)
        return AppTokens(accessToken: resp.accessToken, refreshToken: resp.refreshToken)
        #else
        throw NotReady.sdkNotGenerated
        #endif
    }
    
    static func me() async throws -> AppUser {
        #if canImport(WotlweduAPI)
        let u = try await UsersAPI.me()
        return AppUser(id: u.id, email: u.email, name: u.name)
        #else
        throw NotReady.sdkNotGenerated
        #endif
    }
    
    static func listElections() async throws -> [AppElection] {
        #if canImport(WotlweduAPI)
        return try await ElectionsAPI.listElections().map { g in
            AppElection(id: g.id, name: g.name, description: g.description, items: g.items?.map { AppElectionItem(id: $0.id, name: $0.name, description: $0.description, votes: $0.votes) }, imageUrl: g.imageUrl)
        }
        #else
        throw NotReady.sdkNotGenerated
        #endif
    }
    
    static func getElection(id: Int) async throws -> AppElection {
        #if canImport(WotlweduAPI)
        let g = try await ElectionsAPI.getElectionById(id: id)
        return AppElection(id: g.id, name: g.name, description: g.description, items: g.items?.map { AppElectionItem(id: $0.id, name: $0.name, description: $0.description, votes: $0.votes) }, imageUrl: g.imageUrl)
        #else
        throw NotReady.sdkNotGenerated
        #endif
    }
    
    static func createElection(name: String, description: String?) async throws -> AppElection {
        #if canImport(WotlweduAPI)
        let body = WotlweduAPI.CreateElectionRequest(name: name, description: description)
        let g = try await ElectionsAPI.createElection(body: body)
        return AppElection(id: g.id, name: g.name, description: g.description, items: g.items?.map { AppElectionItem(id: $0.id, name: $0.name, description: $0.description, votes: $0.votes) }, imageUrl: g.imageUrl)
        #else
        throw NotReady.sdkNotGenerated
        #endif
    }
    
    static func createItem(electionId: Int, name: String, description: String?) async throws -> AppElectionItem {
        #if canImport(WotlweduAPI)
        let body = WotlweduAPI.CreateElectionItemRequest(name: name, description: description)
        let it = try await ElectionsAPI.createElectionItem(electionId: electionId, body: body)
        return AppElectionItem(id: it.id, name: it.name, description: it.description, votes: it.votes)
        #else
        throw NotReady.sdkNotGenerated
        #endif
    }
    
    static func vote(electionId: Int, itemId: Int) async throws {
        #if canImport(WotlweduAPI)
        _ = try await ElectionsAPI.voteItem(electionId: electionId, itemId: itemId)
        #else
        throw NotReady.sdkNotGenerated
        #endif
    }
}