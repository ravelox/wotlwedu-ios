import SwiftUI

struct HomeDashboardView: View {
    let onSelect: (MainRoute) -> Void
    @EnvironmentObject var appViewModel: AppViewModel

    private let actions: [(title: String, icon: String, route: MainRoute)] = [
        ("Cast vote", "checkmark.circle", .votes),
        ("Friends", "person.2", .friends),
        ("Preferences", "slider.horizontal.3", .preferences),
        ("Groups", "person.3.sequence", .groups),
        ("Categories", "tag", .categories),
        ("Items", "list.bullet", .items),
        ("Images", "photo.on.rectangle", .images),
        ("Lists", "square.stack.3d.up", .lists),
        ("Elections", "flag.2.crossed", .elections),
        ("Notifications", "bell", .notifications)
    ]

    private let adminActions: [(title: String, icon: String, route: MainRoute)] = [
        ("Users", "person.crop.rectangle", .users),
        ("Roles", "lock.shield", .roles)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to wotlwedu")
                        .font(.title.bold())
                    Text("Create lists, share with friends, and vote together.")
                        .foregroundStyle(.secondary)
                    if let message = appViewModel.serverStatus?.message {
                        Label(message, systemImage: "info.circle")
                            .font(.footnote)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                    }
                }

                if appViewModel.unreadNotifications > 0 {
                    HStack {
                        Label("\(appViewModel.unreadNotifications) unread notifications", systemImage: "bell.badge")
                        Spacer()
                        Button("View") { onSelect(.notifications) }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(.yellow.opacity(0.2)))
                }

                Text("Quick actions").font(.headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(actions, id: \.route) { action in
                        Button {
                            onSelect(action.route)
                        } label: {
                            HStack {
                                Image(systemName: action.icon)
                                Text(action.title)
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if appViewModel.isAdmin {
                    Text("Admin").font(.headline)
                    ForEach(adminActions, id: \.route) { action in
                        Button {
                            onSelect(action.route)
                        } label: {
                            HStack {
                                Image(systemName: action.icon)
                                Text(action.title)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Home")
    }
}
