import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @State private var me: UserProfile?
    @State private var error: String?

    var body: some View {
        List {
            if let me {
                LabeledContent("Email", value: me.email)
                if let name = me.name { LabeledContent("Name", value: name) }
            }
            if let error {
                Text(error).foregroundStyle(.red)
            }
            Button("Sign Out", role: .destructive) { session.signOut() }
        }
        .navigationTitle("Profile")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        guard let api = session.api else { return }
        do { me = try await api.me() }
        catch { self.error = (error as? APIError)?.userMessage ?? error.localizedDescription }
    }
}