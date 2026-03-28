import Foundation

@MainActor
final class VotingViewModel: ObservableObject {
    @Published var upcomingVotes: [WotlweduVote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let domainService: WotlweduDomainService
    let electionId: String?

    init(domainService: WotlweduDomainService, electionId: String? = nil) {
        self.domainService = domainService
        self.electionId = electionId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            if let electionId, !electionId.isEmpty {
                let vote = try await domainService.nextVote(electionId: electionId)
                upcomingVotes = [vote]
            } else {
                upcomingVotes = try await domainService.myVotes()
            }
        } catch {
            errorMessage = error.localizedDescription
            upcomingVotes = []
        }
        isLoading = false
    }

    func cast(voteId: String, decision: String) async {
        do {
            try await domainService.cast(voteId: voteId, decision: decision)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
