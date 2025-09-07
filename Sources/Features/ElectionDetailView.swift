import SwiftUI
import PhotosUI

struct ElectionDetailView: View {
    let election: Election
    @EnvironmentObject var session: SessionStore
    @State private var updated: Election?
    @State private var error: String?
    @State private var showingAddItem = false
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text((updated ?? election).name).font(.title2.bold())
                if let desc = (updated ?? election).description {
                    Text(desc).foregroundStyle(.secondary)
                }
                if let imageURL = (updated ?? election).imageUrl, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { img in img.resizable().scaledToFit() } placeholder: { ProgressView() }
                        .frame(maxHeight: 240).clipShape(RoundedRectangle(cornerRadius: 12))
                }

                HStack {
                    Button("Add Item") { showingAddItem = true }
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Set Cover", systemImage: "photo.badge.plus")
                    }
                    .onChange(of: selectedItem) { _ in Task { await uploadElectionImage() } }
                }

                Divider()
                Text("Items").font(.headline)
                ForEach((updated ?? election).items ?? []) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name).bold()
                            if let d = item.description, !d.isEmpty {
                                Text(d).font(.subheadline).foregroundStyle(.secondary)
                            }
                            if let votes = item.votes {
                                Text(votes == 1 ? "\(votes) vote" : "\(votes) votes").font(.caption)
                            }
                        }
                        Spacer()
                        Button("Vote") {
                            Task { await vote(item: item) }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 6)
                }
            }.padding()
        }
        .task { await refresh() }
        .navigationTitle("Election")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddItem) { NavigationStack { AddItemView(electionId: election.id) } }
    }

    private func refresh() async {
        guard let api = session.api else { return }
        do { updated = try await api.getElection(id: election.id) }
        catch { self.error = (error as? APIError)?.userMessage ?? error.localizedDescription }
    }

    private func vote(item: ElectionItem) async {
        guard let api = session.api else { return }
        do {
            try await api.vote(electionId: election.id, itemId: item.id)
            await refresh()
        } catch {
            self.error = (error as? APIError)?.userMessage ?? error.localizedDescription
        }
    }

    private func uploadElectionImage() async {
        guard let selectedItem, let api = session.api else { return }
        do {
            if let data = try await selectedItem.loadTransferable(type: Data.self) {
                try await api.uploadElectionImage(electionId: election.id, data: data, filename: "cover.jpg", mime: "image/jpeg")
                await refresh()
            }
        } catch { /* ignore */ }
    }
}