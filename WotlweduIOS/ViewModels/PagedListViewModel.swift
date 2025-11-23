import Foundation

@MainActor
final class PagedListViewModel<Model: Identifiable & Codable>: ObservableObject {
    @Published var items: [Model] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filter: String = ""
    @Published var page: Int = 1
    @Published var total: Int = 0
    @Published var itemsPerPage: Int = 25

    typealias PageFetcher = (_ page: Int, _ items: Int, _ filter: String?) async throws -> PagedResult<Model>
    private let fetchPage: PageFetcher

    init(fetchPage: @escaping PageFetcher) {
        self.fetchPage = fetchPage
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await fetchPage(page, itemsPerPage, filter.isEmpty ? nil : filter)
            items = result.items
            page = result.page
            total = result.total
            itemsPerPage = result.itemsPerPage
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func nextPage() async {
        guard page * itemsPerPage < total else { return }
        page += 1
        await load()
    }

    func prevPage() async {
        guard page > 1 else { return }
        page -= 1
        await load()
    }
}
