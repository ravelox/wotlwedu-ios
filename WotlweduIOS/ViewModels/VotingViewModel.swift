import Foundation

@MainActor
final class VotingViewModel: ObservableObject {
    @Published var upcomingVotes: [WotlweduVote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let domainService: WotlweduDomainService

    init(domainService: WotlweduDomainService) {
        self.domainService = domainService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            upcomingVotes = try await domainService.myVotes()
        } catch {
            errorMessage = error.localizedDescription
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
