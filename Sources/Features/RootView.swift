import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionStore
    var body: some View {
        Group {
            if session.isAuthenticated {
                NavigationSplitView {
                    ElectionListView()
                } detail: {
                    Text("Select an election").foregroundStyle(.secondary)
                }
            } else {
                NavigationStack { LoginView() }
            }
        }
        .task { await session.restore() }
    }
}