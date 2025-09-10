import SwiftUI

struct ElectionListView: View {
    @State private var elections: [AppElection] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var showingCreate = false
    
    var body: some View {
        List {
            if let error { Text(error).foregroundStyle(.red) }
            ForEach(elections) { election in
                NavigationLink(value: election) {
                    VStack(alignment: .leading) {
                        Text(election.name).font(.headline)
                        if let desc = election.description, !desc.isEmpty {
                            Text(desc).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                }
            }
        }
        .navigationTitle("Elections")
        .navigationDestination(for: AppElection.self) { election in
            ElectionDetailView(election: election) }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink("Profile") { ProfileView() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreate = true } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showingCreate) { NavigationStack { CreateElectionView() } }
        .task { await load() }
        .refreshable { await load() }
    }
    
    private func load() async {
        isLoading = true; defer { isLoading = false }
        do { elections = try await GeneratedBackend.listElections() }
        catch { self.error = error.localizedDescription }
    }
}