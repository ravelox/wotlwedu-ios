import SwiftUI

struct HomeDashboardView: View {
    let onSelect: (MainRoute) -> Void
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var aiPrompt = "Suggest food options for lunch"
    @State private var aiTextToCategorize = "Let's grab pizza and sushi"
    @State private var aiTextToModerate = "Plan a safe and friendly meetup"
    @State private var aiAssistantQuery = "Suggest quick ideas for tonight"
    @State private var aiImageId = ""
    @State private var aiDigest: AINotificationDigest?
    @State private var aiDefaults: AISmartDefaults?
    @State private var aiSuggestions: AIListSuggestions?
    @State private var aiCategory: AICategoryResult?
    @State private var aiModeration: AIModerationResult?
    @State private var aiAssistantResult: AIAssistantResponse?
    @State private var aiSummary: AIElectionSummary?
    @State private var aiRecommendations: AIElectionRecommendations?
    @State private var aiParticipantSuggestions: AIParticipantSuggestions?
    @State private var aiImageDescription: AIImageDescription?
    @State private var aiElections: [WotlweduElection] = []
    @State private var selectedElectionId: String?
    @State private var aiError: String?

    private let actions: [(title: String, icon: String, route: MainRoute)] = [
        ("Cast vote", "checkmark.circle", .votes),
        ("Friends", "person.2", .friends),
        ("Preferences", "slider.horizontal.3", .preferences),
        ("Audience Groups", "person.3.sequence", .groups),
        ("Categories", "tag", .categories),
        ("Items", "list.bullet", .items),
        ("Images", "photo.on.rectangle", .images),
        ("Lists", "square.stack.3d.up", .lists),
        ("Elections", "flag.2.crossed", .elections),
        ("Notifications", "bell", .notifications)
    ]

    private let adminActions: [(title: String, icon: String, route: MainRoute)] = [
        ("Workgroups", "person.3", .workgroups),
        ("Organizations", "building.2", .organizations),
        ("Users", "person.crop.rectangle", .users),
        ("Roles", "lock.shield", .roles)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to wotlwedu")
                        .font(.title.bold())
                    Text("Create lists, share with friends, and vote together.")
                        .foregroundStyle(.secondary)
                    if let message = appViewModel.serverStatus?.message {
                        Label(message, systemImage: "info.circle")
                            .font(.footnote)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                    }
                }

                if appViewModel.unreadNotifications > 0 {
                    HStack {
                        Label("\(appViewModel.unreadNotifications) unread notifications", systemImage: "bell.badge")
                        Spacer()
                        Button("View") { onSelect(.notifications) }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(.yellow.opacity(0.2)))
                }

