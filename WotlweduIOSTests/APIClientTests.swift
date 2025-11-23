@testable import WotlweduIOS
import XCTest

final class APIClientTests: XCTestCase {
    private var apiClient: APIClient!
    private var sessionStore: SessionStore!

    override func setUp() {
        super.setUp()
        sessionStore = SessionStore(defaults: .standard)
        let config = AppConfig.default
        let session = URLSession(configuration: urlSessionConfiguration())
        apiClient = APIClient(config: config, sessionStore: sessionStore, session: session)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testSendDecodesResponse() async throws {
        let responseObject = APIResponse<MessageResponse>(status: 200, message: "ok", data: MessageResponse(message: "hi"))
        let data = try JSONEncoder.api.encode(responseObject)
        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (httpResponse, data)
        }

        let endpoint = Endpoint(path: "ping", method: .get)
        let result: APIResponse<MessageResponse> = try await apiClient.send(endpoint)
        XCTAssertEqual(result.data?.message, "hi")
    }

    func testUnauthorizedReturnsError() async {
        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            let httpResponse = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (httpResponse, Data())
        }

        let endpoint = Endpoint(path: "secure", method: .get)
        do {
            let _: APIResponse<MessageResponse> = try await apiClient.send(endpoint)
            XCTFail("Expected unauthorized error")
        } catch let error as APIError {
            if case .unauthorized = error {
                // ok
            } else {
                XCTFail("Unexpected error \(error)")
            }
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testServerErrorReturnsMessage() async {
        let payload = "server down".data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            let httpResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (httpResponse, payload)
        }

        let endpoint = Endpoint(path: "error", method: .get)
        do {
            let _: APIResponse<MessageResponse> = try await apiClient.send(endpoint)
            XCTFail("Expected server error")
        } catch let error as APIError {
            if case .server(let message) = error {
                XCTAssertTrue(message.contains("500") || message.contains("server down"))
            } else {
                XCTFail("Unexpected error \(error)")
            }
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testAttachesBearerTokenWhenPresent() async throws {
        sessionStore.save(id: "1", auth: "abc123", refresh: "r", displayName: "User", admin: false)
        let expectedAuth = "Bearer abc123"
        let expectation = expectation(description: "Header attached")

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), expectedAuth)
            expectation.fulfill()
            let url = request.url!
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, try! JSONEncoder.api.encode(APIResponse<MessageResponse>(status: 200, message: nil, data: MessageResponse(message: "ok"))))
        }

        let endpoint = Endpoint(path: "secure", method: .get)
        _ = try await apiClient.send(endpoint) as APIResponse<MessageResponse>
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // Helpers
    private func urlSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return config
    }
}
