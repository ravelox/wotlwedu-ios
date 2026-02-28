import Foundation

enum NotificationPresentation: Identifiable {
    case message(title: String, body: String)
    case votes
    case friends

    var id: String {
        switch self {
        case .message(let title, _):
            return "message-\(title)"
        case .votes:
            return "votes"
        case .friends:
            return "friends"
        }
    }
}

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published var notifications: [WotlweduNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var presentation: NotificationPresentation?

    let domainService: WotlweduDomainService
    private let appViewModel: AppViewModel
    private(set) var page: Int = 1
    private(set) var total: Int = 0
    private(set) var itemsPerPage: Int = 25

    init(domainService: WotlweduDomainService, appViewModel: AppViewModel) {
        self.domainService = domainService
        self.appViewModel = appViewModel
    }

    func load(page: Int = 1, items: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        do {
            let pageResponse = try await domainService.notifications(page: page, items: items ?? itemsPerPage)
            notifications = pageResponse.collection
            self.page = pageResponse.page ?? page
            self.total = pageResponse.total ?? notifications.count
            self.itemsPerPage = pageResponse.itemsPerPage ?? (items ?? itemsPerPage)
            let unread = notifications.filter { $0.status?.id == String(NotificationStatusId.unread) || $0.status?.name?.lowercased() == "unread" }.count
            if total <= notifications.count {
                appViewModel.setUnreadNotifications(unread)
            } else {
                await appViewModel.refreshNotifications()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func refresh() async {
        await load(page: page, items: itemsPerPage)
    }

    func delete(notification: WotlweduNotification) async {
        guard let id = notification.id else { return }
        do {
            try await domainService.deleteNotification(id: id)
            removeNotification(notification)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markStatus(notification: WotlweduNotification, statusId: Int) async {
        guard let id = notification.id else { return }
        guard currentStatusId(notification) != statusId else { return }
        do {
            try await domainService.setNotificationStatus(id: id, statusId: statusId)
            updateNotification(notificationId: id, statusId: statusId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func performPrimaryAction(for notification: WotlweduNotification) async {
        switch notification.type {
        case NotificationTypeId.friendRequest:
            await acceptFriendRequest(notification)
        case NotificationTypeId.shareItem:
            await acceptSharedItem(notification)
        case NotificationTypeId.shareImage:
            await acceptSharedImage(notification)
        case NotificationTypeId.shareList:
            await acceptSharedList(notification)
        case NotificationTypeId.electionStart:
            await markStatus(notification: notification, statusId: NotificationStatusId.read)
            presentation = .votes
        case NotificationTypeId.electionEnd, NotificationTypeId.electionExpired:
            await previewElection(notification)
        default:
            await markStatus(notification: notification, statusId: NotificationStatusId.read)
        }
    }

    func acceptFriendRequest(_ notification: WotlweduNotification) async {
        guard let token = notification.objectId else { return }
        do {
            try await domainService.confirmFriend(token: token)
            removeNotification(notification)
            presentation = .friends
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func blockSender(_ notification: WotlweduNotification) async {
        guard let senderId = notification.sender?.id else { return }
        do {
            try await domainService.blockFriend(id: senderId)
            removeNotification(notification)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptSharedItem(_ notification: WotlweduNotification) async {
        guard let notificationId = notification.id else { return }
        do {
            try await domainService.acceptSharedItem(notificationId: notificationId)
            removeNotification(notification)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptSharedImage(_ notification: WotlweduNotification) async {
        guard let notificationId = notification.id else { return }
        do {
            try await domainService.acceptImage(notificationId: notificationId)
            removeNotification(notification)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptSharedList(_ notification: WotlweduNotification) async {
        guard let notificationId = notification.id else { return }
        do {
            try await domainService.acceptList(notificationId: notificationId)
            removeNotification(notification)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func previewSharedItem(_ notification: WotlweduNotification) async {
        guard let objectId = notification.objectId else { return }
        do {
            let item = try await domainService.itemDetail(id: objectId, notificationId: notification.id)
            await markStatus(notification: notification, statusId: NotificationStatusId.read)
            presentation = .message(
                title: item.name ?? "Item",
                body: [item.description, item.location, item.url].compactMap { $0 }.joined(separator: "\n\n")
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func previewSharedImage(_ notification: WotlweduNotification) async {
        guard let objectId = notification.objectId else { return }
        do {
            let image = try await domainService.imageDetail(id: objectId, notificationId: notification.id)
            await markStatus(notification: notification, statusId: NotificationStatusId.read)
            presentation = .message(
                title: image.name ?? "Image",
                body: [image.description, image.url].compactMap { $0 }.joined(separator: "\n\n")
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func previewSharedList(_ notification: WotlweduNotification) async {
        guard let objectId = notification.objectId else { return }
        do {
            let list = try await domainService.listDetail(id: objectId, notificationId: notification.id)
            await markStatus(notification: notification, statusId: NotificationStatusId.read)
            let itemSummary = list.items?.compactMap { $0.name }.joined(separator: ", ") ?? ""
            presentation = .message(
                title: list.name ?? "List",
                body: [list.description, itemSummary.isEmpty ? nil : "Items: \(itemSummary)"].compactMap { $0 }.joined(separator: "\n\n")
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func previewElection(_ notification: WotlweduNotification) async {
        guard let objectId = notification.objectId else { return }
        do {
            let election = try await domainService.electionDetail(id: objectId)
            await markStatus(notification: notification, statusId: NotificationStatusId.read)
            presentation = .message(
                title: election.name ?? "Election",
                body: [election.description, election.text, election.status?.name].compactMap { $0 }.joined(separator: "\n\n")
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func currentStatusId(_ notification: WotlweduNotification) -> Int? {
        if let id = notification.status?.id, let numeric = Int(id) {
            return numeric
        }
        switch notification.status?.name?.lowercased() {
        case "unread":
            return NotificationStatusId.unread
        case "read":
            return NotificationStatusId.read
        case "archived":
            return NotificationStatusId.archived
        default:
            return nil
        }
    }

    private func removeNotification(_ notification: WotlweduNotification) {
        guard let id = notification.id else { return }
        let wasUnread = currentStatusId(notification) == NotificationStatusId.unread
        notifications.removeAll { $0.id == id }
        if wasUnread {
            appViewModel.adjustUnreadNotifications(by: -1)
        }
    }

    private func updateNotification(notificationId: String, statusId: Int) {
        guard let index = notifications.firstIndex(where: { $0.id == notificationId }) else { return }

        let previousStatus = currentStatusId(notifications[index])
        notifications[index].status = WotlweduStatus(
            id: String(statusId),
            name: statusId == NotificationStatusId.unread ? "Unread" : "Read",
            object: "notification"
        )

        if previousStatus == NotificationStatusId.unread && statusId != NotificationStatusId.unread {
            appViewModel.adjustUnreadNotifications(by: -1)
        } else if previousStatus != NotificationStatusId.unread && statusId == NotificationStatusId.unread {
            appViewModel.adjustUnreadNotifications(by: 1)
        }
    }
}
