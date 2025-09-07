import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case http(Int, Data?)
    case decoding(Error)
    case encoding(Error)
    case noData
    case unauthorized
    case other(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .http(let status, _): return "Server responded with status code \(status)"
        case .decoding(let e): return "Failed to decode response: \(e.localizedDescription)"
        case .encoding(let e): return "Failed to encode request: \(e.localizedDescription)"
        case .noData: return "No data in response"
        case .unauthorized: return "You are not signed in"
        case .other(let m): return m
        }
    }

    var userMessage: String {
        switch self {
        case .unauthorized: return "Your session expired. Please sign in again."
        default: return self.localizedDescription
        }
    }
}