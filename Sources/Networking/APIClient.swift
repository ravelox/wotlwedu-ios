import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class APIClient {
    let endpoints: Endpoints
    private let session: URLSession
    private let tokenProvider: () -> String?

    init(endpoints: Endpoints, tokenProvider: @escaping () -> String?) {
        self.endpoints = endpoints
        self.tokenProvider = tokenProvider
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = endpoints.timeout
        self.session = URLSession(configuration: config)
    }

    // MARK: - Helpers
    func request(_ url: URL, method: String = "GET", body: Encodable? = nil, authorized: Bool = false) throws -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            do {
                req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
            } catch {
                throw APIError.encoding(error, url)
            }
        }
        if authorized {
            guard let token = tokenProvider() else { throw APIError.unauthorized(url) }
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    func decode<T: Decodable>(_ data: Data, url: URL) throws -> T {
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw APIError.decoding(error, url) }
    }

    func perform(_ req: URLRequest) async throws -> Data {
        let url = req.url ?? endpoints.baseURL
        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw APIError.noData(url) }
            guard (200..<300).contains(http.statusCode) else { throw APIError.http(http.statusCode, data, url) }
            return data
        } catch {
            throw APIError.other(error.localizedDescription, url)
        }
    }

    // MARK: - Auth
    struct LoginRequest: Codable { let email: String; let password: String }
    struct RegisterRequest: Codable { let email: String; let password: String; let name: String? }

    func login(email: String, password: String) async throws -> AuthTokens {
        let req = try request(endpoints.login, method: "POST", body: LoginRequest(email: email, password: password))
        let data = try await perform(req)
        return try decode(data, url: req.url ?? endpoints.login)
    }

    func register(email: String, password: String, name: String?) async throws -> AuthTokens {
        let req = try request(endpoints.register, method: "POST", body: RegisterRequest(email: email, password: password, name: name))
        let data = try await perform(req)
        return try decode(data, url: req.url ?? endpoints.register)
    }

    func me() async throws -> UserProfile {
        let req = try request(endpoints.me, authorized: true)
        let data = try await perform(req)
        return try decode(data, url: req.url ?? endpoints.me)
    }

    // MARK: - Elections
    func listElections() async throws -> [Election] {
        let req = try request(endpoints.elections, authorized: true)
        let data = try await perform(req)
        return try decode(data, url: req.url ?? endpoints.elections)
    }

    func getElection(id: Int) async throws -> Election {
        let req = try request(endpoints.election(id: id), authorized: true)
        let data = try await perform(req)
        return try decode(data, url: req.url ?? endpoints.election(id: id))
    }

    func vote(electionId: Int, itemId: Int) async throws {
        let req = try request(endpoints.vote(electionId: electionId, itemId: itemId), method: "POST", authorized: true)
        _ = try await perform(req)
    }

    struct CreateElectionRequest: Codable { let name: String; let description: String? }
    struct CreateItemRequest: Codable { let name: String; let description: String? }

    func createElection(name: String, description: String?) async throws -> Election {
        let req = try request(endpoints.elections, method: "POST",
                              body: CreateElectionRequest(name: name, description: description), authorized: true)
        let data = try await perform(req)
        return try decode(data, url: req.url ?? endpoints.elections)
    }

    func createItem(electionId: Int, name: String, description: String?) async throws -> ElectionItem {
        let req = try request(endpoints.items(electionId: electionId), method: "POST",
                              body: CreateItemRequest(name: name, description: description), authorized: true)
        let data = try await perform(req)
        return try decode(data, url: req.url ?? endpoints.items(electionId: electionId))
    }

    func uploadElectionImage(electionId: Int, data: Data, filename: String, mime: String) async throws {
        let (body, contentType) = MultipartFormDataBuilder().build(parts: [("image", filename, mime, data)])
        var req = try request(endpoints.electionImage(electionId: electionId), method: "POST", authorized: true)
        req.httpBody = body
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        _ = try await perform(req)
    }

    func uploadItemImage(electionId: Int, itemId: Int, data: Data, filename: String, mime: String) async throws {
        let (body, contentType) = MultipartFormDataBuilder().build(parts: [("image", filename, mime, data)])
        var req = try request(endpoints.itemImage(electionId: electionId, itemId: itemId), method: "POST", authorized: true)
        req.httpBody = body
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        _ = try await perform(req)
    }
}

// Helper Encodable wrapper
private struct AnyEncodable: Encodable {
    let value: Encodable
    init(_ value: Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}