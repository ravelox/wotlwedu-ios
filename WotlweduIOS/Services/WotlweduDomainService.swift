import Foundation

final class WotlweduDomainService {
    let api: APIClient
    let dataService: WotlweduDataService
    let mediaService: MediaService

    init(api: APIClient) {
        self.api = api
        self.dataService = WotlweduDataService(api: api)
        self.mediaService = MediaService(api: api)
    }

    // MARK: - Helper endpoints
    func serverStatus() async throws -> ServerStatus {
        struct PingData: Decodable { let version: String?; let date: Date? }
        let endpoint = Endpoint(path: "ping", method: .get, requiresAuth: false)
        let response: APIResponse<PingData> = try await api.send(endpoint)
        return ServerStatus(version: response.data?.version, uptime: nil, message: response.message)
    }

    func ping() async throws -> MessageResponse {
        let endpoint = Endpoint(path: "ping", method: .get)
        let response: APIResponse<MessageResponse> = try await api.send(endpoint)
        return response.data ?? MessageResponse(message: response.message)
    }

    // MARK: - Notifications
    func notifications(page: Int = 1, items: Int = 25) async throws -> PagedResponse<WotlweduNotification> {
        let endpoint = Endpoint(
            path: "notification/",
            method: .get,
            query: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "items", value: "\(items)")
            ]
        )
        let response: APIResponse<PagedResponse<WotlweduNotification>> = try await api.send(endpoint)
        guard let data = response.data else { throw APIError.server(message: response.message ?? "No notifications", url: nil) }
        return data
    }

    func unreadNotificationCount() async throws -> Int {
        let endpoint = Endpoint(path: "notification/unreadcount", method: .get)
        struct CountResponse: Decodable { let count: Int?; let unread: Int? }
        let response: APIResponse<CountResponse> = try await api.send(endpoint)
        return response.data?.count ?? response.data?.unread ?? 0
    }

    func deleteNotification(id: String) async throws {
        let endpoint = Endpoint(path: "notification/\(id)", method: .delete)
        try await api.sendWithoutDecoding(endpoint)
    }

    func setNotificationStatus(id: String, statusId: Int) async throws {
        let endpoint = Endpoint(path: "notification/status/\(id)/\(statusId)", method: .put)
        try await api.sendWithoutDecoding(endpoint)
    }

    // MARK: - Preferences
    func preferences(page: Int = 1, items: Int = 100) async throws -> PagedResponse<WotlweduPreference> {
        try await dataService.pagedList(path: "preference/", page: page, items: items)
    }

    func save(preference: WotlweduPreference) async throws -> WotlweduPreference {
        struct Payload: Encodable { let name: String; let value: String }
        return try await dataService.save(
            path: "preference/",
            id: preference.id,
            payload: Payload(name: preference.name ?? "", value: preference.value ?? "")
        )
    }

    // MARK: - Categories
    func categories(page: Int = 1, items: Int = 50, filter: String? = nil) async throws -> PagedResponse<WotlweduCategory> {
        try await dataService.pagedList(path: "category/", page: page, items: items, filter: filter)
    }

    func categoryDetail(id: String) async throws -> WotlweduCategory {
        try await dataService.detail(path: "category/", id: id)
    }

    func save(category: WotlweduCategory) async throws -> WotlweduCategory {
        struct Payload: Encodable { let name: String; let description: String? }
        return try await dataService.save(
            path: "category/",
            id: category.id,
            payload: Payload(name: category.name ?? "", description: category.description)
        )
    }

    func deleteCategory(id: String) async throws {
        try await dataService.delete(path: "category/", id: id)
    }

    // MARK: - Groups
    func groups(page: Int = 1, items: Int = 50, filter: String? = nil) async throws -> PagedResponse<WotlweduGroup> {
        try await dataService.pagedList(path: "group/", detail: "user,category", page: page, items: items, filter: filter)
    }

    func save(group: WotlweduGroup, originalMemberIds: Set<String> = []) async throws -> WotlweduGroup {
        struct Payload: Encodable {
            let name: String
            let description: String?
            let categoryId: String?
        }
        let payload = Payload(
            name: group.name ?? "",
            description: group.description,
            categoryId: group.category?.id
        )

        let saved: WotlweduGroup = try await dataService.save(path: "group/", id: group.id, payload: payload)

        let newIds = Set(group.users?.compactMap { $0.id } ?? [])
        let toAdd = Array(newIds.subtracting(originalMemberIds))
        let toDel = Array(originalMemberIds.subtracting(newIds))
        if let id = saved.id {
            try await bulkUsers(path: "group/\(id)/bulkuserdel", userIds: toDel)
            try await bulkUsers(path: "group/\(id)/bulkuseradd", userIds: toAdd)
        }
        return saved
    }

    func deleteGroup(id: String) async throws {
        try await dataService.delete(path: "group/", id: id)
    }

    // MARK: - Workgroups
    func workgroups(page: Int = 1, items: Int = 50, filter: String? = nil) async throws -> PagedResponse<WotlweduWorkgroup> {
        try await dataService.pagedList(path: "workgroup/", detail: "user,category", page: page, items: items, filter: filter)
    }

    func save(workgroup: WotlweduWorkgroup, originalMemberIds: Set<String> = []) async throws -> WotlweduWorkgroup {
        struct Payload: Encodable {
            let organizationId: String?
            let name: String
            let description: String?
            let categoryId: String?
        }
        let payload = Payload(
            organizationId: workgroup.organizationId,
            name: workgroup.name ?? "",
            description: workgroup.description,
            categoryId: workgroup.category?.id
        )

        let saved: WotlweduWorkgroup = try await dataService.save(path: "workgroup/", id: workgroup.id, payload: payload)

        let newIds = Set(workgroup.users?.compactMap { $0.id } ?? [])
        let toAdd = Array(newIds.subtracting(originalMemberIds))
        let toDel = Array(originalMemberIds.subtracting(newIds))
        if let id = saved.id {
            try await bulkUsers(path: "workgroup/\(id)/bulkuserdel", userIds: toDel)
            try await bulkUsers(path: "workgroup/\(id)/bulkuseradd", userIds: toAdd)
        }
        return saved
    }

    func deleteWorkgroup(id: String) async throws {
        try await dataService.delete(path: "workgroup/", id: id)
    }

    // MARK: - Organizations
    func organizations(page: Int = 1, items: Int = 50, filter: String? = nil) async throws -> PagedResponse<WotlweduOrganization> {
        try await dataService.pagedList(path: "organization/", page: page, items: items, filter: filter)
    }

    func organizationDetail(id: String) async throws -> WotlweduOrganization {
        try await dataService.detail(path: "organization/", id: id)
    }

    func save(organization: WotlweduOrganization) async throws -> WotlweduOrganization {
        struct Payload: Encodable {
            let name: String
            let description: String?
            let active: Bool?
        }
        let payload = Payload(
            name: organization.name ?? "",
            description: organization.description,
            active: organization.active
        )
        return try await dataService.save(path: "organization/", id: organization.id, payload: payload)
    }

    func deleteOrganization(id: String) async throws {
        try await dataService.delete(path: "organization/", id: id)
    }

    // MARK: - Items
    func items(page: Int = 1, items: Int = 25, filter: String? = nil, workgroupId: String? = nil) async throws -> PagedResponse<WotlweduItem> {
        var extra: [URLQueryItem] = []
        if let workgroupId, !workgroupId.isEmpty {
            extra.append(URLQueryItem(name: "workgroupId", value: workgroupId))
        }
        return try await dataService.pagedList(path: "item/", detail: "image,category", page: page, items: items, filter: filter, extraQuery: extra)
    }

    func itemDetail(id: String, notificationId: String? = nil) async throws -> WotlweduItem {
        if let notificationId, !notificationId.isEmpty {
            try await dataService.detail(path: "item/", id: "\(id)/notif/\(notificationId)", detail: "image,category")
        } else {
            try await dataService.detail(path: "item/", id: id, detail: "image,category")
        }
    }

    func save(item: WotlweduItem) async throws -> WotlweduItem {
        struct Payload: Encodable {
            let id: String?
            let name: String
            let description: String?
            let url: String?
            let location: String?
            let imageId: String?
            let categoryId: String?
            let workgroupId: String?
        }
        let payload = Payload(
            id: item.id,
            name: item.name ?? "",
            description: item.description,
            url: item.url,
            location: item.location,
            imageId: item.image?.id,
            categoryId: item.category?.id,
            workgroupId: item.workgroupId
        )
        return try await dataService.save(path: "item/", id: item.id, payload: payload)
    }

    func deleteItem(id: String) async throws {
        try await dataService.delete(path: "item/", id: id)
    }

    func shareItem(id: String, recipientId: String) async throws {
        let endpoint = Endpoint(path: "item/share/\(id)/recipient/\(recipientId)", method: .post)
        try await api.sendWithoutDecoding(endpoint)
    }

    func acceptSharedItem(notificationId: String) async throws {
        let endpoint = Endpoint(path: "item/accept/\(notificationId)", method: .post)
        try await api.sendWithoutDecoding(endpoint)
    }

    // MARK: - Helpers
    private func bulkUsers(path: String, userIds: [String]) async throws {
        guard !userIds.isEmpty else { return }
        struct Payload: Encodable { let userList: [String] }
        let data = try JSONEncoder.api.encode(Payload(userList: userIds))
        let endpoint = Endpoint(path: path, method: .put, body: data)
        try await api.sendWithoutDecoding(endpoint)
    }

    // MARK: - Images
    func images(page: Int = 1, items: Int = 50, filter: String? = nil, workgroupId: String? = nil) async throws -> PagedResponse<WotlweduImage> {
        var extra: [URLQueryItem] = []
        if let workgroupId, !workgroupId.isEmpty {
            extra.append(URLQueryItem(name: "workgroupId", value: workgroupId))
        }
        return try await dataService.pagedList(path: "image/", detail: "category", page: page, items: items, filter: filter, extraQuery: extra)
    }

    func imageDetail(id: String, notificationId: String? = nil) async throws -> WotlweduImage {
        if let notificationId, !notificationId.isEmpty {
            try await dataService.detail(path: "image/", id: "\(id)/notif/\(notificationId)", detail: "category")
        } else {
            try await dataService.detail(path: "image/", id: id, detail: "category")
        }
    }

    func deleteImage(id: String) async throws {
        try await dataService.delete(path: "image/", id: id)
    }

    func shareImage(id: String, recipientId: String) async throws {
        let endpoint = Endpoint(path: "image/share/\(id)/recipient/\(recipientId)", method: .post)
        try await api.sendWithoutDecoding(endpoint)
    }

    func acceptImage(notificationId: String) async throws {
        let endpoint = Endpoint(path: "image/accept/\(notificationId)", method: .post)
        try await api.sendWithoutDecoding(endpoint)
    }

    // MARK: - Lists
    func lists(page: Int = 1, items: Int = 25, filter: String? = nil, workgroupId: String? = nil) async throws -> PagedResponse<WotlweduList> {
        var extra: [URLQueryItem] = []
        if let workgroupId, !workgroupId.isEmpty {
            extra.append(URLQueryItem(name: "workgroupId", value: workgroupId))
        }
        return try await dataService.pagedList(path: "list/", detail: "category,item,image", page: page, items: items, filter: filter, extraQuery: extra)
    }

    func listDetail(id: String, notificationId: String? = nil) async throws -> WotlweduList {
        if let notificationId, !notificationId.isEmpty {
            try await dataService.detail(path: "list/", id: "\(id)/notif/\(notificationId)", detail: "category,item,image")
        } else {
            try await dataService.detail(path: "list/", id: id, detail: "category,item,image")
        }
    }

    func save(list: WotlweduList) async throws -> WotlweduList {
        struct Payload: Encodable {
            let name: String
            let description: String?
            let categoryId: String?
            let workgroupId: String?
        }
        let payload = Payload(
            name: list.name ?? "",
            description: list.description,
            categoryId: list.category?.id,
            workgroupId: list.workgroupId
        )
        return try await dataService.save(path: "list/", id: list.id, payload: payload)
    }

    func deleteList(id: String) async throws {
        try await dataService.delete(path: "list/", id: id)
    }

    func shareList(id: String, recipientId: String) async throws {
        let endpoint = Endpoint(path: "list/share/\(id)/recipient/\(recipientId)", method: .post)
        try await api.sendWithoutDecoding(endpoint)
    }

    func acceptList(notificationId: String) async throws {
        let endpoint = Endpoint(path: "list/accept/\(notificationId)", method: .post)
        try await api.sendWithoutDecoding(endpoint)
    }

    func addItems(to listId: String, itemIds: [String]) async throws {
        guard !itemIds.isEmpty else { return }
        let endpoint = Endpoint(path: "list/\(listId)/bulkitemadd", method: .post, body: try JSONEncoder.api.encode(["itemList": itemIds]))
        try await api.sendWithoutDecoding(endpoint)
    }

    func removeItems(from listId: String, itemIds: [String]) async throws {
        guard !itemIds.isEmpty else { return }
        let endpoint = Endpoint(path: "list/\(listId)/bulkitemdel", method: .post, body: try JSONEncoder.api.encode(["itemList": itemIds]))
        try await api.sendWithoutDecoding(endpoint)
    }

    // MARK: - Elections
    func elections(page: Int = 1, items: Int = 25, filter: String? = nil, workgroupId: String? = nil) async throws -> PagedResponse<WotlweduElection> {
        var extra: [URLQueryItem] = []
        if let workgroupId, !workgroupId.isEmpty {
            extra.append(URLQueryItem(name: "workgroupId", value: workgroupId))
        }
        return try await dataService.pagedList(path: "election/", detail: "group,list,category,image", page: page, items: items, filter: filter, extraQuery: extra)
    }

    func electionDetail(id: String) async throws -> WotlweduElection {
        try await dataService.detail(path: "election/", id: id, detail: "group,list,category,image")
    }

    func save(election: WotlweduElection) async throws -> WotlweduElection {
        struct Payload: Encodable {
            let id: String?
            let name: String
            let description: String?
            let text: String?
            let electionType: Int?
            let expiration: Date?
            let statusId: Int?
            let listId: String?
            let groupId: String?
            let categoryId: String?
            let imageId: String?
            let workgroupId: String?
        }
        let payload = Payload(
            id: election.id,
            name: election.name ?? "",
            description: election.description,
            text: election.text,
            electionType: election.electionType,
            expiration: election.expiration,
            statusId: election.statusId,
            listId: election.list?.id,
            groupId: election.group?.id,
            categoryId: election.category?.id,
            imageId: election.image?.id,
            workgroupId: election.workgroupId
        )
        return try await dataService.save(path: "election/", id: election.id, payload: payload)
    }

    func deleteElection(id: String) async throws {
        try await dataService.delete(path: "election/", id: id)
    }

    func startElection(id: String) async throws {
        let endpoint = Endpoint(path: "election/\(id)/start", method: .post)
        try await api.sendWithoutDecoding(endpoint)
    }

    func stopElection(id: String) async throws {
        let endpoint = Endpoint(path: "election/\(id)/stop", method: .post)
        try await api.sendWithoutDecoding(endpoint)
    }

    // MARK: - Votes
    func votes(page: Int = 1, items: Int = 25, filter: String? = nil) async throws -> PagedResponse<WotlweduVote> {
        try await dataService.pagedList(path: "vote/", detail: "user,item,election,image", page: page, items: items, filter: filter)
    }

    func nextVote(electionId: String) async throws -> WotlweduVote {
        let endpoint = Endpoint(path: "vote/\(electionId)/next", method: .get)
        let response: APIResponse<WotlweduVote> = try await api.send(endpoint)
        guard let data = response.data else { throw APIError.server(message: response.message ?? "No votes available", url: nil) }
        return data
    }

    func myVotes() async throws -> [WotlweduVote] {
        let endpoint = Endpoint(path: "vote/next/all", method: .get)
        let response: APIResponse<[WotlweduVote]> = try await api.send(endpoint)
        return response.data ?? []
    }

    func cast(voteId: String, decision: String) async throws {
        let endpoint = Endpoint(path: "cast/\(voteId)/decision", method: .post, body: try JSONEncoder.api.encode(["decision": decision]))
        try await api.sendWithoutDecoding(endpoint)
    }

    // MARK: - Roles & capabilities
    func roles(page: Int = 1, items: Int = 50, filter: String? = nil) async throws -> PagedResponse<WotlweduRole> {
        try await dataService.pagedList(path: "role/", detail: "capability,user", page: page, items: items, filter: filter)
    }

    func capabilities(page: Int = 1, items: Int = 100) async throws -> PagedResponse<WotlweduCap> {
        try await dataService.pagedList(path: "capability/", page: page, items: items)
    }

    func save(role: WotlweduRole) async throws -> WotlweduRole {
        struct Payload: Encodable {
            let name: String
            let description: String?
            let capabilityIds: [String]?
            let userIds: [String]?
        }
        let payload = Payload(
            name: role.name ?? "",
            description: role.description,
            capabilityIds: role.capabilities?.compactMap { $0.id },
            userIds: role.users?.compactMap { $0.id }
        )
        return try await dataService.save(path: "role/", id: role.id, payload: payload)
    }

    func deleteRole(id: String) async throws {
        try await dataService.delete(path: "role/", id: id)
    }

    // MARK: - Users & friends
    func users(page: Int = 1, items: Int = 50, filter: String? = nil) async throws -> PagedResponse<WotlweduUser> {
        try await dataService.pagedList(path: "user/", detail: "image", page: page, items: items, filter: filter)
    }

    func userDetail(id: String) async throws -> WotlweduUser {
        try await dataService.detail(path: "user/", id: id, detail: "image")
    }

    func save(user: WotlweduUser) async throws -> WotlweduUser {
        struct Payload: Encodable {
            let email: String
            let firstName: String?
            let lastName: String?
            let alias: String?
            let active: Bool?
            let verified: Bool?
            let enable2fa: Bool?
            let imageId: String?
            let admin: Bool?
            let systemAdmin: Bool?
            let organizationId: String?
            let organizationAdmin: Bool?
            let workgroupAdmin: Bool?
            let adminWorkgroupId: String?
        }
        let payload = Payload(
            email: user.email ?? "",
            firstName: user.firstName,
            lastName: user.lastName,
            alias: user.alias,
            active: user.active,
            verified: user.verified,
            enable2fa: user.enable2fa,
            imageId: user.image?.id,
            admin: user.admin,
            systemAdmin: user.systemAdmin ?? user.admin,
            organizationId: user.organizationId,
            organizationAdmin: user.organizationAdmin,
            workgroupAdmin: user.workgroupAdmin,
            adminWorkgroupId: user.adminWorkgroupId
        )
        return try await dataService.save(path: "user/", id: user.id, payload: payload)
    }

    func deleteUser(id: String) async throws {
        try await dataService.delete(path: "user/", id: id)
    }

    func friends(userId: String, showBlocked: Bool = false) async throws -> [WotlweduUser] {
        var query: [URLQueryItem] = []
        if showBlocked { query.append(URLQueryItem(name: "blocked", value: "1")) }
        let endpoint = Endpoint(path: "user/\(userId)/friend", method: .get, query: query)
        let response: APIResponse<[WotlweduUser]> = try await api.send(endpoint)
        return response.data ?? []
    }

    func addFriend(email: String) async throws {
        let endpoint = Endpoint(path: "user/request", method: .post, body: try JSONEncoder.api.encode(["email": email]))
        try await api.sendWithoutDecoding(endpoint)
    }

    func addFriend(id: String) async throws {
        let endpoint = Endpoint(path: "user/request/\(id)", method: .post)
        try await api.sendWithoutDecoding(endpoint)
    }

    func deleteRelationship(id: String) async throws {
        let endpoint = Endpoint(path: "user/relationship/\(id)", method: .delete)
        try await api.sendWithoutDecoding(endpoint)
    }

    func confirmFriend(token: String) async throws {
        let endpoint = Endpoint(path: "user/accept/\(token)", method: .post)
        try await api.sendWithoutDecoding(endpoint)
    }

    func blockFriend(id: String) async throws {
        let endpoint = Endpoint(path: "user/block/\(id)", method: .put)
        try await api.sendWithoutDecoding(endpoint)
    }
}
