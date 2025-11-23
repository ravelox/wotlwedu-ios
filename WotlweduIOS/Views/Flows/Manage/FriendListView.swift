import SwiftUI

struct FriendListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            FriendListContent(service: service, currentUserId: appViewModel.sessionStore.userId)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct FriendListContent: View {
    let service: WotlweduDomainService
    let currentUserId: String?
    @State private var friends: [WotlweduUser] = []
    @State private var emailToAdd = ""
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Add Friend") {
                HStack {
                    TextField("Email", text: $emailToAdd)
                        .textInputAutocapitalization(.never)
                    Button("Send") {
                        Task {
                            await addFriend()
                        }
                    }.disabled(emailToAdd.isEmpty)
                }
            }
            Section("Friends") {
                ForEach(friends) { friend in
                    VStack(alignment: .leading) {
                        Text(friend.displayName)
                        Text(friend.email ?? "").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Friends")
        .task { await loadFriends() }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadFriends() async {
        guard let id = currentUserId else { return }
        do {
            friends = try await service.friends(userId: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func addFriend() async {
        do {
            try await service.addFriend(email: emailToAdd)
            emailToAdd = ""
            await loadFriends()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
