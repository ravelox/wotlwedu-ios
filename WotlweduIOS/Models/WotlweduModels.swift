import Foundation
import SwiftUI

protocol NamedEntity {
    var name: String? { get }
    var description: String? { get }
}

protocol CategorizedEntity {
    var category: WotlweduCategory? { get }
}

struct WotlweduStatus: Codable, Identifiable, Hashable {
    var id: String?
    var name: String?
    var object: String?

    init(id: String? = nil, name: String? = nil, object: String? = nil) {
        self.id = id
        self.name = name
        self.object = object
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case object
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringId = try? container.decode(String.self, forKey: .id) {
            id = stringId
        } else if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = nil
        }
        name = try container.decodeIfPresent(String.self, forKey: .name)
        object = try container.decodeIfPresent(String.self, forKey: .object)
    }
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

struct WotlweduImage: Codable, Identifiable, NamedEntity, CategorizedEntity, Hashable {
    var id: String?
    var workgroupId: String?
    var contentType: String?
    var description: String?
    var name: String?
    var filename: String?
    var category: WotlweduCategory?
    var url: String?
}

struct WotlweduItem: Codable, Identifiable, NamedEntity, CategorizedEntity, Hashable {
    var id: String?
    var workgroupId: String?
    var name: String?
    var description: String?
    var url: String?
    var location: String?
    var image: WotlweduImage?
    var category: WotlweduCategory?
}

struct WotlweduList: Codable, Identifiable, NamedEntity, CategorizedEntity, Hashable {
    var id: String?
    var workgroupId: String?
    var name: String?
    var description: String?
    var category: WotlweduCategory?
    var items: [WotlweduItem]?
}

struct WotlweduGroup: Codable, Identifiable, NamedEntity, CategorizedEntity, Hashable {
    var id: String?
    var name: String?
    var description: String?
    var users: [WotlweduUser]?
    var category: WotlweduCategory?
}

struct WotlweduWorkgroup: Codable, Identifiable, NamedEntity, CategorizedEntity, Hashable {
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
    var objectId: String?
    var status: WotlweduStatus?
    var text: String?
    var user: WotlweduUser?
    var sender: WotlweduUser?
    var createdAt: Date?
}

enum NotificationStatusId {
    static let unread = 100
    static let read = 101
    static let archived = 102
}

enum NotificationTypeId {
    static let friendRequest = 103
    static let electionStart = 104
    static let electionEnd = 105
    static let electionExpired = 106
    static let shareImage = 107
    static let shareItem = 108
    static let shareList = 109
}

struct WotlweduPreference: Codable, Identifiable, Hashable {
    var id: String?
    var name: String?
    var value: String?
}

struct WotlweduElection: Codable, Identifiable, NamedEntity, CategorizedEntity, Hashable {
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

struct CategoryGroup<Element: Identifiable>: Identifiable {
    let categoryName: String
    let items: [Element]

    var id: String { categoryName }
}

extension Array where Element: NamedEntity & Identifiable {
    func sortedByName() -> [Element] {
        return sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
    }
}

extension Array where Element: NamedEntity & CategorizedEntity & Identifiable {
    func groupedByCategory() -> [CategoryGroup<Element>] {
        let grouped = Dictionary(grouping: self) { element in
            let trimmedName = element.category?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmedName.isEmpty ? "Uncategorized" : trimmedName
        }

        return grouped
            .map { CategoryGroup(categoryName: $0.key, items: $0.value.sortedByName()) }
            .sorted {
                $0.categoryName.localizedCaseInsensitiveCompare($1.categoryName) == .orderedAscending
            }
    }
}
