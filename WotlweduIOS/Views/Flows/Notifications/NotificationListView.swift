import SwiftUI

struct NotificationListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            NotificationListContent(
                viewModel: NotificationViewModel(domainService: service, appViewModel: appViewModel)
            )
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct NotificationListContent: View {
    @StateObject var viewModel: NotificationViewModel

    var body: some View {
        List {
            ForEach(viewModel.notifications) { notification in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Circle()
                            .fill(viewModel.currentStatusId(notification) == NotificationStatusId.unread ? Color.blue : Color.gray.opacity(0.4))
                            .frame(width: 10, height: 10)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.sender?.displayName ?? "Notification")
                                .font(.headline)
                            Text(notification.text ?? "Notification")
                                .font(.subheadline)
                            if let status = notification.status?.name {
                                Text(status)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack {
                        if let primaryTitle = primaryActionTitle(for: notification) {
                            Button(primaryTitle) {
                                Task { await viewModel.performPrimaryAction(for: notification) }
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if let secondaryTitle = secondaryActionTitle(for: notification) {
                            Button(secondaryTitle) {
                                Task { await performSecondaryAction(for: notification) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) {
                        Task { await viewModel.delete(notification: notification) }
                    }

                    if viewModel.currentStatusId(notification) == NotificationStatusId.unread {
                        Button("Read") {
                            Task { await viewModel.markStatus(notification: notification, statusId: NotificationStatusId.read) }
                        }
                        .tint(.blue)
                    } else {
                        Button("Unread") {
                            Task { await viewModel.markStatus(notification: notification, statusId: NotificationStatusId.unread) }
                        }
                        .tint(.orange)
                    }
                }
                .contextMenu {
                    if notification.type == NotificationTypeId.friendRequest {
                        Button("Accept Friend Request") {
                            Task { await viewModel.acceptFriendRequest(notification) }
                        }
                        Button("Block Sender", role: .destructive) {
                            Task { await viewModel.blockSender(notification) }
                        }
                    }

                    if notification.type == NotificationTypeId.shareItem {
                        Button("Preview Item") {
                            Task { await viewModel.previewSharedItem(notification) }
                        }
                        Button("Accept Item") {
                            Task { await viewModel.acceptSharedItem(notification) }
                        }
                    }

                    if notification.type == NotificationTypeId.shareImage {
                        Button("Preview Image") {
                            Task { await viewModel.previewSharedImage(notification) }
                        }
                        Button("Accept Image") {
                            Task { await viewModel.acceptSharedImage(notification) }
                        }
                    }

                    if notification.type == NotificationTypeId.shareList {
                        Button("Preview List") {
                            Task { await viewModel.previewSharedList(notification) }
                        }
                        Button("Accept List") {
                            Task { await viewModel.acceptSharedList(notification) }
                        }
                    }

                    if notification.type == NotificationTypeId.electionStart {
                        Button("Open Voting") {
                            Task { await viewModel.performPrimaryAction(for: notification) }
                        }
                    }

                    if notification.type == NotificationTypeId.electionEnd || notification.type == NotificationTypeId.electionExpired {
                        Button("View Election") {
                            Task { await viewModel.previewElection(notification) }
                        }
                    }
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading notifications...")
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .navigationTitle("Notifications")
        .sheet(item: $viewModel.presentation) { presentation in
            switch presentation {
            case .votes:
                VotingView()
            case .friends:
                FriendListView()
            case .message(let title, let body):
                NavigationStack {
                    ScrollView {
                        Text(body.isEmpty ? "No additional details." : body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func primaryActionTitle(for notification: WotlweduNotification) -> String? {
        switch notification.type {
        case NotificationTypeId.friendRequest:
            return "Accept"
        case NotificationTypeId.shareItem, NotificationTypeId.shareImage, NotificationTypeId.shareList:
            return "Accept"
        case NotificationTypeId.electionStart:
            return "Vote"
        case NotificationTypeId.electionEnd, NotificationTypeId.electionExpired:
            return "View"
        default:
            return nil
        }
    }

    private func secondaryActionTitle(for notification: WotlweduNotification) -> String? {
        switch notification.type {
        case NotificationTypeId.shareItem, NotificationTypeId.shareImage, NotificationTypeId.shareList:
            return "Preview"
        case NotificationTypeId.friendRequest:
            return "Block"
        default:
            return nil
        }
    }

    private func performSecondaryAction(for notification: WotlweduNotification) async {
        switch notification.type {
        case NotificationTypeId.shareItem:
            await viewModel.previewSharedItem(notification)
        case NotificationTypeId.shareImage:
            await viewModel.previewSharedImage(notification)
        case NotificationTypeId.shareList:
            await viewModel.previewSharedList(notification)
        case NotificationTypeId.friendRequest:
            await viewModel.blockSender(notification)
        default:
            break
        }
    }
}
