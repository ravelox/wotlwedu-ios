import SwiftUI

struct CategoryListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            CategoryListContent(service: service)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct CategoryListContent: View {
    let service: WotlweduDomainService
    @StateObject private var viewModel: PagedListViewModel<WotlweduCategory>
    @State private var editing: WotlweduCategory?

    init(service: WotlweduDomainService) {
        self.service = service
        _viewModel = StateObject(wrappedValue: PagedListViewModel<WotlweduCategory> { page, items, filter in
            let response = try await service.categories(page: page, items: items, filter: filter)
            return PagedResult(items: response.collection, page: response.page ?? 1, total: response.total ?? response.collection.count, itemsPerPage: response.itemsPerPage ?? items)
        })
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { category in
                VStack(alignment: .leading) {
                    Text(category.name ?? "Untitled").font(.headline)
                    if let description = category.description {
                        Text(description).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { editing = category }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task {
                            if let id = category.id {
                                try? await service.deleteCategory(id: id)
                                await viewModel.load()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editing = WotlweduCategory(id: nil, name: "", description: "")
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task { await viewModel.load() }
        .sheet(item: $editing, content: { category in
            CategoryEditor(category: category) { updated in
                Task {
                    _ = try? await service.save(category: updated)
                    editing = nil
                    await viewModel.load()
                }
            }
        })
    }
}

private struct CategoryEditor: View {
    @State var category: WotlweduCategory
    var onSave: (WotlweduCategory) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: Binding($category.name, replacingNilWith: ""))
                TextField("Description", text: Binding($category.description, replacingNilWith: ""))
            }
            .navigationTitle(category.id == nil ? "New Category" : "Edit Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(category)
                        dismiss()
                    }
                }
            }
        }
    }
}
