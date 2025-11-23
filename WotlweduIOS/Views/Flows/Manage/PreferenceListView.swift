import SwiftUI

struct PreferenceListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            PreferenceListContent(service: service)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct PreferenceListContent: View {
    let service: WotlweduDomainService
    @StateObject private var viewModel: PagedListViewModel<WotlweduPreference>
    @State private var editing: WotlweduPreference?

    init(service: WotlweduDomainService) {
        self.service = service
        _viewModel = StateObject(wrappedValue: PagedListViewModel<WotlweduPreference> { page, items, filter in
            let response = try await service.preferences(page: page, items: items)
            return PagedResult(items: response.collection, page: response.page ?? 1, total: response.total ?? response.collection.count, itemsPerPage: response.itemsPerPage ?? items)
        })
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { pref in
                HStack {
                    VStack(alignment: .leading) {
                        Text(pref.name ?? "Preference").font(.headline)
                        Text(pref.value ?? "").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { editing = pref }
            }
        }
        .navigationTitle("Preferences")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { editing = WotlweduPreference(id: nil, name: "", value: "") } label: { Image(systemName: "plus") }
            }
        }
        .task { await viewModel.load() }
        .sheet(item: $editing) { preference in
            PreferenceEditor(preference: preference) { updated in
                Task {
                    _ = try? await service.save(preference: updated)
                    editing = nil
                    await viewModel.load()
                }
            }
        }
    }
}

private struct PreferenceEditor: View {
    @State var preference: WotlweduPreference
    var onSave: (WotlweduPreference) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: Binding($preference.name, replacingNilWith: ""))
                TextField("Value", text: Binding($preference.value, replacingNilWith: ""))
            }
            .navigationTitle("Preference")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(preference)
                        dismiss()
                    }
                }
            }
        }
    }
}
