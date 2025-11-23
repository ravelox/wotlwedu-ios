import SwiftUI

enum MainRoute: Hashable {
    case notifications
    case preferences
    case categories
    case groups
    case items
    case images
    case lists
    case elections
    case votes
    case roles
    case users
    case friends
    case profile
}

struct MainShellView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeDashboardView(onSelect: { path.append($0) })
                .navigationDestination(for: MainRoute.self) { route in
                    switch route {
                    case .notifications:
                        NotificationListView()
                    case .preferences:
                        PreferenceListView()
                    case .categories:
                        CategoryListView()
                    case .groups:
                        GroupListView()
                    case .items:
                        ItemListView()
                    case .images:
                        ImageListView()
                    case .lists:
                        ListListView()
                    case .elections:
                        ElectionListView()
                    case .votes:
                        VotingView()
                    case .roles:
                        RoleListView()
                    case .users:
                        UserListView()
                    case .friends:
                        FriendListView()
                    case .profile:
                        ProfileView()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        VStack(alignment: .leading) {
                            if let name = appViewModel.displayName {
                                Text(name).font(.subheadline).bold()
                            }
                            if let version = appViewModel.serverStatus?.version {
                                Text("Server v\(version)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            if appViewModel.unreadNotifications > 0 {
                                Button {
                                    path.append(MainRoute.notifications)
                                } label: {
                                    Label("\(appViewModel.unreadNotifications)", systemImage: "bell.fill")
                                }
                            }
                            Button {
                                path.append(MainRoute.profile)
                            } label: {
                                Image(systemName: "person.crop.circle")
                                    .imageScale(.large)
                            }
                        }
                    }
                }
        }
        .task {
            await appViewModel.refreshStatus()
            await appViewModel.refreshNotifications()
        }
    }
}
