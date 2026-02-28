import SwiftUI
import PhotosUI
import UIKit

struct ImageListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            ImageListContent(service: service, workgroupId: appViewModel.activeWorkgroupId)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct ImageListContent: View {
    let service: WotlweduDomainService
    let workgroupId: String?
    @StateObject private var viewModel: PagedListViewModel<WotlweduImage>
    @State private var editing: WotlweduImage?
    @State private var showingUploader = false
    @State private var categories: [WotlweduCategory] = []

    init(service: WotlweduDomainService, workgroupId: String?) {
        self.service = service
        self.workgroupId = workgroupId
        _viewModel = StateObject(wrappedValue: PagedListViewModel<WotlweduImage> { page, items, filter in
            let response = try await service.images(page: page, items: items, filter: filter, workgroupId: workgroupId)
            return PagedResult(items: response.collection, page: response.page ?? 1, total: response.total ?? response.collection.count, itemsPerPage: response.itemsPerPage ?? items)
        })
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { image in
                VStack(alignment: .leading) {
                    Text(image.name ?? "Image").font(.headline)
                    if let description = image.description {
                        Text(description).font(.subheadline).foregroundStyle(.secondary)
                    }
                    if let category = image.category?.name {
                        Text("Category: \(category)").font(.caption).foregroundStyle(.secondary)
                    }
                    if let url = image.url {
                        Text(url).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { editing = image }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task {
                            if let id = image.id { try? await service.deleteImage(id: id); await viewModel.load() }
                        }
                    }
                }
            }
        }
        .navigationTitle("Images")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingUploader = true } label: { Image(systemName: "plus") }
            }
        }
        .task {
            await viewModel.load()
            await loadCategories()
        }
        .sheet(isPresented: $showingUploader) {
            ImageUploadView(workgroupId: workgroupId, categories: categories) { newImage in
                Task {
                    editing = nil
                    await viewModel.load()
                }
            }
        }
        .sheet(item: $editing) { image in
            ImageMetaEditor(image: image, categories: categories) { updated in
                Task {
                    if let id = updated.id {
                        _ = try? await service.mediaService.updateImageRecord(
                            id: id,
                            name: updated.name ?? "",
                            description: updated.description,
                            workgroupId: updated.workgroupId,
                            categoryId: updated.category?.id
                        )
                        await viewModel.load()
                    }
                    editing = nil
                }
            }
        }
    }

    private func loadCategories() async {
        if let result = try? await service.categories(page: 1, items: 200, filter: nil) {
            categories = result.collection.sortedByName()
        }
    }
}

private struct ImageUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var name = ""
    @State private var description = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedData: Data?
    @State private var isSaving = false
    @State private var selectedCategoryId: String?

    let workgroupId: String?
    let categories: [WotlweduCategory]
    var onComplete: (WotlweduImage) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Description", text: $description)
                Picker("Category", selection: Binding(
                    get: { selectedCategoryId ?? "" },
                    set: { selectedCategoryId = $0.isEmpty ? nil : $0 }
                )) {
                    Text("None").tag("")
                    ForEach(categories) { category in
                        Text(category.name ?? "Unnamed").tag(category.id ?? "")
                    }
                }
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo")
                        Text(selectedData == nil ? "Select image" : "Change image")
                    }
                }
                if let data = selectedData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                }
            }
            .navigationTitle("Upload Image")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await save()
                        }
                    } label: {
                        Text("Save")
                    }
                    .disabled(isSaving || name.isEmpty || selectedData == nil)
                }
            }
            .onChange(of: selectedItem) { newValue in
                guard let item = newValue else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        selectedData = data
                    }
                }
            }
        }
    }

    private func save() async {
        guard let data = selectedData, let service = appViewModel.domainService else { return }
        isSaving = true
        do {
            let imageRecord = try await service.mediaService.createImageRecord(
                name: name,
                description: description,
                workgroupId: workgroupId,
                categoryId: selectedCategoryId
            )
            if let id = imageRecord.id {
                try await service.mediaService.uploadImageFile(imageId: id, data: data)
            }
            onComplete(imageRecord)
            dismiss()
        } catch {
            // surface in parent
        }
        isSaving = false
    }
}

private struct ImageMetaEditor: View {
    @State var image: WotlweduImage
    let categories: [WotlweduCategory]
    var onSave: (WotlweduImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategoryId: String?

    init(image: WotlweduImage, categories: [WotlweduCategory], onSave: @escaping (WotlweduImage) -> Void) {
        self.image = image
        self.categories = categories
        self.onSave = onSave
        _selectedCategoryId = State(initialValue: image.category?.id)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: Binding($image.name, replacingNilWith: ""))
                TextField("Description", text: Binding($image.description, replacingNilWith: ""))
                Picker("Category", selection: Binding(
                    get: { selectedCategoryId ?? "" },
                    set: { selectedCategoryId = $0.isEmpty ? nil : $0 }
                )) {
                    Text("None").tag("")
                    ForEach(categories) { category in
                        Text(category.name ?? "Unnamed").tag(category.id ?? "")
                    }
                }
            }
            .navigationTitle("Edit Image")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        image.category = categories.first { $0.id == selectedCategoryId }
                        onSave(image)
                        dismiss()
                    }
                }
            }
        }
    }
}
