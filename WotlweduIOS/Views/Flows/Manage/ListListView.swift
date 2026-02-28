import SwiftUI

struct ListListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            ListListContent(service: service, workgroupId: appViewModel.activeWorkgroupId)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct ListListContent: View {
    let service: WotlweduDomainService
    let workgroupId: String?
    @StateObject private var viewModel: PagedListViewModel<WotlweduList>
    @State private var editing: WotlweduList?
    @State private var items: [WotlweduItem] = []
    @State private var categories: [WotlweduCategory] = []

    init(service: WotlweduDomainService, workgroupId: String?) {
        self.service = service
        self.workgroupId = workgroupId
        _viewModel = StateObject(wrappedValue: PagedListViewModel<WotlweduList> { page, items, filter in
            let response = try await service.lists(page: page, items: items, filter: filter, workgroupId: workgroupId)
            return PagedResult(items: response.collection, page: response.page ?? 1, total: response.total ?? response.collection.count, itemsPerPage: response.itemsPerPage ?? items)
        })
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { list in
                VStack(alignment: .leading) {
                    Text(list.name ?? "List").font(.headline)
                    if let desc = list.description { Text(desc).font(.subheadline) }
                    if let category = list.category?.name {
                        Text("Category: \(category)").font(.caption).foregroundStyle(.secondary)
                    }
                    if let count = list.items?.count {
                        Text("\(count) items").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { editing = list }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task {
                            if let id = list.id { try? await service.deleteList(id: id); await viewModel.load() }
                        }
                    }
                }
            }
        }
        .navigationTitle("Lists")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editing = WotlweduList(id: nil, workgroupId: workgroupId, name: "", description: "", category: nil, items: [])
                } label: { Image(systemName: "plus") }
            }
        }
        .task {
            await viewModel.load()
            await loadItems()
            await loadCategories()
        }
        .sheet(item: $editing) { list in
            let initialIds = Set(list.items?.compactMap { $0.id } ?? [])
            ListEditor(list: list, items: items, categories: categories) { updated, selectedIds in
                Task {
                    let saved = try? await service.save(list: updated)
                    let listId = saved?.id ?? updated.id
                    if let listId {
                        let selectedNonNil = Set(selectedIds.compactMap { $0 })
                        let toAdd = Array(selectedNonNil.subtracting(initialIds))
                        let toRemove = Array(initialIds.subtracting(selectedNonNil))
                        try? await service.addItems(to: listId, itemIds: toAdd)
                        try? await service.removeItems(from: listId, itemIds: toRemove)
                    }
                    editing = nil
                    await viewModel.load()
                }
            }
        }
    }

    private func loadItems() async {
        if let result = try? await service.items(page: 1, items: 500, filter: nil, workgroupId: workgroupId) {
            items = result.collection.sortedByName()
        }
    }

    private func loadCategories() async {
        if let result = try? await service.categories(page: 1, items: 200, filter: nil) {
            categories = result.collection.sortedByName()
        }
    }
}

private struct ListEditor: View {
    @State var list: WotlweduList
    let items: [WotlweduItem]
    let categories: [WotlweduCategory]
    var onSave: (WotlweduList, Set<String?>) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItemIds: Set<String?> = []
    @State private var selectedCategoryId: String?

    init(list: WotlweduList, items: [WotlweduItem], categories: [WotlweduCategory], onSave: @escaping (WotlweduList, Set<String?>) -> Void) {
        self.list = list
        self.items = items
        self.categories = categories
        self.onSave = onSave
        _selectedItemIds = State(initialValue: Set(list.items?.map { $0.id } ?? []))
        _selectedCategoryId = State(initialValue: list.category?.id)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: Binding($list.name, replacingNilWith: ""))
                TextField("Description", text: Binding($list.description, replacingNilWith: ""))
                Picker("Category", selection: Binding(
                    get: { selectedCategoryId ?? "" },
                    set: { selectedCategoryId = $0.isEmpty ? nil : $0 }
                )) {
                    Text("None").tag("")
                    ForEach(categories) { category in
                        Text(category.name ?? "Unnamed").tag(category.id ?? "")
                    }
                }
                MultiSelectList(title: "Items", items: items, selection: $selectedItemIds)
            }
            .navigationTitle(list.id == nil ? "New List" : "Edit List")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        list.category = categories.first { $0.id == selectedCategoryId }
                        list.items = items.filter { selectedItemIds.contains($0.id) }
                        onSave(list, selectedItemIds)
                        dismiss()
                    }
                }
            }
        }
    }
}
