import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let status: Int?
    let message: String?
    let data: T?
}

struct PagedResponse<T: Decodable>: Decodable {
    let page: Int?
    let total: Int?
    let itemsPerPage: Int?
    let items: [T]?
    let categories: [T]?
    let images: [T]?
    let lists: [T]?
    let elections: [T]?
    let votes: [T]?
    let users: [T]?
    let organizations: [T]?
    let notifications: [T]?
    let preferences: [T]?
    let groups: [T]?
    let workgroups: [T]?
    let roles: [T]?
    let capabilities: [T]?
}

extension PagedResponse {
    var collection: [T] {
        items ??
        categories ??
        images ??
        lists ??
        elections ??
        votes ??
        users ??
        organizations ??
        notifications ??
        preferences ??
        groups ??
        workgroups ??
        roles ??
        capabilities ??
        []
    }
}

struct PagedResult<T> {
    let items: [T]
    let page: Int
    let total: Int
    let itemsPerPage: Int
}

struct MessageResponse: Decodable {
    let message: String?
}
