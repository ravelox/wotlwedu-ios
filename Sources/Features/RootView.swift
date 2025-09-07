import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        Group {
            if session.isAuthenticated {
                NavigationSplitView {
                    ElectionListView()
                } detail: {
                    Text("Pick an election to view details")
                        .foregroundStyle(.secondary)
                }
            } else {
                NavigationStack { LoginView() }
            }
        }
        .task { await session.restore() }
    }
}