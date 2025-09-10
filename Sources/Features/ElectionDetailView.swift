import SwiftUI

struct ElectionDetailView: View {
    let election: AppElection
    @State private var updated: AppElection?
    @State private var error: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text((updated ?? election).name).font(.title2.bold())
                if let desc = (updated ?? election).description { Text(desc).foregroundStyle(.secondary) }
                if let imageURL = (updated ?? election).imageUrl, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { img in img.resizable().scaledToFit() } placeholder: { ProgressView() }
                        .frame(maxHeight: 240).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Divider()
                Text("Items").font(.headline)
                ForEach((updated ?? election).items ?? []) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name).bold()
                            if let d = item.description, !d.isEmpty { Text(d).font(.subheadline).foregroundStyle(.secondary) }
                            if let votes = item.votes { Text(votes == 1 ? "\(votes) vote" : "\(votes) votes").font(.caption) }
                        }
                        Spacer()
                        Button("Vote") { Task { await vote(item: item) } }
                            .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 6)
                }
            }.padding()
        }
        .task { await refresh() }
        .navigationTitle("Election")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func refresh() async {
        do { updated = try await GeneratedBackend.getElection(id: election.id) }
        catch { self.error = error.localizedDescription }
    }
    
    private func vote(item: AppElectionItem) async {
        do {
            try await GeneratedBackend.vote(electionId: election.id, itemId: item.id)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }
}