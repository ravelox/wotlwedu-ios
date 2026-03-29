import SwiftUI

struct HomeDashboardView: View {
    private enum HomePanel: String, CaseIterable, Identifiable {
        case votes
        case polls

        var id: String { rawValue }
        var title: String {
            switch self {
            case .votes: return "Pending Votes"
            case .polls: return "My Polls"
            }
        }
    }

    let onSelect: (MainRoute) -> Void
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var pendingVotes: [WotlweduVote] = []
    @State private var myPolls: [WotlweduElection] = []
    @State private var participationByElectionId: [String: WotlweduElectionParticipationEnvelope] = [:]
    @State private var selectedPanel: HomePanel = .votes
    @State private var isLoadingSummary = false

    private let adminActions: [(title: String, icon: String, route: MainRoute)] = [
        ("Organizations", "building.2", .organizations),
        ("Users", "person.crop.rectangle", .users),
        ("Roles", "lock.shield", .roles)
    ]

    private var actions: [(title: String, icon: String, route: MainRoute)] {
        var base: [(title: String, icon: String, route: MainRoute)] = [
            ("Cast vote", "checkmark.circle", .votes(electionId: nil)),
            ("Friends", "person.2", .friends),
            ("Preferences", "slider.horizontal.3", .preferences),
            ("Audience Groups", "person.3.sequence", .groups),
            ("Categories", "tag", .categories),
            ("Items", "list.bullet", .items),
            ("Images", "photo.on.rectangle", .images),
            ("Lists", "square.stack.3d.up", .lists),
            ("Polls", "flag.2.crossed", .elections),
            ("Notifications", "bell", .notifications)
        ]

        if appViewModel.isSystemAdmin || appViewModel.isOrganizationAdmin || appViewModel.isWorkgroupAdmin {
            base.insert(("Workgroups", "person.3", .workgroups), at: 4)
        }

        return base
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text("Home")
                            .font(.title.bold())
                        Spacer()
                        Button("Create Poll") {
                            onSelect(.elections)
                        }
                        .buttonStyle(.borderedProminent)
                    }
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

                tutorialSection

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

