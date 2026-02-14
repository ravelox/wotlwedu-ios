import SwiftUI

struct WorkgroupListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            WorkgroupListContent(service: service, isSystemAdmin: appViewModel.isSystemAdmin)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct WorkgroupListContent: View {
    let service: WotlweduDomainService
    let isSystemAdmin: Bool
    @StateObject private var viewModel: PagedListViewModel<WotlweduWorkgroup>
    @State private var editing: WotlweduWorkgroup?
    @State private var categories: [WotlweduCategory] = []
    @State private var users: [WotlweduUser] = []
    @State private var organizations: [WotlweduOrganization] = []

    init(service: WotlweduDomainService, isSystemAdmin: Bool) {
        self.service = service
        self.isSystemAdmin = isSystemAdmin
        _viewModel = StateObject(wrappedValue: PagedListViewModel<WotlweduWorkgroup> { page, items, filter in
            let response = try await service.workgroups(page: page, items: items, filter: filter)
            return PagedResult(items: response.collection, page: response.page ?? 1, total: response.total ?? response.collection.count, itemsPerPage: response.itemsPerPage ?? items)
        })
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { workgroup in
                VStack(alignment: .leading, spacing: 4) {
                    Text(workgroup.name ?? "Untitled").font(.headline)
                    if let orgId = workgroup.organizationId {
                        Text("Org: \(orgId)").font(.caption).foregroundStyle(.secondary)
                    }
                    if let count = workgroup.users?.count {
                        Text("\(count) members").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { editing = workgroup }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task {
                            if let id = workgroup.id {
                                try? await service.deleteWorkgroup(id: id)
                                await viewModel.load()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Workgroups")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editing = WotlweduWorkgroup(id: nil, organizationId: nil, name: "", description: "", users: [], category: nil)
                } label: { Image(systemName: "plus") }
            }
        }
        .task {
            await viewModel.load()
            await loadLookups()
        }
        .sheet(item: $editing) { workgroup in
            let originalIds = Set(workgroup.users?.compactMap { $0.id } ?? [])
            WorkgroupEditor(
                workgroup: workgroup,
                categories: categories,
                users: users,
                organizations: organizations,
                isSystemAdmin: isSystemAdmin
            ) { updated in
                Task {
                    _ = try? await service.save(workgroup: updated, originalMemberIds: originalIds)
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

    private func loadLookups() async {
        async let cats = service.categories(page: 1, items: 200, filter: nil)
        async let usrs = service.users(page: 1, items: 500, filter: nil)
        async let orgs = service.organizations(page: 1, items: 200, filter: nil)
        if let catData = try? await cats {
            categories = catData.collection.sortedByName()
        }
        if let userData = try? await usrs {
            users = userData.collection.sortedByName()
        }
        if let orgData = try? await orgs {
            organizations = orgData.collection.sortedByName()
        }
    }
}

private struct WorkgroupEditor: View {
    @State var workgroup: WotlweduWorkgroup
    let categories: [WotlweduCategory]
    let users: [WotlweduUser]
    let organizations: [WotlweduOrganization]
    let isSystemAdmin: Bool
    var onSave: (WotlweduWorkgroup) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategoryId: String?
    @State private var selectedOrganizationId: String?
    @State private var memberIds: Set<String?> = []

    init(
        workgroup: WotlweduWorkgroup,
        categories: [WotlweduCategory],
        users: [WotlweduUser],
        organizations: [WotlweduOrganization],
        isSystemAdmin: Bool,
        onSave: @escaping (WotlweduWorkgroup) -> Void
    ) {
        self.workgroup = workgroup
        self.categories = categories
        self.users = users
        self.organizations = organizations
        self.isSystemAdmin = isSystemAdmin
        self.onSave = onSave
        _selectedCategoryId = State(initialValue: workgroup.category?.id)
        _selectedOrganizationId = State(initialValue: workgroup.organizationId)
        _memberIds = State(initialValue: Set(workgroup.users?.map { $0.id } ?? []))
    }

    var filteredUsers: [WotlweduUser] {
        guard isSystemAdmin, let orgId = selectedOrganizationId, !orgId.isEmpty else {
            return users
        }
        return users.filter { $0.organizationId == orgId }
    }

    var body: some View {
        NavigationStack {
            Form {
                if isSystemAdmin {
                    Picker("Organization", selection: Binding(
                        get: { selectedOrganizationId ?? "" },
                        set: { selectedOrganizationId = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("Select…").tag("")
                        ForEach(organizations) { org in
                            Text(org.name ?? org.id ?? "Org").tag(org.id ?? "")
                        }
                    }
                }

                TextField("Name", text: Binding($workgroup.name, replacingNilWith: ""))
                TextField("Description", text: Binding($workgroup.description, replacingNilWith: ""))

                Picker("Category", selection: Binding(
                    get: { selectedCategoryId ?? "" },
                    set: { selectedCategoryId = $0.isEmpty ? nil : $0 }
                )) {
                    Text("None").tag("")
                    ForEach(categories) { category in
                        Text(category.name ?? "Unnamed").tag(category.id ?? "")
                    }
                }

                MultiSelectList(title: "Members", items: filteredUsers, selection: $memberIds)
            }
            .navigationTitle(workgroup.id == nil ? "New Workgroup" : "Edit Workgroup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let selectedCategory = categories.first { $0.id == selectedCategoryId }
                        let selectedUsers = filteredUsers.filter { memberIds.contains($0.id) }
                        workgroup.category = selectedCategory
                        workgroup.users = selectedUsers
                        workgroup.organizationId = selectedOrganizationId
                        onSave(workgroup)
                        dismiss()
                    }
                    .disabled(isSystemAdmin && (selectedOrganizationId ?? "").isEmpty)
                }
            }
        }
    }
}

