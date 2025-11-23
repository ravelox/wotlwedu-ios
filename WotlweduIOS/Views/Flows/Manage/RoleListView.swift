import SwiftUI

struct RoleListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            RoleListContent(service: service)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct RoleListContent: View {
    let service: WotlweduDomainService
    @StateObject private var viewModel: PagedListViewModel<WotlweduRole>
    @State private var editing: WotlweduRole?
    @State private var capabilities: [WotlweduCap] = []
    @State private var users: [WotlweduUser] = []

    init(service: WotlweduDomainService) {
        self.service = service
        _viewModel = StateObject(wrappedValue: PagedListViewModel<WotlweduRole> { page, items, filter in
            let response = try await service.roles(page: page, items: items, filter: filter)
            return PagedResult(items: response.collection, page: response.page ?? 1, total: response.total ?? response.collection.count, itemsPerPage: response.itemsPerPage ?? items)
        })
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { role in
                VStack(alignment: .leading) {
                    Text(role.name ?? "Role").font(.headline)
                    if let desc = role.description { Text(desc).font(.subheadline) }
                    if let caps = role.capabilities {
                        Text("\(caps.count) caps").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { editing = role }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task {
                            if let id = role.id { try? await service.deleteRole(id: id); await viewModel.load() }
                        }
                    }
                }
            }
        }
        .navigationTitle("Roles")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { editing = WotlweduRole(id: nil, name: "", description: "", protected: false, capabilities: [], users: []) } label: { Image(systemName: "plus") }
            }
        }
        .task {
            await viewModel.load()
            await loadLookups()
        }
        .sheet(item: $editing) { role in
            RoleEditor(role: role, capabilities: capabilities, users: users) { updated in
                Task {
                    _ = try? await service.save(role: updated)
                    editing = nil
                    await viewModel.load()
                }
            }
        }
    }

    private func loadLookups() async {
        if let caps = try? await service.capabilities(page: 1, items: 200) {
            capabilities = caps.collection.sortedByName()
        }
        if let userPage = try? await service.users(page: 1, items: 200, filter: nil) {
            users = userPage.collection.sortedByName()
        }
    }
}

private struct RoleEditor: View {
    @State var role: WotlweduRole
    let capabilities: [WotlweduCap]
    let users: [WotlweduUser]
    var onSave: (WotlweduRole) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCaps: Set<String> = []
    @State private var selectedUsers: Set<String> = []

    init(role: WotlweduRole, capabilities: [WotlweduCap], users: [WotlweduUser], onSave: @escaping (WotlweduRole) -> Void) {
        self.role = role
        self.capabilities = capabilities
        self.users = users
        self.onSave = onSave
        _selectedCaps = State(initialValue: Set(role.capabilities?.compactMap { $0.id } ?? []))
        _selectedUsers = State(initialValue: Set(role.users?.compactMap { $0.id } ?? []))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: Binding($role.name, replacingNilWith: ""))
                TextField("Description", text: Binding($role.description, replacingNilWith: ""))
                Toggle("Protected", isOn: Binding(
                    get: { role.protected ?? false },
                    set: { role.protected = $0 }
                ))

                MultiSelectList(title: "Capabilities", items: capabilities, selection: $selectedCaps)
                MultiSelectList(title: "Users", items: users, selection: $selectedUsers)
            }
            .navigationTitle(role.id == nil ? "New Role" : "Edit Role")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        role.capabilities = capabilities.filter { selectedCaps.contains($0.id ?? "") }
                        role.users = users.filter { selectedUsers.contains($0.id ?? "") }
                        onSave(role)
                        dismiss()
                    }
                }
            }
        }
    }
}
