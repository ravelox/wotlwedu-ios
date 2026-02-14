import Foundation
import SwiftUI

protocol NamedEntity {
    var name: String? { get }
    var description: String? { get }
}

struct WotlweduStatus: Codable, Identifiable, Hashable {
    var id: String?
    var name: String?
    var object: String?
}

struct WotlweduCap: Codable, Identifiable, NamedEntity, Hashable {
    var id: String?
    var name: String?
    var description: String?
}

struct WotlweduCategory: Codable, Identifiable, NamedEntity, Hashable {
    var id: String?
    var name: String?
    var description: String?
}

struct WotlweduImage: Codable, Identifiable, NamedEntity, Hashable {
    var id: String?
    var workgroupId: String?
    var contentType: String?
    var description: String?
    var name: String?
    var filename: String?
    var url: String?
}

struct WotlweduItem: Codable, Identifiable, NamedEntity, Hashable {
    var id: String?
    var workgroupId: String?
    var name: String?
    var description: String?
    var url: String?
    var location: String?
    var image: WotlweduImage?
    var category: WotlweduCategory?
}

struct WotlweduList: Codable, Identifiable, NamedEntity, Hashable {
    var id: String?
    var workgroupId: String?
    var name: String?
    var description: String?
    var items: [WotlweduItem]?
}

struct WotlweduGroup: Codable, Identifiable, NamedEntity, Hashable {
    var id: String?
    var name: String?
    var description: String?
    var users: [WotlweduUser]?
    var category: WotlweduCategory?
}

struct WotlweduWorkgroup: Codable, Identifiable, NamedEntity, Hashable {
    var id: String?
    var organizationId: String?
    var name: String?
    var description: String?
    var users: [WotlweduUser]?
    var category: WotlweduCategory?
}

struct WotlweduOrganization: Codable, Identifiable, NamedEntity, Hashable {
    var id: String?
    var name: String?
    var description: String?
    var active: Bool?
    var creator: String?
}

struct WotlweduRole: Codable, Identifiable, NamedEntity, Hashable {
    var id: String?
    var name: String?
    var description: String?
    var protected: Bool?
    var capabilities: [WotlweduCap]?
    var users: [WotlweduUser]?
}

struct WotlweduUser: Codable, Identifiable, NamedEntity, Hashable {
    var id: String?
    var firstName: String?
    var lastName: String?
    var alias: String?
    var email: String?
    var image: WotlweduImage?
    var active: Bool?
    var verified: Bool?
    var enable2fa: Bool?
    var admin: Bool?
    var systemAdmin: Bool?
    var organizationId: String?
    var organizationAdmin: Bool?
    var workgroupAdmin: Bool?
    var adminWorkgroupId: String?

    var name: String? { displayName }
    var description: String? { email }

    var displayName: String {
        let full = [firstName, lastName].compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        if !full.isEmpty { return full }
        if let alias { return alias }
        return email ?? "Unknown"
    }
}

struct WotlweduFriend: Codable, Identifiable, Hashable {
    var id: String?
    var status: WotlweduStatus?
    var user: WotlweduUser?
}

struct WotlweduNotification: Codable, Identifiable, Hashable {
    var id: String?
    var type: Int?
    var status: WotlweduStatus?
    var text: String?
    var user: WotlweduUser?
    var sender: WotlweduUser?
}

struct WotlweduPreference: Codable, Identifiable, Hashable {
    var id: String?
    var name: String?
    var value: String?
}

struct WotlweduElection: Codable, Identifiable, NamedEntity, Hashable {
    var id: String?
    var workgroupId: String?
    var name: String?
    var description: String?
    var text: String?
    var electionType: Int?
    var expiration: Date?
    var statusId: Int?
    var status: WotlweduStatus?
    var list: WotlweduList?
    var group: WotlweduGroup?
    var category: WotlweduCategory?
    var image: WotlweduImage?
}

struct WotlweduVote: Codable, Identifiable, Hashable {
    var id: String?
    var election: WotlweduElection?
    var status: WotlweduStatus?
    var item: WotlweduItem?
    var user: WotlweduUser?
}

struct WotlweduRegistration: Codable {
    var email: String
    var firstName: String
    var lastName: String
    var alias: String
    var auth: String?
}

struct ServerStatus: Decodable {
    var version: String?
    var uptime: String?
    var message: String?
}

extension Array where Element: NamedEntity & Identifiable {
    func sortedByName() -> [Element] {
        return sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
    }
}
