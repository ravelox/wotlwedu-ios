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
        case .encoding(let error, _):
            return "Encoding error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized"
        case .decoding(let error, _):
            return "Decoding error: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        case .http(let status, _, _):
            return "HTTP \(status)"
        case .other(let message, _):
            return message
        }
    }

    var userMessage: String { errorDescription ?? "Unknown error" }
}
