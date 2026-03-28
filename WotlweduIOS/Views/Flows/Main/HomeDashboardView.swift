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

    private let actions: [(title: String, icon: String, route: MainRoute)] = [
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
        }
        .refreshable {
            await loadSummary()
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
