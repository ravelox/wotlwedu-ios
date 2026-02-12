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
    var contentType: String?
    var description: String?
    var name: String?
    var filename: String?
    var url: String?
}

struct WotlweduItem: Codable, Identifiable, NamedEntity, Hashable {
    var id: String?
    var name: String?
    var description: String?
    var url: String?
    var location: String?
    var image: WotlweduImage?
    var category: WotlweduCategory?
}

struct WotlweduList: Codable, Identifiable, NamedEntity, Hashable {
    var id: String?
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

struct AIRecommendation: Decodable, Identifiable, Hashable {
    var itemId: String?
    var name: String?
    var score: Int?
    var reason: String?

    var id: String { itemId ?? name ?? "unknown-recommendation" }
}

struct AIElectionRecommendations: Decodable {
    var electionId: String?
    var recommendations: [AIRecommendation]?
}

struct AISuggestedItem: Decodable, Identifiable, Hashable {
    var name: String?
    var reason: String?

    var id: String { name ?? "unknown-suggestion" }
}

struct AIListSuggestions: Decodable {
    var category: String?
    var confidence: Double?
    var count: Int?
    var suggestions: [AISuggestedItem]?
}

struct AIElectionTopItem: Decodable, Identifiable, Hashable {
    var itemId: String?
    var name: String?
    var votes: Int?

    var id: String { itemId ?? name ?? "unknown-top-item" }
}

struct AIElectionSummary: Decodable {
    struct Stats: Decodable {
        var totalVotes: Int?
        var participantCount: Int?
        var itemCount: Int?
    }

    var summary: String?
    var stats: Stats?
    var topItems: [AIElectionTopItem]?
}

struct AINotificationDigest: Decodable {
    struct DigestNotification: Decodable, Identifiable, Hashable {
        var id: String?
        var text: String?
        var type: Int?
        var statusId: Int?
        var updatedAt: Date?
    }

    var summary: String?
    var unread: Int?
    var byType: [String: Int]?
    var recent: [DigestNotification]?
}

struct AIParticipantSuggestion: Decodable, Identifiable, Hashable {
    var userId: String?
    var alias: String?
    var score: Int?
    var reason: String?

    var id: String { userId ?? alias ?? "unknown-participant" }
}

struct AIParticipantSuggestions: Decodable {
    var suggestions: [AIParticipantSuggestion]?
    var count: Int?
}

struct AICategoryResult: Decodable {
    var category: String?
    var confidence: Double?
    var matches: [String]?
}

struct AIModerationFlag: Decodable, Hashable {
    var term: String?
    var policyArea: String?
}

struct AIModerationResult: Decodable {
    var safe: Bool?
    var severity: String?
    var flaggedTerms: [AIModerationFlag]?
}

struct AIImageDescription: Decodable {
    var description: String?
    var tags: [String]?
    var confidence: Double?
}

enum AIDefaultValue: Decodable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            throw DecodingError.typeMismatch(
                AIDefaultValue.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Unsupported default value")
            )
        }
    }

    var displayValue: String {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        case .double(let value): return String(format: "%.2f", value)
        case .bool(let value): return value ? "true" : "false"
        case .null: return "null"
        }
    }
}

struct AISmartDefaults: Decodable {
    var defaults: [String: AIDefaultValue]?
    var sourcePreferenceCount: Int?
}

struct AIAssistantData: Decodable {
    var category: String?
    var confidence: Double?
    var matches: [String]?
    var safe: Bool?
    var severity: String?
    var flaggedTerms: [AIModerationFlag]?
    var suggestions: [AISuggestedItem]?
    var defaults: [String: AIDefaultValue]?
    var sourcePreferenceCount: Int?
}

struct AIAssistantResponse: Decodable {
    var intent: String?
    var answer: String?
    var data: AIAssistantData?
}

extension Array where Element: NamedEntity & Identifiable {
    func sortedByName() -> [Element] {
        return sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
    }
}
