import SwiftUI

struct VotingView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            VotingContent(viewModel: VotingViewModel(domainService: service))
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct VotingContent: View {
    @StateObject var viewModel: VotingViewModel

    var body: some View {
        List {
            ForEach(viewModel.upcomingVotes) { vote in
                VStack(alignment: .leading, spacing: 8) {
                    Text(vote.election?.name ?? "Election").font(.headline)
                    if let itemName = vote.item?.name {
                        Text("Item: \(itemName)").font(.subheadline)
                    }
                    HStack {
                        Button {
                            if let id = vote.id { Task { await viewModel.cast(voteId: id, decision: "yes") } }
                        } label: {
                            Label("Yes", systemImage: "hand.thumbsup.fill")
                        }
                        Button {
                            if let id = vote.id { Task { await viewModel.cast(voteId: id, decision: "no") } }
                        } label: {
                            Label("No", systemImage: "hand.thumbsdown.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Cast Vote")
        .task { await viewModel.load() }
        .overlay {
            if viewModel.isLoading { ProgressView("Loading votes...") }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
