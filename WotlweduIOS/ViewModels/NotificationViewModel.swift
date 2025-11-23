import Foundation

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published var notifications: [WotlweduNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let domainService: WotlweduDomainService

    init(domainService: WotlweduDomainService) {
        self.domainService = domainService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let page = try await domainService.notifications()
            notifications = page.collection
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func delete(notification: WotlweduNotification) async {
        guard let id = notification.id else { return }
        do {
            try await domainService.deleteNotification(id: id)
            notifications.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markStatus(notification: WotlweduNotification, status: String) async {
        guard let id = notification.id else { return }
        do {
            try await domainService.setNotificationStatus(id: id, status: status)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
