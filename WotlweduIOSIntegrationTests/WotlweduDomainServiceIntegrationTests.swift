@testable import WotlweduIOS
import XCTest

final class WotlweduDomainServiceIntegrationTests: XCTestCase {
    func testElectionsListDecodesFromAPI() async throws {
        let election = WotlweduElection(id: "1", name: "Weekend plans", description: "Pick a place", text: nil, electionType: 0, expiration: nil, statusId: nil, status: nil, list: nil, group: nil, category: nil, image: nil)
        let paged = PagedResponse<WotlweduElection>(page: 1, total: 1, itemsPerPage: 10, items: nil, categories: nil, images: nil, lists: nil, elections: [election], votes: nil, users: nil, notifications: nil, preferences: nil, groups: nil, roles: nil, capabilities: nil)
        let apiResponse = APIResponse(status: 200, message: "ok", data: paged)
        let payload = try JSONEncoder.api.encode(apiResponse)
        let apiClient = makeMockedAPIClient(payload: payload)
        let domain = WotlweduDomainService(api: apiClient)

        let result = try await domain.elections(page: 1, items: 10, filter: nil)
        XCTAssertEqual(result.collection.first?.name, "Weekend plans")
        XCTAssertEqual(result.page, 1)
    }

    func testAddItemsAndRemoveItemsSendsPayload() async throws {
        let expectation = expectation(description: "Payload received")
        var receivedBody: Data?

        MockURLProtocol.requestHandler = { request in
            receivedBody = request.httpBody
            expectation.fulfill()
            let url = request.url!
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, try! JSONEncoder.api.encode(APIResponse<MessageResponse>(status: 200, message: "ok", data: MessageResponse(message: "done"))))
        }

        let sessionStore = SessionStore(defaults: .standard)
        let config = AppConfig.default
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfig)
        let apiClient = APIClient(config: config, sessionStore: sessionStore, session: session)
        let domain = WotlweduDomainService(api: apiClient)

        try await domain.addItems(to: "list123", itemIds: ["a", "b"])
        await fulfillment(of: [expectation], timeout: 1.0)

        let body = receivedBody.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        let itemList = body?["itemList"] as? [String]
        XCTAssertEqual(itemList, ["a", "b"])
    }
}
