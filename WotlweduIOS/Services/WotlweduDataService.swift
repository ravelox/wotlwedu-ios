import Foundation

final class WotlweduDataService {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func pagedList<T: Decodable>(path: String, detail: String? = nil, page: Int = 1, items: Int = 25, filter: String? = nil) async throws -> PagedResponse<T> {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "items", value: "\(items)")
        ]
        if let detail { query.append(URLQueryItem(name: "detail", value: detail)) }
        if let filter, !filter.isEmpty {
            query.append(URLQueryItem(name: "filter", value: filter))
        }
        let endpoint = Endpoint(path: path, method: .get, query: query)
        let response: APIResponse<PagedResponse<T>> = try await api.send(endpoint)
        guard let data = response.data else { throw APIError.server(response.message ?? "No data") }
        return data
    }

    func detail<T: Decodable>(path: String, id: String, detail: String? = nil) async throws -> T {
        var query: [URLQueryItem] = []
        if let detail { query.append(URLQueryItem(name: "detail", value: detail)) }
        let endpoint = Endpoint(path: "\(path)\(id)", method: .get, query: query)
        let response: APIResponse<T> = try await api.send(endpoint)
        guard let data = response.data else { throw APIError.server(response.message ?? "No detail data") }
        return data
    }

    func save<T: Decodable, P: Encodable>(path: String, id: String?, payload: P) async throws -> T {
        let data = try JSONEncoder.api.encode(payload)
        let method: HTTPMethod = id == nil ? .post : .put
        let endpoint = Endpoint(path: "\(path)\(id ?? "")", method: method, body: data)
        let response: APIResponse<T> = try await api.send(endpoint)
        guard let model = response.data else { throw APIError.server(response.message ?? "No response data") }
        return model
    }

    func delete(path: String, id: String) async throws {
        let endpoint = Endpoint(path: "\(path)\(id)", method: .delete)
        try await api.sendWithoutDecoding(endpoint)
    }
}
