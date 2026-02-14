import SwiftUI

struct OrganizationListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            OrganizationListContent(service: service, canCreate: appViewModel.isSystemAdmin)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct OrganizationListContent: View {
    let service: WotlweduDomainService
    let canCreate: Bool
    @StateObject private var viewModel: PagedListViewModel<WotlweduOrganization>
    @State private var editing: WotlweduOrganization?

    init(service: WotlweduDomainService, canCreate: Bool) {
        self.service = service
        self.canCreate = canCreate
        _viewModel = StateObject(wrappedValue: PagedListViewModel<WotlweduOrganization> { page, items, filter in
            let response = try await service.organizations(page: page, items: items, filter: filter)
            return PagedResult(items: response.collection, page: response.page ?? 1, total: response.total ?? response.collection.count, itemsPerPage: response.itemsPerPage ?? items)
        })
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { org in
                VStack(alignment: .leading, spacing: 4) {
                    Text(org.name ?? "Unnamed").font(.headline)
                    if let desc = org.description, !desc.isEmpty {
                        Text(desc).font(.subheadline).foregroundStyle(.secondary)
                    }
                    if let active = org.active {
                        Text(active ? "Active" : "Inactive").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { editing = org }
                .swipeActions {
                    if canCreate {
                        Button("Delete", role: .destructive) {
                            Task {
                                if let id = org.id {
                                    try? await service.deleteOrganization(id: id)
                                    await viewModel.load()
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Organizations")
        .toolbar {
            if canCreate {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editing = WotlweduOrganization(id: nil, name: "", description: "", active: true, creator: nil)
                    } label: { Image(systemName: "plus") }
                }
            }
        }
        .task { await viewModel.load() }
        .sheet(item: $editing) { org in
            OrganizationEditor(organization: org, canEditActive: canCreate) { updated in
                Task {
                    _ = try? await service.save(organization: updated)
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
}

private struct OrganizationEditor: View {
    @State var organization: WotlweduOrganization
    let canEditActive: Bool
    var onSave: (WotlweduOrganization) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: Binding($organization.name, replacingNilWith: ""))
                TextField("Description", text: Binding($organization.description, replacingNilWith: ""))
                Toggle("Active", isOn: Binding(
                    get: { organization.active ?? true },
                    set: { organization.active = $0 }
                ))
                .disabled(!canEditActive)
            }
            .navigationTitle(organization.id == nil ? "New Organization" : "Edit Organization")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(organization)
                        dismiss()
                    }
                }
            }
        }
    }
}

