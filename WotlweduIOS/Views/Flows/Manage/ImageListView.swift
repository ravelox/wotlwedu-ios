import SwiftUI
import PhotosUI
import UIKit

struct ImageListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            ImageListContent(service: service)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct ImageListContent: View {
    let service: WotlweduDomainService
    @StateObject private var viewModel: PagedListViewModel<WotlweduImage>
    @State private var editing: WotlweduImage?
    @State private var showingUploader = false

    init(service: WotlweduDomainService) {
        self.service = service
        _viewModel = StateObject(wrappedValue: PagedListViewModel<WotlweduImage> { page, items, filter in
            let response = try await service.images(page: page, items: items, filter: filter)
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
        .task { await viewModel.load() }
        .sheet(isPresented: $showingUploader) {
            ImageUploadView { newImage in
                Task {
                    editing = nil
                    await viewModel.load()
                }
            }
        }
        .sheet(item: $editing) { image in
            ImageMetaEditor(image: image) { updated in
                Task {
                    if let id = updated.id {
                        _ = try? await service.mediaService.updateImageRecord(id: id, name: updated.name ?? "", description: updated.description)
                        await viewModel.load()
                    }
                    editing = nil
                }
            }
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

    var onComplete: (WotlweduImage) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Description", text: $description)
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
            let imageRecord = try await service.mediaService.createImageRecord(name: name, description: description)
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
    var onSave: (WotlweduImage) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: Binding($image.name, replacingNilWith: ""))
                TextField("Description", text: Binding($image.description, replacingNilWith: ""))
            }
            .navigationTitle("Edit Image")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(image)
                        dismiss()
                    }
                }
            }
        }
    }
}
