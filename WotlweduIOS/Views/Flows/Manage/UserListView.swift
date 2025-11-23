import SwiftUI

struct UserListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            UserListContent(service: service)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct UserListContent: View {
    let service: WotlweduDomainService
    @StateObject private var viewModel: PagedListViewModel<WotlweduUser>
    @State private var editing: WotlweduUser?
    @State private var images: [WotlweduImage] = []

    init(service: WotlweduDomainService) {
        self.service = service
        _viewModel = StateObject(wrappedValue: PagedListViewModel<WotlweduUser> { page, items, filter in
            let response = try await service.users(page: page, items: items, filter: filter)
            return PagedResult(items: response.collection, page: response.page ?? 1, total: response.total ?? response.collection.count, itemsPerPage: response.itemsPerPage ?? items)
        })
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { user in
                VStack(alignment: .leading) {
                    Text(user.displayName).font(.headline)
                    Text(user.email ?? "").font(.subheadline).foregroundStyle(.secondary)
                    if user.admin == true {
                        Text("Admin").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { editing = user }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task {
                            if let id = user.id { try? await service.deleteUser(id: id); await viewModel.load() }
                        }
                    }
                }
            }
        }
        .navigationTitle("Users")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { editing = WotlweduUser(id: nil, firstName: "", lastName: "", alias: "", email: "", image: nil, active: true, verified: false, enable2fa: false, admin: false) } label: { Image(systemName: "plus") }
            }
        }
        .task {
            await viewModel.load()
            await loadImages()
        }
        .sheet(item: $editing) { user in
            UserEditor(user: user, images: images) { updated in
                Task {
                    _ = try? await service.save(user: updated)
                    editing = nil
                    await viewModel.load()
                }
            }
        }
    }

    private func loadImages() async {
        if let res = try? await service.images(page: 1, items: 200, filter: nil) {
            images = res.collection.sortedByName()
        }
    }
}

private struct UserEditor: View {
    @State var user: WotlweduUser
    let images: [WotlweduImage]
    var onSave: (WotlweduUser) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage = ""

    init(user: WotlweduUser, images: [WotlweduImage], onSave: @escaping (WotlweduUser) -> Void) {
        self.user = user
        self.images = images
        self.onSave = onSave
        _selectedImage = State(initialValue: user.image?.id ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("First name", text: Binding($user.firstName, replacingNilWith: ""))
                TextField("Last name", text: Binding($user.lastName, replacingNilWith: ""))
                TextField("Alias", text: Binding($user.alias, replacingNilWith: ""))
                TextField("Email", text: Binding($user.email, replacingNilWith: ""))
                Toggle("Active", isOn: Binding(
                    get: { user.active ?? true },
                    set: { user.active = $0 }
                ))
                Toggle("Verified", isOn: Binding(
                    get: { user.verified ?? false },
                    set: { user.verified = $0 }
                ))
                Toggle("2FA Enabled", isOn: Binding(
                    get: { user.enable2fa ?? false },
                    set: { user.enable2fa = $0 }
                ))
                Toggle("Admin", isOn: Binding(
                    get: { user.admin ?? false },
                    set: { user.admin = $0 }
                ))

                Picker("Image", selection: $selectedImage) {
                    Text("None").tag("")
                    ForEach(images) { image in
                        Text(image.name ?? "Image").tag(image.id ?? "")
                    }
                }
            }
            .navigationTitle(user.id == nil ? "New User" : "Edit User")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        user.image = images.first { $0.id == selectedImage }
                        onSave(user)
                        dismiss()
                    }
                }
            }
        }
    }
}
