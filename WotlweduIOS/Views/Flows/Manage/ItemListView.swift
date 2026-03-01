import SwiftUI

struct ItemListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            ItemListContent(service: service, workgroupId: appViewModel.activeWorkgroupId)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct ItemListContent: View {
    let service: WotlweduDomainService
    let workgroupId: String?
    @StateObject private var viewModel: PagedListViewModel<WotlweduItem>
    @State private var editing: WotlweduItem?
    @State private var categories: [WotlweduCategory] = []
    @State private var images: [WotlweduImage] = []
    @State private var alertMessage: String?
    @State private var collapsedCategories: Set<String> = []

    init(service: WotlweduDomainService, workgroupId: String?) {
        self.service = service
        self.workgroupId = workgroupId
        _viewModel = StateObject(wrappedValue: PagedListViewModel<WotlweduItem> { page, items, filter in
            let response = try await service.items(page: page, items: items, filter: filter, workgroupId: workgroupId)
            return PagedResult(items: response.collection, page: response.page ?? 1, total: response.total ?? response.collection.count, itemsPerPage: response.itemsPerPage ?? items)
        })
    }

    var body: some View {
        List {
            ForEach(viewModel.items.groupedByCategory()) { group in
                DisclosureGroup(isExpanded: expansionBinding(for: group.categoryName)) {
                    ForEach(group.items) { item in
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Untitled").font(.headline)
                            if let description = item.description {
                                Text(description).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { editing = item }
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                Task {
                                    if let id = item.id {
                                        do {
                                            try await service.deleteItem(id: id)
                                            alertMessage = "Deleted item \(item.name ?? id)"
                                            await viewModel.load()
                                        } catch {
                                            alertMessage = "Delete failed: \(error.localizedDescription)"
                                        }
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Text(group.categoryName).font(.subheadline.weight(.semibold))
                }
            }
        }
        .navigationTitle("Items")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editing = WotlweduItem(
                        id: nil,
                        workgroupId: workgroupId,
                        name: "",
                        description: "",
                        url: nil,
                        location: nil,
                        image: nil,
                        category: nil
                    )
                } label: { Image(systemName: "plus") }
            }
        }
        .task {
            await viewModel.load()
            await loadLookups()
        }
        .sheet(item: $editing) { item in
            ItemEditor(item: item, categories: categories, images: images) { updated in
                Task {
                    do {
                        let saved = try await service.save(item: updated)
                        alertMessage = "Saved item \(saved.name ?? saved.id ?? "")"
                        editing = nil
                        await viewModel.load()
                    } catch {
                        alertMessage = "Save failed: \(error.localizedDescription)"
                    }
                }
            }
        }
        .alert("Status", isPresented: Binding(
            get: { alertMessage != nil },
            set: { _ in alertMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func loadLookups() async {
        if let catData = try? await service.categories(page: 1, items: 200, filter: nil) {
            categories = catData.collection.sortedByName()
        }
        if let imageData = try? await service.images(page: 1, items: 200, filter: nil, workgroupId: workgroupId) {
            images = imageData.collection.sortedByName()
        }
    }

    private func expansionBinding(for categoryName: String) -> Binding<Bool> {
        Binding(
            get: { !collapsedCategories.contains(categoryName) },
            set: { isExpanded in
                if isExpanded {
                    collapsedCategories.remove(categoryName)
                } else {
                    collapsedCategories.insert(categoryName)
                }
            }
        )
    }
}

private struct ItemEditor: View {
    @State var item: WotlweduItem
    let categories: [WotlweduCategory]
    let images: [WotlweduImage]
    var onSave: (WotlweduItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String = ""
    @State private var selectedImage: String = ""

    init(item: WotlweduItem, categories: [WotlweduCategory], images: [WotlweduImage], onSave: @escaping (WotlweduItem) -> Void) {
        self.item = item
        self.categories = categories
        self.images = images
        self.onSave = onSave
        _selectedCategory = State(initialValue: item.category?.id ?? "")
        _selectedImage = State(initialValue: item.image?.id ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: Binding($item.name, replacingNilWith: ""))
                TextField("Description", text: Binding($item.description, replacingNilWith: ""))
                TextField("URL", text: Binding($item.url, replacingNilWith: ""))
                TextField("Location", text: Binding($item.location, replacingNilWith: ""))

                Picker("Category", selection: $selectedCategory) {
                    Text("None").tag("")
                    ForEach(categories) { category in
                        Text(category.name ?? "Unnamed").tag(category.id ?? "")
                    }
                }

                Picker("Image", selection: $selectedImage) {
                    Text("None").tag("")
                    ForEach(images) { image in
                        Text(image.name ?? "Image").tag(image.id ?? "")
                    }
                }
            }
            .navigationTitle(item.id == nil ? "New Item" : "Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        item.category = categories.first { $0.id == selectedCategory }
                        item.image = images.first { $0.id == selectedImage }
                        onSave(item)
                        dismiss()
                    }
                }
            }
        }
    }
}
