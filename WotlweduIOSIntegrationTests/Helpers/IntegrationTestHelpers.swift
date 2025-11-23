import Foundation
@testable import WotlweduIOS

enum IntegrationTestError: Error {
    case missingHandler
}

func makeMockedAPIClient(statusCode: Int = 200, payload: Data, headers: [String: String]? = nil) -> APIClient {
    let sessionStore = SessionStore(defaults: .standard)
    let config = AppConfig.default
    let sessionConfig = URLSessionConfiguration.ephemeral
    sessionConfig.protocolClasses = [MockURLProtocol.self]
    MockURLProtocol.requestHandler = { request in
        let url = request.url!
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)!
        return (response, payload)
    }
    let session = URLSession(configuration: sessionConfig)
    return APIClient(config: config, sessionStore: sessionStore, session: session)
}
