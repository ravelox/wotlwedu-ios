import SwiftUI

struct ElectionListView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            ElectionListContent(service: service, workgroupId: appViewModel.activeWorkgroupId)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct ElectionListContent: View {
    let service: WotlweduDomainService
    let workgroupId: String?
    @StateObject private var viewModel: PagedListViewModel<WotlweduElection>
    @State private var editing: WotlweduElection?
    @State private var lists: [WotlweduList] = []
    @State private var groups: [WotlweduGroup] = []
    @State private var categories: [WotlweduCategory] = []
    @State private var images: [WotlweduImage] = []
    @State private var collapsedCategories: Set<String> = []
    @State private var participationByElectionId: [String: WotlweduElectionParticipationEnvelope] = [:]

    init(service: WotlweduDomainService, workgroupId: String?) {
        self.service = service
        self.workgroupId = workgroupId
        _viewModel = StateObject(wrappedValue: PagedListViewModel<WotlweduElection> { page, items, filter in
            let response = try await service.elections(page: page, items: items, filter: filter, workgroupId: workgroupId)
            return PagedResult(items: response.collection, page: response.page ?? 1, total: response.total ?? response.collection.count, itemsPerPage: response.itemsPerPage ?? items)
        })
    }

    var body: some View {
        List {
            ForEach(viewModel.items.groupedByCategory()) { group in
                DisclosureGroup(isExpanded: expansionBinding(for: group.categoryName)) {
                    ForEach(group.items) { election in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(election.name ?? "Poll").font(.headline)
                            if let desc = election.description { Text(desc).font(.subheadline) }
                            if let status = election.status?.name {
                                Text(status).font(.caption).foregroundStyle(.secondary)
                            }
                            if let summary = election.id.flatMap({ participationByElectionId[$0] }) {
                                participationSummaryView(summary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { editing = election }
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                Task {
                                    if let id = election.id {
                                        try? await service.deleteElection(id: id)
                                        await viewModel.load()
                                        await loadParticipation()
                                    }
                                }
                            }
                            Button("Start") {
                                Task {
                                    if let id = election.id {
                                        try? await service.startElection(id: id)
                                        await viewModel.load()
                                        await loadParticipation()
                                    }
                                }
                            }.tint(.green)
                            Button("Stop") {
                                Task {
                                    if let id = election.id {
                                        try? await service.stopElection(id: id)
                                        await viewModel.load()
                                        await loadParticipation()
                                    }
                                }
                            }.tint(.orange)
                        }
                    }
                } label: {
                    Text(group.categoryName).font(.subheadline.weight(.semibold))
                }
            }
        }
        .navigationTitle("Polls")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editing = WotlweduElection(
                        id: nil,
                        workgroupId: workgroupId,
                        name: "",
                        description: "",
                        text: "",
                        electionType: 0,
                        expiration: nil,
                        statusId: nil,
                        status: nil,
                        list: nil,
                        group: nil,
                        category: nil,
                        image: nil
                    )
                } label: { Image(systemName: "plus") }
            }
        }
        .task {
            await viewModel.load()
            await loadLookups()
            await loadParticipation()
        }
        .sheet(item: $editing) { election in
            ElectionEditor(election: election, lists: lists, groups: groups, categories: categories, images: images) { updated, startAfterSave in
                Task {
                    do {
                        let saved = try await service.save(election: updated)
                        if startAfterSave, let id = saved.id {
                            try await service.startElection(id: id)
                        }
                        editing = nil
                        await viewModel.load()
                        await loadParticipation()
                    } catch {
                        // Keep the sheet open and rely on the editor state to show the save issue.
                    }
                }
            }
        }
    }

    private func loadLookups() async {
        async let ls = service.lists(page: 1, items: 200, filter: nil, workgroupId: workgroupId)
        async let gs = service.groups(page: 1, items: 200, filter: nil)
        async let cs = service.categories(page: 1, items: 200, filter: nil)
        async let ims = service.images(page: 1, items: 200, filter: nil, workgroupId: workgroupId)
        if let res = try? await ls { lists = res.collection.sortedByName() }
        if let res = try? await gs { groups = res.collection.sortedByName() }
        if let res = try? await cs { categories = res.collection.sortedByName() }
        if let res = try? await ims { images = res.collection.sortedByName() }
    }

    private func loadParticipation() async {
        var next: [String: WotlweduElectionParticipationEnvelope] = [:]
        for election in viewModel.items {
            guard let id = election.id else { continue }
            if let summary = try? await service.electionParticipation(id: id) {
                next[id] = summary
            }
        }
        participationByElectionId = next
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

    @ViewBuilder
    private func participationSummaryView(_ summary: WotlweduElectionParticipationEnvelope) -> some View {
        let participation = summary.participation
        let audience = summary.audience
        VStack(alignment: .leading, spacing: 6) {
            if let groupName = audience?.group?.name, !groupName.isEmpty {
                Text(groupName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                metricBadge(title: "Participants", value: participation?.expectedParticipants ?? 0)
                metricBadge(title: "Done", value: participation?.completedCount ?? 0)
                metricBadge(title: "Follow-up", value: participation?.followUpCount ?? 0)
                metricBadge(title: "Complete", value: participation?.completionRate ?? 0, suffix: "%")
            }
            let followUpNames = (audience?.participants ?? [])
                .filter { $0.state != "completed" }
                .prefix(3)
                .map { $0.fullName ?? $0.email ?? $0.id ?? "Member" }
            if !followUpNames.isEmpty {
                Text("Follow up: \(followUpNames.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
    }

    private func metricBadge(title: String, value: Int, suffix: String = "") -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)\(suffix)")
                .font(.subheadline.weight(.semibold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
    }
}

private struct ElectionEditor: View {
    @State var election: WotlweduElection
    let lists: [WotlweduList]
    let groups: [WotlweduGroup]
    let categories: [WotlweduCategory]
    let images: [WotlweduImage]
    var onSave: (WotlweduElection, Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedList = ""
    @State private var selectedGroup = ""
    @State private var selectedCategory = ""
    @State private var selectedImage = ""
    @State private var expiration = Date()
    @State private var saveError: String?

    init(election: WotlweduElection, lists: [WotlweduList], groups: [WotlweduGroup], categories: [WotlweduCategory], images: [WotlweduImage], onSave: @escaping (WotlweduElection, Bool) -> Void) {
        self.election = election
        self.lists = lists
        self.groups = groups
        self.categories = categories
        self.images = images
        self.onSave = onSave
        _selectedList = State(initialValue: election.list?.id ?? "")
        _selectedGroup = State(initialValue: election.group?.id ?? "")
        _selectedCategory = State(initialValue: election.category?.id ?? "")
        _selectedImage = State(initialValue: election.image?.id ?? "")
        _expiration = State(initialValue: election.expiration ?? Date().addingTimeInterval(86400))
    }

    var body: some View {
        NavigationStack {
            Form {
                if let saveError {
                    Section {
                        Text(saveError)
                            .foregroundStyle(.red)
                    }
                }
                TextField("Name", text: Binding($election.name, replacingNilWith: ""))
                TextField("Description", text: Binding($election.description, replacingNilWith: ""))
                TextField("Text", text: Binding($election.text, replacingNilWith: ""))

                Section("Selections") {
                    summaryRow(title: "List", value: lists.first(where: { $0.id == selectedList })?.name ?? "Choose a list")
                    summaryRow(title: "Audience", value: groups.first(where: { $0.id == selectedGroup })?.name ?? "Choose a group")
                    summaryRow(title: "Image", value: images.first(where: { $0.id == selectedImage })?.name ?? "Optional")
                }

                Picker("Poll Type", selection: Binding(
                    get: { election.electionType ?? 0 },
                    set: { election.electionType = $0 }
                )) {
                    Text("Ranked choice").tag(0)
                    Text("Single choice").tag(1)
                    Text("Approval").tag(2)
                }

                DatePicker("Expiration", selection: $expiration, displayedComponents: .date)

                Picker("List", selection: $selectedList) {
                    Text("None").tag("")
                    ForEach(lists) { list in
                        Text(list.name ?? "List").tag(list.id ?? "")
                    }
                }

                Picker("Group", selection: $selectedGroup) {
                    Text("None").tag("")
                    ForEach(groups) { group in
                        Text(group.name ?? "Group").tag(group.id ?? "")
                    }
                }

                Picker("Category", selection: $selectedCategory) {
                    Text("None").tag("")
                    ForEach(categories) { category in
                        Text(category.name ?? "Category").tag(category.id ?? "")
                    }
                }

                Picker("Image", selection: $selectedImage) {
                    Text("None").tag("")
                    ForEach(images) { image in
                        Text(image.name ?? "Image").tag(image.id ?? "")
                    }
                }
            }
            .navigationTitle(election.id == nil ? "New Poll" : "Edit Poll")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        submit(startAfterSave: false)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save & Start") {
                        submit(startAfterSave: true)
                    }
                    .disabled(selectedList.isEmpty || selectedGroup.isEmpty)
                }
            }
        }
    }

    private func submit(startAfterSave: Bool) {
        guard !startAfterSave || (!selectedList.isEmpty && !selectedGroup.isEmpty) else {
            saveError = "Choose both a list and an audience group before starting the poll."
            return
        }
        saveError = nil
        election.list = lists.first { $0.id == selectedList }
        election.group = groups.first { $0.id == selectedGroup }
        election.category = categories.first { $0.id == selectedCategory }
        election.image = images.first { $0.id == selectedImage }
        election.expiration = expiration
        onSave(election, startAfterSave)
        dismiss()
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}