                summarySection

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
            }
            .padding()
        }
        .navigationTitle("Home")
        .task {
            await loadSummary()
            await appViewModel.refreshPollTutorial()
        }
        .refreshable {
            await loadSummary()
            await appViewModel.refreshPollTutorial()
        }
    }

    @ViewBuilder
    private var tutorialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tutorial").font(.headline)
            if let tutorial = appViewModel.pollTutorial {
                let nextStep = tutorial.steps?.first(where: { $0.key == tutorial.nextStepKey }) ??
                    tutorial.steps?.first(where: { $0.complete != true })
                let isSkipped = tutorial.status == "skipped"

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Create your first poll")
                            .font(.headline)
                        Spacer()
                        Text("\(tutorial.progress?.completedSteps ?? 0)/\(tutorial.progress?.totalSteps ?? 0)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if isSkipped {
                        Text("Tutorial skipped")
                            .font(.subheadline.weight(.semibold))
                        Text("Resume the saved walkthrough or restart it with a fresh tutorial poll.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button("Resume Tutorial") {
                                Task { await appViewModel.enablePollTutorial() }
                            }
                            .buttonStyle(.borderedProminent)
                            Button("Restart Tutorial") {
                                Task { await appViewModel.enablePollTutorial(restart: true) }
                            }
                            .buttonStyle(.bordered)
                        }
                    } else if let nextStep {
                        Text("Next: \(nextStep.title ?? "Continue")")
                            .font(.subheadline.weight(.semibold))
                        if let detail = nextStep.detail, !detail.isEmpty {
                            Text(detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        if let suggestedName = nextStep.suggestedName, !suggestedName.isEmpty {
                            Text("Suggested name: \(suggestedName)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            if let route = route(for: nextStep, tutorial: tutorial) {
                                Button("Open Step") { onSelect(route) }
                                    .buttonStyle(.borderedProminent)
                            }
                            Button("Skip Tutorial") {
                                Task { await appViewModel.skipPollTutorial() }
                            }
                            .buttonStyle(.bordered)
                            if tutorial.status == "completed", let electionId = tutorial.bindings?.electionId {
                                Button("View Votes") { onSelect(.votes(electionId: electionId)) }
                                    .buttonStyle(.bordered)
                            }
                        }
                    } else {
                        Text("Tutorial completed.")
                            .font(.subheadline.weight(.semibold))
                        HStack {
                            if let electionId = tutorial.bindings?.electionId {
                                Button("View Votes") { onSelect(.votes(electionId: electionId)) }
                                    .buttonStyle(.borderedProminent)
                            }
                            Button("Restart Tutorial") {
                                Task { await appViewModel.enablePollTutorial(restart: true) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Walk through creating a real options list, audience group, poll, and live stats.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Start Tutorial") {
                        Task { await appViewModel.startPollTutorial() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
            }
        }
    }

    @ViewBuilder
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Participate").font(.headline)
                Spacer()
                Picker("Focus", selection: $selectedPanel) {
                    ForEach(HomePanel.allCases) { panel in
                        Text(panel.title).tag(panel)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)
            }

            if isLoadingSummary {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if selectedPanel == .votes {
                if pendingVotes.isEmpty {
                    summaryEmptyState("No pending votes right now.")
                } else {
                    ForEach(pendingVotes.prefix(4)) { vote in
                        Button {
                            onSelect(.votes(electionId: vote.election?.id))
                        } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vote.election?.name ?? "Poll")
                                        .font(.headline)
                                    if let itemName = vote.item?.name, !itemName.isEmpty {
                                        Text(itemName)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                if myPolls.isEmpty {
                    summaryEmptyState("No polls created yet.")
                } else {
                    ForEach(myPolls.prefix(4)) { poll in
                        Button {
                            onSelect(.elections)
                        } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(poll.name ?? "Poll")
                                        .font(.headline)
                                    if let date = poll.expiration {
                                        Text(date.formatted())
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let summary = poll.id.flatMap({ participationByElectionId[$0] }) {
                                        participationSummaryView(summary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "square.and.pencil")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func summaryEmptyState(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }

    private func loadSummary() async {
        guard let service = appViewModel.domainService else { return }
        isLoadingSummary = true
        defer { isLoadingSummary = false }

        async let votesTask = service.myVotes()
        async let pollsTask = service.elections(page: 1, items: 8, filter: nil, workgroupId: nil)

        if let votes = try? await votesTask {
            pendingVotes = votes
        }
        if let polls = try? await pollsTask {
            myPolls = polls.collection
            var next: [String: WotlweduElectionParticipationEnvelope] = [:]
            for poll in polls.collection {
                guard let id = poll.id else { continue }
                if let summary = try? await service.electionParticipation(id: id) {
                    next[id] = summary
                }
            }
            participationByElectionId = next
        }

        if pendingVotes.isEmpty && !myPolls.isEmpty {
            selectedPanel = .polls
        } else {
            selectedPanel = .votes
        }
    }

    private func route(for step: WotlweduTutorialStep, tutorial: WotlweduPollTutorial) -> MainRoute? {
        switch step.key {
        case "create_options_list", "add_items":
            return .lists
        case "create_audience", "add_yourself_to_audience":
            return .groups
        case "create_poll", "start_poll":
            return .elections
        case "cast_vote":
            return .votes(electionId: tutorial.bindings?.electionId)
        case "view_stats":
            return .elections
        default:
            return nil
        }
    }

    @ViewBuilder
    private func participationSummaryView(_ summary: WotlweduElectionParticipationEnvelope) -> some View {
        let participation = summary.participation
        HStack(spacing: 8) {
            dashboardChip("\(participation?.expectedParticipants ?? 0) people")
            dashboardChip("\(participation?.completedCount ?? 0) done")
            dashboardChip("\(participation?.followUpCount ?? 0) follow-up")
            dashboardChip("\(participation?.completionRate ?? 0)%")
        }
        .padding(.top, 4)
    }

    private func dashboardChip(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 999).fill(Color(.tertiarySystemBackground)))
    }
}
