@testable import WotlweduIOS
import XCTest

final class AuthAuditParityTests: XCTestCase {
    func testInviteHistoryPageDecodesCurrentBackendShape() throws {
        let payload = """
        {
          "status": 200,
          "message": "OK",
          "data": {
            "invites": [
              {
                "id": "invite_123",
                "organizationId": "org_123",
                "email": "person@example.com",
                "token": "token_123",
                "status": "accepted",
                "createdAt": "2026-03-24T10:15:00.000Z",
                "expiresAt": "2026-03-31T10:15:00.000Z",
                "acceptedAt": "2026-03-24T11:00:00.000Z",
                "invitedByName": "Admin User",
                "acceptedByName": "Person Example"
              }
            ]
          }
        }
        """.data(using: .utf8)!

        struct Envelope: Decodable {
            let invites: [WotlweduOrganizationInvite]?
        }

        let response = try JSONDecoder.api.decode(APIResponse<Envelope>.self, from: payload)
        XCTAssertEqual(response.data?.invites?.first?.status, "accepted")
        XCTAssertEqual(response.data?.invites?.first?.acceptedByName, "Person Example")
    }

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

    func testSupportOverviewDecodesCurrentBackendShape() throws {
        let payload = """
        {
          "status": 200,
          "message": "OK",
          "data": {
            "organizationId": "org_123",
            "days": 3,
            "totals": {
              "all": 12,
              "success": 9,
              "blocked": 2,
              "pending": 1
            },
            "byEventType": [
              { "eventType": "login_google", "count": 4 },
              { "eventType": "organization_invite_create", "count": 2 }
            ],
            "recentFailures": [
              {
                "id": "audit_123",
                "eventType": "social_sign_in",
                "outcome": "blocked",
                "message": "Invite email did not match verified provider email",
                "createdAt": "2026-03-24T10:15:00.000Z"
              }
            ]
          }
        }
        """.data(using: .utf8)!

        struct SupportTotals: Decodable {
            let all: Int?
            let success: Int?
            let blocked: Int?
            let pending: Int?
        }

        struct SupportEventCount: Decodable {
            let eventType: String?
            let count: Int?
        }

        struct SupportOverview: Decodable {
            let organizationId: String?
            let days: Int?
            let totals: SupportTotals?
            let byEventType: [SupportEventCount]?
            let recentFailures: [WotlweduAuthAudit]?
        }

        let response = try JSONDecoder.api.decode(APIResponse<SupportOverview>.self, from: payload)
        XCTAssertEqual(response.data?.organizationId, "org_123")
        XCTAssertEqual(response.data?.totals?.blocked, 2)
        XCTAssertEqual(response.data?.recentFailures?.first?.outcome, "blocked")
    }
}
