import Foundation

struct AppTokens: Codable {
    let accessToken: String
    let refreshToken: String?
}

struct AppUser: Codable, Identifiable {
    let id: Int
    let email: String
    let name: String?
}

struct AppElectionItem: Codable, Identifiable, Hashable {
    let id: Int
    var name: String
    var description: String?
    var votes: Int?
}

struct AppElection: Codable, Identifiable, Hashable {
    let id: Int
    var name: String
    var description: String?
    var items: [AppElectionItem]?
    var imageUrl: String?
}