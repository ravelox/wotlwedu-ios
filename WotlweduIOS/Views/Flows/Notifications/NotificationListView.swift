import SwiftUI

struct NotificationListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            NotificationListContent(viewModel: NotificationViewModel(domainService: service))
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
                VStack(alignment: .leading, spacing: 6) {
                    Text(notification.text ?? "Notification")
                        .font(.headline)
                    if let sender = notification.sender?.displayName {
                        Text("From \(sender)").font(.subheadline)
                    }
                    if let status = notification.status?.name {
                        Text(status).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task { await viewModel.delete(notification: notification) }
                    }
                    Button("Mark read") {
                        Task { await viewModel.markStatus(notification: notification, status: "read") }
                    }.tint(.blue)
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
        .navigationTitle("Notifications")
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
