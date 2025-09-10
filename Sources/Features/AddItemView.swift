import SwiftUI
import PhotosUI

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: SessionStore
    let electionId: Int
    @State private var name = ""
    @State private var description = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var error: String?
    @State private var isBusy = false

    var body: some View {
        Form {
            Section("Item") {
                TextField("Name", text: $name)
                TextField("Description (optional)", text: $description, axis: .vertical)
            }
            Section("Image (optional)") {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack { Image(systemName: "photo"); Text(imageData == nil ? "Choose Image" : "Change Image") }
                }
                .onChange(of: selectedItem) { _ in Task { await loadImage() } }
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage).resizable().scaledToFit().frame(height: 160).clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            if let error { Text(error).foregroundStyle(.red) }
            Button {
                Task { await save() }
            } label: {
                HStack { if isBusy { ProgressView() } ; Text("Add Item") }.frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isBusy || name.isEmpty)
        }
        .navigationTitle("Add Item")
    }

    private func loadImage() async {
        guard let selectedItem else { imageData = nil; return }
        do { imageData = try await selectedItem.loadTransferable(type: Data.self) } catch { imageData = nil }
    }

    private func save() async {
        error = nil
        isBusy = true
        defer { isBusy = false }
        do {
            let newItem = try await GeneratedBackend.createItem(
                electionId: electionId,
                name: name,
                description: description.isEmpty ? nil : description
            )
            if let imageData {
                try await GeneratedBackend.uploadItemImage(
                    electionId: electionId,
                    itemId: newItem.id,
                    data: imageData,
                    filename: "photo.jpg",
                    mime: "image/jpeg"
                )
            }
            dismiss()
        } catch {
            self.error = (error as? APIError)?.userMessage ?? error.localizedDescription
        }
    }
}