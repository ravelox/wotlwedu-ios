import SwiftUI

struct GroupListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            GroupListContent(service: service)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct GroupListContent: View {
    let service: WotlweduDomainService
    @StateObject private var viewModel: PagedListViewModel<WotlweduGroup>
    @State private var editing: WotlweduGroup?
    @State private var categories: [WotlweduCategory] = []
    @State private var users: [WotlweduUser] = []

    init(service: WotlweduDomainService) {
        self.service = service
        _viewModel = StateObject(wrappedValue: PagedListViewModel<WotlweduGroup> { page, items, filter in
            let response = try await service.groups(page: page, items: items, filter: filter)
            return PagedResult(items: response.collection, page: response.page ?? 1, total: response.total ?? response.collection.count, itemsPerPage: response.itemsPerPage ?? items)
        })
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { group in
                VStack(alignment: .leading) {
                    Text(group.name ?? "Untitled").font(.headline)
                    if let category = group.category?.name {
                        Text("Category: \(category)").font(.subheadline)
                    }
                    if let count = group.users?.count {
                        Text("\(count) members").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { editing = group }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task {
                            if let id = group.id {
                                try? await service.deleteGroup(id: id)
                                await viewModel.load()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Audience Groups")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editing = WotlweduGroup(id: nil, name: "", description: "", users: [], category: nil)
                } label: { Image(systemName: "plus") }
            }
        }
        .task {
            await viewModel.load()
            await loadLookups()
        }
        .sheet(item: $editing) { group in
            let originalIds = Set(group.users?.compactMap { $0.id } ?? [])
            GroupEditor(group: group, categories: categories, users: users) { updated in
                Task {
                    _ = try? await service.save(group: updated, originalMemberIds: originalIds)
                    editing = nil
                    await viewModel.load()
                }
            }
        }
    }

    private func loadLookups() async {
        async let cats = service.categories(page: 1, items: 200, filter: nil)
        async let usrs = service.users(page: 1, items: 200, filter: nil)
        if let catData = try? await cats {
            categories = catData.collection.sortedByName()
        }
        if let userData = try? await usrs {
            users = userData.collection.sortedByName()
        }
    }
}

private struct GroupEditor: View {
    @State var group: WotlweduGroup
    let categories: [WotlweduCategory]
    let users: [WotlweduUser]
    var onSave: (WotlweduGroup) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategoryId: String?
    @State private var memberIds: Set<String?> = []

    init(group: WotlweduGroup, categories: [WotlweduCategory], users: [WotlweduUser], onSave: @escaping (WotlweduGroup) -> Void) {
        self.group = group
        self.categories = categories
        self.users = users
        self.onSave = onSave
        _selectedCategoryId = State(initialValue: group.category?.id)
        _memberIds = State(initialValue: Set(group.users?.map { $0.id } ?? []))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: Binding($group.name, replacingNilWith: ""))
                TextField("Description", text: Binding($group.description, replacingNilWith: ""))

                Picker("Category", selection: Binding(
                    get: { selectedCategoryId ?? "" },
                    set: { selectedCategoryId = $0.isEmpty ? nil : $0 }
                )) {
                    Text("None").tag("")
                    ForEach(categories) { category in
                        Text(category.name ?? "Unnamed").tag(category.id ?? "")
                    }
                }

                MultiSelectList(title: "Members", items: users, selection: $memberIds)
            }
            .navigationTitle(group.id == nil ? "New Group" : "Edit Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let selectedCategory = categories.first { $0.id == selectedCategoryId }
                        let selectedUsers = users.filter { memberIds.contains($0.id) }
                        group.category = selectedCategory
                        group.users = selectedUsers
                        onSave(group)
                        dismiss()
                    }
                }
            }
        }
    }
}
