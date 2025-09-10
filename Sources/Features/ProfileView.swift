import SwiftUI

struct ProfileView: View {
    @State private var me: AppUser?
    @State private var error: String?
    
    var body: some View {
        List {
            if let me {
                LabeledContent("Email", value: me.email)
                if let name = me.name { LabeledContent("Name", value: name) }
            }
            if let error { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle("Profile")
        .task { await load() }
        .refreshable { await load() }
    }
    
    private func load() async {
        do { me = try await GeneratedBackend.me() }
        catch { self.error = error.localizedDescription }
    }
}