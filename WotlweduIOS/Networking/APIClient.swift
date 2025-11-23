import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct Endpoint {
    var path: String
    var method: HTTPMethod = .get
    var query: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data? = nil
    var requiresAuth: Bool = true
    var contentType: String? = "application/json"
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case server(String)
    case unauthorized
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Unexpected response from server"
        case .server(let message):
            return message
        case .unauthorized:
            return "Authorization required"
        case .decoding(let error):
            return "Failed to decode server response: \(error.localizedDescription)"
        case .transport(let error):
            return error.localizedDescription
        }
    }
}

final class APIClient {
    private let config: AppConfig
    private let sessionStore: SessionStore
    private let urlSession: URLSession

    init(config: AppConfig, sessionStore: SessionStore, session: URLSession = .shared) {
        self.config = config
        self.sessionStore = sessionStore
        self.urlSession = session
    }

    func send<T: Decodable>(_ endpoint: Endpoint, decode type: T.Type = T.self) async throws -> T {
        let request = try makeRequest(endpoint: endpoint)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw APIError.server(message)
        }

        do {
            return try JSONDecoder.api.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    func sendWithoutDecoding(_ endpoint: Endpoint) async throws {
        let _: APIResponse<MessageResponse> = try await send(endpoint, decode: APIResponse<MessageResponse>.self)
    }

    private func makeRequest(endpoint: Endpoint) throws -> URLRequest {
        var base = config.apiUrl
        if !base.hasSuffix("/") { base += "/" }
        guard var components = URLComponents(string: base + endpoint.path) else {
            throw APIError.invalidURL
        }
        if !endpoint.query.isEmpty {
            components.queryItems = endpoint.query
        }
        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        if let contentType = endpoint.contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        endpoint.headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        if endpoint.requiresAuth, let token = sessionStore.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

extension JSONDecoder {
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(DateFormatter.apiDateFormatter)
        return decoder
    }
}

extension JSONEncoder {
    static var api: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .formatted(DateFormatter.apiDateFormatter)
        return encoder
    }
}

extension DateFormatter {
    static var apiDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}
