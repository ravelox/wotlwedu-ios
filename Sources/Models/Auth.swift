import Foundation

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String?
}

struct UserProfile: Codable {
    let id: Int
    let email: String
    let name: String?
}