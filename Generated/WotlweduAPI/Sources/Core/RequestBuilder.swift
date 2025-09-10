import Foundation

/// A lightweight, non-functional request builder used solely to satisfy
/// the generated API's compile-time dependencies. Networking is left to
/// the application integrating this SDK.
open class RequestBuilder<T> {
    public let method: String
    public let URLString: String
    public let parameters: [String: Any]?
    public let headers: [String: Any]
    public let requiresAuthentication: Bool

    public required init(method: String,
                         URLString: String,
                         parameters: [String: Any]?,
                         headers: [String: Any],
                         requiresAuthentication: Bool) {
        self.method = method
        self.URLString = URLString
        self.parameters = parameters
        self.headers = headers
        self.requiresAuthentication = requiresAuthentication
    }

    /// Placeholder execution method. Applications should provide their own
    /// networking layer to actually perform the request.
    open func execute() async throws -> Response<T> {
        throw RequestBuilderError.executionNotSupported
    }
}

/// Simple response wrapper matching what the generated API expects.
public struct Response<T> {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: T

    public init(statusCode: Int = 0, headers: [String: String] = [:], body: T) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

public enum RequestBuilderError: Error {
    case executionNotSupported
}

/// Factory that returns `RequestBuilder` types.
public class RequestBuilderFactory {
    public init() {}

    public func getNonDecodableBuilder<T>() -> RequestBuilder<T>.Type {
        return RequestBuilder<T>.self
    }

    public func getDecodableBuilder<T: Decodable>() -> RequestBuilder<T>.Type {
        return RequestBuilder<T>.self
    }
}

/// Namespacing object to mirror the structure used by the generator.
public enum WotlweduAPIAPI {
    public static var basePath: String = ""
    public static let requestBuilderFactory = RequestBuilderFactory()
}
