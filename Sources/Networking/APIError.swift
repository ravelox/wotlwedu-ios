import Foundation

enum APIError: Error, LocalizedError {
    case encoding(Error, URL)
    case unauthorized(URL)
    case decoding(Error, URL)
    case noData(URL)
    case http(Int, Data, URL)
    case other(String, URL)

    var errorDescription: String? {
        switch self {
        case .encoding(let error, let url):
            return "Encoding error: \(error.localizedDescription) (\(url.absoluteString))"
        case .unauthorized(let url):
            return "Unauthorized (\(url.absoluteString))"
        case .decoding(let error, let url):
            return "Decoding error: \(error.localizedDescription) (\(url.absoluteString))"
        case .noData(let url):
            return "No data received (\(url.absoluteString))"
        case .http(let status, _, let url):
            return "HTTP \(status) (\(url.absoluteString))"
        case .other(let message, let url):
            return "\(message) (\(url.absoluteString))"
        }
    }

    var userMessage: String { errorDescription ?? "Unknown error" }
}
