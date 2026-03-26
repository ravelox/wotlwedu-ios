@testable import WotlweduIOS
import XCTest

final class AuthAuditParityTests: XCTestCase {
    func testInviteLookupDecodesCurrentBackendShape() throws {
        let payload = """
        {
          "status": 200,
          "message": "OK",
          "data": {
            "invite": {
              "id": "invite_123",
              "organizationId": "org_123",
              "email": "person@example.com",
              "token": "token_123",
              "status": "pending",
              "createdAt": "2026-03-24T10:15:00.000Z",
              "expiresAt": "2026-03-31T10:15:00.000Z",
              "invitedByName": "Admin User",
              "organizationName": "Example Org"
            }
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.api.decode(APIResponse<WotlweduInviteLookup>.self, from: payload)
        XCTAssertEqual(response.data?.invite?.id, "invite_123")
        XCTAssertEqual(response.data?.invite?.organizationName, "Example Org")
        XCTAssertEqual(response.data?.invite?.status, "pending")
    }

    func testSignInMethodsEnvelopeDecodesCurrentBackendShape() throws {
        let payload = """
        {
          "status": 200,
          "message": "OK",
          "data": {
            "methods": {
              "passwordEnabled": true,
              "linkedProviders": [
                {
                  "id": "identity_123",
                  "provider": "google",
                  "email": "person@example.com",
                  "subjectPreview": "abc123...",
                  "createdAt": "2026-03-24T10:15:00.000Z",
                  "updatedAt": "2026-03-24T10:15:00.000Z"
                }
              ]
            }
          }
        }
        """.data(using: .utf8)!

        struct Envelope: Decodable {
            let methods: WotlweduSignInMethodsEnvelope?
        }

        let response = try JSONDecoder.api.decode(APIResponse<Envelope>.self, from: payload)
        XCTAssertEqual(response.data?.methods?.passwordEnabled, true)
        XCTAssertEqual(response.data?.methods?.linkedProviders?.first?.provider, "google")
    }

    func testAuthAuditPageDecodesCurrentBackendShape() throws {
        let payload = """
        {
          "status": 200,
          "message": "OK",
          "data": {
            "total": 1,
            "page": 1,
            "itemsPerPage": 10,
            "audits": [
              {
                "id": "audit_123",
                "eventType": "login_google",
                "outcome": "success",
                "actorUserId": "user_123",
                "targetUserId": "user_123",
                "organizationId": "org_123",
                "inviteId": "invite_123",
                "provider": "google",
                "email": "person@example.com",
                "ipAddress": "127.0.0.1",
                "userAgent": "Unit Test",
                "message": "Google sign-in succeeded",
                "createdAt": "2026-03-24T10:15:00.000Z"
              }
            ]
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.api.decode(APIResponse<PagedResponse<WotlweduAuthAudit>>.self, from: payload)
        XCTAssertEqual(response.data?.audits?.first?.eventType, "login_google")
        XCTAssertEqual(response.data?.audits?.first?.organizationId, "org_123")
        XCTAssertEqual(response.data?.audits?.first?.provider, "google")
    }
}
