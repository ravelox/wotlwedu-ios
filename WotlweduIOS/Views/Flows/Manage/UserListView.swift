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
    @State private var organizations: [WotlweduOrganization] = []
    @State private var workgroups: [WotlweduWorkgroup] = []
    @EnvironmentObject private var appViewModel: AppViewModel

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
                Button {
                    editing = WotlweduUser(
                        id: nil,
                        firstName: "",
                        lastName: "",
                        alias: "",
                        email: "",
                        image: nil,
                        active: true,
                        verified: false,
                        enable2fa: false,
                        admin: false,
                        systemAdmin: false,
                        organizationId: appViewModel.organizationId,
                        organizationAdmin: false,
                        workgroupAdmin: false,
                        adminWorkgroupId: nil
                    )
                } label: { Image(systemName: "plus") }
            }
        }
        .task {
            await viewModel.load()
            await loadImages()
            await loadOrgAndWorkgroups()
        }
        .sheet(item: $editing) { user in
            UserEditor(
                user: user,
                images: images,
                organizations: organizations,
                workgroups: workgroups,
                canSetSystemAdmin: appViewModel.isSystemAdmin,
                canSetOrgAdmin: appViewModel.isSystemAdmin || appViewModel.isOrganizationAdmin
            ) { updated in
                Task {
                    _ = try? await service.save(user: updated)
                    editing = nil
                    await viewModel.load()
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func loadImages() async {
        if let res = try? await service.images(page: 1, items: 200, filter: nil) {
            images = res.collection.sortedByName()
        }
    }

    private func loadOrgAndWorkgroups() async {
        if let res = try? await service.organizations(page: 1, items: 200, filter: nil) {
            organizations = res.collection.sortedByName()
        }
        if let res = try? await service.workgroups(page: 1, items: 200, filter: nil) {
            workgroups = res.collection.sortedByName()
        }
    }
}

private struct UserEditor: View {
    @State var user: WotlweduUser
    let images: [WotlweduImage]
    let organizations: [WotlweduOrganization]
    let workgroups: [WotlweduWorkgroup]
    let canSetSystemAdmin: Bool
    let canSetOrgAdmin: Bool
    var onSave: (WotlweduUser) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage = ""
    @State private var selectedOrganizationId = ""
    @State private var selectedAdminWorkgroupId = ""

    init(
        user: WotlweduUser,
        images: [WotlweduImage],
        organizations: [WotlweduOrganization],
        workgroups: [WotlweduWorkgroup],
        canSetSystemAdmin: Bool,
        canSetOrgAdmin: Bool,
        onSave: @escaping (WotlweduUser) -> Void
    ) {
        self.user = user
        self.images = images
        self.organizations = organizations
        self.workgroups = workgroups
        self.canSetSystemAdmin = canSetSystemAdmin
        self.canSetOrgAdmin = canSetOrgAdmin
        self.onSave = onSave
        _selectedImage = State(initialValue: user.image?.id ?? "")
        _selectedOrganizationId = State(initialValue: user.organizationId ?? "")
        _selectedAdminWorkgroupId = State(initialValue: user.adminWorkgroupId ?? "")
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

                Toggle("System admin", isOn: Binding(
                    get: { user.systemAdmin ?? (user.admin ?? false) },
                    set: {
                        user.systemAdmin = $0
                        user.admin = $0
                    }
                ))
                .disabled(!canSetSystemAdmin)

                Picker("Organization", selection: $selectedOrganizationId) {
                    Text("Default").tag("")
                    ForEach(organizations) { org in
                        Text(org.name ?? org.id ?? "Org").tag(org.id ?? "")
                    }
                }
                .disabled(!canSetSystemAdmin)

                Toggle("Organization admin", isOn: Binding(
                    get: { user.organizationAdmin ?? false },
                    set: { user.organizationAdmin = $0 }
                ))
                .disabled(!canSetOrgAdmin)

                Toggle("Workgroup admin", isOn: Binding(
                    get: { user.workgroupAdmin ?? false },
                    set: { user.workgroupAdmin = $0 }
                ))
                .disabled(!canSetOrgAdmin)

                Picker("Admin workgroup", selection: $selectedAdminWorkgroupId) {
                    Text("None").tag("")
                    ForEach(workgroups.filter { wg in
                        // If system admin picked an org, restrict to it. Otherwise keep all.
                        if canSetSystemAdmin, !selectedOrganizationId.isEmpty {
                            return wg.organizationId == selectedOrganizationId
                        }
                        return true
                    }) { wg in
                        Text(wg.name ?? wg.id ?? "Workgroup").tag(wg.id ?? "")
                    }
                }
                .disabled(!canSetOrgAdmin)

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
                        user.organizationId = selectedOrganizationId.isEmpty ? nil : selectedOrganizationId
                        user.adminWorkgroupId = selectedAdminWorkgroupId.isEmpty ? nil : selectedAdminWorkgroupId
                        onSave(user)
                        dismiss()
                    }
                }
            }
        }
    }
}
