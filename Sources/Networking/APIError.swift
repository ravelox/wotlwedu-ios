import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL(URL)
    case http(Int, Data?, URL)
    case decoding(Error, URL)
    case encoding(Error, URL)
    case noData(URL)
    case unauthorized(URL)
    case other(String, URL)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL \(url.absoluteString)"
        case .http(let status, _, let url):
            return "Server responded with status code \(status) for \(url.absoluteString)"
        case .decoding(let e, let url):
            return "Failed to decode response from \(url.absoluteString): \(e.localizedDescription)"
        case .encoding(let e, let url):
            return "Failed to encode request for \(url.absoluteString): \(e.localizedDescription)"
        case .noData(let url):
            return "No data in response from \(url.absoluteString)"
        case .unauthorized(let url):
            return "You are not signed in (while calling \(url.absoluteString))"
        case .other(let m, let url):
            return "\(m) (\(url.absoluteString))"
        }
    }

    var userMessage: String {
        switch self {
        case .unauthorized(_):
            return "Your session expired. Please sign in again."
        default:
            return self.localizedDescription
        }
    }
}