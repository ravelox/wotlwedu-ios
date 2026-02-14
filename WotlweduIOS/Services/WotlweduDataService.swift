import Foundation

final class WotlweduDataService {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func pagedList<T: Decodable>(
        path: String,
        detail: String? = nil,
        page: Int = 1,
        items: Int = 25,
        filter: String? = nil,
        extraQuery: [URLQueryItem] = []
    ) async throws -> PagedResponse<T> {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "items", value: "\(items)")
        ]
        if let detail { query.append(URLQueryItem(name: "detail", value: detail)) }
        if let filter, !filter.isEmpty {
            query.append(URLQueryItem(name: "filter", value: filter))
        }
        query.append(contentsOf: extraQuery)
        let endpoint = Endpoint(path: path, method: .get, query: query)
        let response: APIResponse<PagedResponse<T>> = try await api.send(endpoint)
        guard let data = response.data else { throw APIError.server(message: response.message ?? "No data", url: nil) }
        return data
    }

    func detail<T: Decodable>(path: String, id: String, detail: String? = nil) async throws -> T {
        var query: [URLQueryItem] = []
        if let detail { query.append(URLQueryItem(name: "detail", value: detail)) }
        let endpoint = Endpoint(path: "\(path)\(id)", method: .get, query: query)
        let response: APIResponse<SingleObject<T>> = try await api.send(endpoint)
        guard let data = response.data?.value else { throw APIError.server(message: response.message ?? "No detail data", url: nil) }
        return data
    }

    func save<T: Decodable, P: Encodable>(path: String, id: String?, payload: P) async throws -> T {
        let data = try JSONEncoder.api.encode(payload)
        let method: HTTPMethod = id == nil ? .post : .put
        let endpoint = Endpoint(path: "\(path)\(id ?? "")", method: method, body: data)
        let response: APIResponse<SingleObject<T>> = try await api.send(endpoint)
        guard let model = response.data?.value else { throw APIError.server(message: response.message ?? "No response data", url: nil) }
        return model
    }

    func delete(path: String, id: String) async throws {
        let endpoint = Endpoint(path: "\(path)\(id)", method: .delete)
        try await api.sendWithoutDecoding(endpoint)
    }
}

// Most wotlwedu endpoints wrap models as `data: { <modelName>: {...} }`.
// Decode the first key without caring what it is.
private struct SingleObject<T: Decodable>: Decodable {
    let value: T

    private struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        guard let first = container.allKeys.first else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Expected single keyed object"))
        }
        value = try container.decode(T.self, forKey: first)
    }
}