                Text("Quick actions").font(.headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(actions, id: \.route) { action in
                        Button {
                            onSelect(action.route)
                        } label: {
                            HStack {
                                Image(systemName: action.icon)
                                Text(action.title)
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if appViewModel.isSystemAdmin || appViewModel.isOrganizationAdmin || appViewModel.isWorkgroupAdmin {
                    Text("Admin").font(.headline)
                    ForEach(adminActions, id: \.route) { action in
                        Button {
                            onSelect(action.route)
                        } label: {
                            HStack {
                                Image(systemName: action.icon)
                                Text(action.title)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()
                Text("AI-assisted features").font(.headline)
                Text("Uses authenticated /ai endpoints with deterministic server heuristics.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let aiError {
                    Text(aiError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                HStack {
                    Button("Refresh digest") {
                        Task { await loadAIDigest() }
                    }
                    Button("Refresh defaults") {
                        Task { await loadAIDefaults() }
                    }
                }
                if let aiDigest {
                    Text(aiDigest.summary ?? "No digest summary")
                        .font(.subheadline)
                }
                if let aiDefaults = aiDefaults?.defaults {
                    ForEach(aiDefaults.keys.sorted(), id: \.self) { key in
                        Text("\(key): \(aiDefaults[key]?.displayValue ?? "-")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("List suggestions").font(.subheadline.bold())
                    TextField("Prompt", text: $aiPrompt)
                        .textFieldStyle(.roundedBorder)
                    Button("Suggest items") {
                        Task { await runAISuggestions() }
                    }
                    if let aiSuggestions {
                        Text("Category: \(aiSuggestions.category ?? "Unknown")")
                            .font(.caption)
                        ForEach(aiSuggestions.suggestions ?? []) { suggestion in
                            Text("• \(suggestion.name ?? "Suggestion")")
                                .font(.caption)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Categorize and moderate text").font(.subheadline.bold())
                    TextField("Text to categorize", text: $aiTextToCategorize)
                        .textFieldStyle(.roundedBorder)
                    Button("Categorize") {
                        Task { await runAICategorization() }
                    }
                    if let aiCategory {
                        Text("Category: \(aiCategory.category ?? "Unknown")")
                            .font(.caption)
                    }
                    TextField("Text to moderate", text: $aiTextToModerate)
                        .textFieldStyle(.roundedBorder)
                    Button("Moderate") {
                        Task { await runAIModeration() }
                    }
                    if let aiModeration {
                        Text("Safe: \((aiModeration.safe ?? false) ? "Yes" : "No"), severity: \(aiModeration.severity ?? "n/a")")
                            .font(.caption)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Assistant query").font(.subheadline.bold())
                    TextField("Query", text: $aiAssistantQuery)
                        .textFieldStyle(.roundedBorder)
                    Button("Ask assistant") {
                        Task { await runAIAssistantQuery() }
                    }
                    if let aiAssistantResult {
                        Text(aiAssistantResult.answer ?? "No answer")
                            .font(.caption)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Election AI").font(.subheadline.bold())
                    if aiElections.isEmpty {
                        Text("No elections available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Election", selection: Binding(
                            get: { selectedElectionId ?? "" },
                            set: { selectedElectionId = $0 }
                        )) {
                            ForEach(aiElections.indices, id: \.self) { index in
                                let election = aiElections[index]
                                Text(election.name ?? "Election").tag(election.id ?? "")
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    HStack {
                        Button("Summary") {
                            Task { await loadAIElectionSummary() }
                        }
                        .disabled(selectedElectionId == nil || selectedElectionId == "")
                        Button("Recommendations") {
                            Task { await loadAIElectionRecommendations() }
                        }
                        .disabled(selectedElectionId == nil || selectedElectionId == "")
                        Button("Participants") {
                            Task { await loadAIParticipantSuggestions() }
                        }
                        .disabled(selectedElectionId == nil || selectedElectionId == "")
                    }
                    if let aiSummary {
                        Text(aiSummary.summary ?? "No summary")
                            .font(.caption)
                    }
                    if let recommendations = aiRecommendations?.recommendations, !recommendations.isEmpty {
                        ForEach(recommendations.prefix(3)) { recommendation in
                            Text("• \(recommendation.name ?? "Item")")
                                .font(.caption)
                        }
                    }
                    if let participants = aiParticipantSuggestions?.suggestions, !participants.isEmpty {
                        ForEach(participants.prefix(3)) { participant in
                            Text("• \(participant.alias ?? "Participant")")
                                .font(.caption)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Image description").font(.subheadline.bold())
                    TextField("Image ID", text: $aiImageId)
                        .textFieldStyle(.roundedBorder)
                    Button("Describe image metadata") {
                        Task { await loadAIImageDescription() }
                    }
                    .disabled(aiImageId.isEmpty)
                    if let aiImageDescription {
                        Text(aiImageDescription.description ?? "No image description")
                            .font(.caption)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Home")
        .task {
            await loadAIDigest()
            await loadAIDefaults()
            await loadElectionList()
        }
    }

    private func loadAIDigest() async {
        guard let service = appViewModel.domainService else { return }
        do {
            aiDigest = try await service.notificationDigest()
            aiError = nil
        } catch {
            aiError = error.localizedDescription
        }
    }

    private func loadAIDefaults() async {
        guard let service = appViewModel.domainService else { return }
        do {
            aiDefaults = try await service.smartDefaults()
            aiError = nil
        } catch {
            aiError = error.localizedDescription
        }
    }

    private func runAISuggestions() async {
        guard let service = appViewModel.domainService else { return }
        do {
            aiSuggestions = try await service.suggestListItems(prompt: aiPrompt, count: 5)
            aiError = nil
        } catch {
            aiError = error.localizedDescription
        }
    }

    private func runAICategorization() async {
        guard let service = appViewModel.domainService else { return }
        do {
            aiCategory = try await service.categorizeText(aiTextToCategorize)
            aiError = nil
        } catch {
            aiError = error.localizedDescription
        }
    }

    private func runAIModeration() async {
        guard let service = appViewModel.domainService else { return }
        do {
            aiModeration = try await service.moderateText(aiTextToModerate)
            aiError = nil
        } catch {
            aiError = error.localizedDescription
        }
    }

    private func runAIAssistantQuery() async {
        guard let service = appViewModel.domainService else { return }
        do {
            aiAssistantResult = try await service.assistantQuery(aiAssistantQuery)
            aiError = nil
        } catch {
            aiError = error.localizedDescription
        }
    }

    private func loadElectionList() async {
        guard let service = appViewModel.domainService else { return }
        do {
            let response = try await service.elections(
                page: 1,
                items: 50,
                filter: nil,
                workgroupId: appViewModel.activeWorkgroupId
            )
            aiElections = response.collection
            if selectedElectionId == nil {
                selectedElectionId = aiElections.first?.id
            }
            aiError = nil
        } catch {
            aiError = error.localizedDescription
        }
    }

    private func loadAIElectionSummary() async {
        guard let service = appViewModel.domainService, let electionId = selectedElectionId, !electionId.isEmpty else { return }
        do {
            aiSummary = try await service.electionSummary(electionId: electionId)
            aiError = nil
        } catch {
            aiError = error.localizedDescription
        }
    }

    private func loadAIElectionRecommendations() async {
        guard let service = appViewModel.domainService, let electionId = selectedElectionId, !electionId.isEmpty else { return }
        do {
            aiRecommendations = try await service.electionRecommendations(electionId: electionId)
            aiError = nil
        } catch {
            aiError = error.localizedDescription
        }
    }

    private func loadAIParticipantSuggestions() async {
        guard let service = appViewModel.domainService, let electionId = selectedElectionId, !electionId.isEmpty else { return }
        do {
            aiParticipantSuggestions = try await service.suggestParticipants(electionId: electionId, limit: 5)
            aiError = nil
        } catch {
            aiError = error.localizedDescription
        }
    }

    private func loadAIImageDescription() async {
        guard let service = appViewModel.domainService, !aiImageId.isEmpty else { return }
        do {
            aiImageDescription = try await service.describeImage(imageId: aiImageId)
            aiError = nil
        } catch {
            aiError = error.localizedDescription
        }
    }
}
