import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        if let service = appViewModel.domainService {
            ProfileContent(service: service)
        } else {
            Text("Configuration not loaded.")
        }
    }
}

private struct ProfileContent: View {
    private enum InviteFilter: String, CaseIterable, Identifiable {
        case all
        case pending
        case accepted
        case revoked
        case expired

        var id: String { rawValue }

        var label: String { rawValue.capitalized }
    }

    let service: WotlweduDomainService
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var user: WotlweduUser?
    @State private var organization: WotlweduOrganization?
    @State private var show2FA = false
    @State private var twoFAData: TwoFactorBootstrap?
    @State private var workgroups: [WotlweduWorkgroup] = []
    @State private var selectedWorkgroupId: String = ""
    @State private var inviteEmail = ""
    @State private var inviteFilter: InviteFilter = .all
    @State private var invites: [WotlweduOrganizationInvite] = []
    @State private var signInMethods = WotlweduSignInMethodsEnvelope(passwordEnabled: false, linkedProviders: [])
    @State private var userAudits: [WotlweduAuthAudit] = []
    @State private var organizationAudits: [WotlweduAuthAudit] = []
    @State private var auditOutcomeFilter = "all"

    var body: some View {
        List {
            if let user {
                Section("Account") {
                    Text(user.displayName).font(.headline)
                    Text(user.email ?? "").foregroundStyle(.secondary)
                    if user.admin == true { Text("Administrator").font(.caption).foregroundStyle(.secondary) }
                    if let organizationName = organization?.name {
                        Text(organizationName).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Section("Workgroup Scope") {
                Picker("Active workgroup", selection: $selectedWorkgroupId) {
                    Text("(none)").tag("")
                    ForEach(workgroups.sortedByName()) { wg in
                        Text(wg.name ?? wg.id ?? "Workgroup").tag(wg.id ?? "")
                    }
                }
                .onChange(of: selectedWorkgroupId) { newValue in
                    appViewModel.setActiveWorkgroupId(newValue.isEmpty ? nil : newValue)
                }
            }

            Section {
                Button("Enable 2FA") { Task { await enable2FA() } }
                if let twoFAData {
                    TwoFactorView(data: twoFAData)
                }
            }

            Section("Sign-In Methods") {
                MethodRow(
                    title: "Password",
                    subtitle: "Local password login availability.",
                    badgeText: signInMethods.passwordEnabled == true ? "Enabled" : "Disabled",
                    badgeTone: signInMethods.passwordEnabled == true ? .success : .neutral,
                    actionTitle: nil,
                    actionRole: nil,
                    action: nil
                )
                ForEach(signInMethods.linkedProviders ?? []) { method in
                    MethodRow(
                        title: methodTitle(method),
                        subtitle: methodSubtitle(method),
                        badgeText: "Linked",
                        badgeTone: .neutral,
                        actionTitle: method.id == nil ? nil : "Unlink",
                        actionRole: .destructive,
                        action: method.id == nil ? nil : {
                            Task { await unlinkMethod(identityId: method.id ?? "") }
                        }
                    )
                }
            }

            Section("Recent Account Activity") {
                if userAudits.isEmpty {
                    Text("No account activity recorded.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(userAudits) { audit in
                        AuditRow(audit: audit)
                    }
                }
            }

            if canManageInvites {
                Section("Organization Invitations") {
                    TextField("Invite email", text: $inviteEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    Button("Send Invite") {
                        Task { await createInvite() }
                    }
                    .disabled(inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Picker("Status", selection: $inviteFilter) {
                        ForEach(InviteFilter.allCases) { status in
                            Text(status.label).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: inviteFilter) { _ in
                        Task { await loadInvites() }
                    }

                    ForEach(invites) { invite in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(invite.email ?? "Unknown email")
                                    .font(.headline)
                                Spacer()
                                Text((invite.status ?? "unknown").capitalized)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.12))
                                    .clipShape(Capsule())
                            }

                            if let createdAt = invite.createdAt {
                                Text("Created \(createdAt.formatted())").font(.caption).foregroundStyle(.secondary)
                            }
                            if let expiresAt = invite.expiresAt {
                                Text("Expires \(expiresAt.formatted())").font(.caption).foregroundStyle(.secondary)
                            }
                            if let invitedByName = invite.invitedByName, !invitedByName.isEmpty {
                                Text("Invited by \(invitedByName)").font(.caption).foregroundStyle(.secondary)
                            }
                            if let acceptedAt = invite.acceptedAt {
                                Text("Accepted \(acceptedAt.formatted())\(invite.acceptedByName.map { " by \($0)" } ?? "")").font(.caption).foregroundStyle(.secondary)
                            }
                            if let revokedAt = invite.revokedAt {
                                Text("Revoked \(revokedAt.formatted())\(invite.revokedByName.map { " by \($0)" } ?? "")").font(.caption).foregroundStyle(.secondary)
                            }
                            if let token = invite.token {
                                Text("Token: \(token)")
                                    .font(.caption2)
                                    .textSelection(.enabled)
                            }

                            if invite.status == "pending", let inviteId = invite.id {
                                HStack {
                                    Button("Resend") {
                                        Task { await resendInvite(inviteId: inviteId) }
                                    }
                                    Button("Revoke", role: .destructive) {
                                        Task { await revokeInvite(inviteId: inviteId) }
                                    }
                                    if let token = invite.token {
                                        Button("Copy Token") {
                                            UIPasteboard.general.string = token
                                        }
                                    }
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Organization Audit Feed") {
                    SupportSnapshotRow(audits: organizationAudits)

                    Picker("Outcome", selection: $auditOutcomeFilter) {
                        Text("All").tag("all")
                        Text("Success").tag("success")
                        Text("Pending").tag("pending")
                        Text("Blocked").tag("blocked")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: auditOutcomeFilter) { _ in
                        Task { await loadOrganizationAudits() }
                    }

                    if organizationAudits.isEmpty {
                        Text("No organization activity for this filter.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(organizationAudits) { audit in
                            AuditRow(audit: audit)
                        }
                    }
                }
            }

            Section {
                Button("Log out", role: .destructive) {
                    appViewModel.logout()
                }
            }
        }
        .navigationTitle("Profile")
        .task {
            selectedWorkgroupId = appViewModel.activeWorkgroupId ?? ""
            await loadUser()
            await loadOrganization()
            await loadWorkgroups()
            await loadInvites()
            await loadSignInMethods()
            await loadUserAudits()
            await loadOrganizationAudits()
        }
    }

    private var canManageInvites: Bool {
        appViewModel.organizationId != nil && (appViewModel.isOrganizationAdmin || appViewModel.isSystemAdmin)
    }

    private func loadUser() async {
        guard let id = appViewModel.sessionStore.userId else { return }
        if let detail = try? await service.userDetail(id: id) {
            user = detail
        }
    }

    private func enable2FA() async {
        if let data = await appViewModel.enable2FA() {
            twoFAData = data
        }
    }

    private func loadOrganization() async {
        guard let organizationId = appViewModel.organizationId else { return }
        if let detail = try? await service.organizationDetail(id: organizationId) {
            organization = detail
        }
    }

    private func loadWorkgroups() async {
        if let result = try? await service.workgroups(page: 1, items: 200, filter: nil) {
            workgroups = result.collection
        }
    }

    private func loadInvites() async {
        guard canManageInvites, let organizationId = appViewModel.organizationId else { return }
        do {
            invites = try await service.organizationInvites(organizationId: organizationId, status: inviteFilter.rawValue)
        } catch {
            appViewModel.errorMessage = error.localizedDescription
        }
    }

    private func loadSignInMethods() async {
        guard let userId = appViewModel.sessionStore.userId else { return }
        do {
            signInMethods = try await service.userSignInMethods(userId: userId)
        } catch {
            appViewModel.errorMessage = error.localizedDescription
        }
    }

    private func loadUserAudits() async {
        guard let userId = appViewModel.sessionStore.userId else { return }
        do {
            userAudits = try await service.userAuthAudit(userId: userId)
        } catch {
            appViewModel.errorMessage = error.localizedDescription
        }
    }

    private func loadOrganizationAudits() async {
        guard canManageInvites, let organizationId = appViewModel.organizationId else { return }
        do {
            organizationAudits = try await service.organizationAuthAudit(
                organizationId: organizationId,
                outcome: auditOutcomeFilter
            )
        } catch {
            appViewModel.errorMessage = error.localizedDescription
        }
    }

    private func createInvite() async {
        guard let organizationId = appViewModel.organizationId else { return }
        do {
            try await service.createOrganizationInvite(
                organizationId: organizationId,
                email: inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            inviteEmail = ""
            await loadInvites()
        } catch {
            appViewModel.errorMessage = error.localizedDescription
        }
    }

    private func resendInvite(inviteId: String) async {
        guard let organizationId = appViewModel.organizationId else { return }
        do {
            try await service.resendOrganizationInvite(organizationId: organizationId, inviteId: inviteId)
            await loadInvites()
        } catch {
            appViewModel.errorMessage = error.localizedDescription
        }
    }

    private func revokeInvite(inviteId: String) async {
        guard let organizationId = appViewModel.organizationId else { return }
        do {
            try await service.revokeOrganizationInvite(organizationId: organizationId, inviteId: inviteId)
            await loadInvites()
        } catch {
            appViewModel.errorMessage = error.localizedDescription
        }
    }

    private func unlinkMethod(identityId: String) async {
        guard let userId = appViewModel.sessionStore.userId else { return }
        do {
            try await service.unlinkSignInMethod(userId: userId, identityId: identityId)
            await loadSignInMethods()
            await loadUserAudits()
        } catch {
            appViewModel.errorMessage = error.localizedDescription
        }
    }

    private func methodTitle(_ method: WotlweduSignInMethod) -> String {
        let provider = (method.provider ?? "social").capitalized
        if let email = method.email, !email.isEmpty {
            return "\(provider) • \(email)"
        }
        return provider
    }

    private func methodSubtitle(_ method: WotlweduSignInMethod) -> String {
        if let updatedAt = method.updatedAt {
            return "Updated \(updatedAt.formatted())"
        }
        if let subjectPreview = method.subjectPreview, !subjectPreview.isEmpty {
            return subjectPreview
        }
        return "Linked provider"
    }
}

private enum AuditTone {
    case neutral
    case success
    case pending
    case blocked
}

private struct AuditBadge: View {
    let text: String
    let tone: AuditTone

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch tone {
        case .success:
            return Color.green.opacity(0.18)
        case .pending:
            return Color.orange.opacity(0.22)
        case .blocked:
            return Color.red.opacity(0.18)
        case .neutral:
            return Color.secondary.opacity(0.12)
        }
    }
}

private struct MethodRow: View {
    let title: String
    let subtitle: String
    let badgeText: String
    let badgeTone: AuditTone
    let actionTitle: String?
    let actionRole: ButtonRole?
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                AuditBadge(text: badgeText, tone: badgeTone)
            }

            if let actionTitle, let action {
                Button(actionTitle, role: actionRole, action: action)
                    .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AuditRow: View {
    let audit: WotlweduAuthAudit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(audit.eventType ?? "Activity").font(.headline)
                    if let message = audit.message, !message.isEmpty {
                        Text(message).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                AuditBadge(text: audit.outcome ?? "unknown", tone: tone(for: audit.outcome))
            }

            if !metaParts.isEmpty {
                Text(metaParts.joined(separator: " • "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var metaParts: [String] {
        [
            audit.createdAt?.formatted(),
            audit.provider,
            audit.email,
        ].compactMap { part in
            guard let part, !part.isEmpty else { return nil }
            return part
        }
    }

    private func tone(for outcome: String?) -> AuditTone {
        switch (outcome ?? "").lowercased() {
        case "success":
            return .success
        case "pending":
            return .pending
        case "blocked", "error", "failed":
            return .blocked
        default:
            return .neutral
        }
    }
}

private struct SupportSnapshotRow: View {
    let audits: [WotlweduAuthAudit]

    var body: some View {
        HStack(spacing: 8) {
            metric(title: "Loaded", value: "\(audits.count)")
            metric(title: "Success", value: "\(successCount)")
            metric(title: "Non-success", value: "\(max(0, audits.count - successCount))")
        }
        .padding(.vertical, 4)
    }

    private var successCount: Int {
        audits.filter { ($0.outcome ?? "").lowercased() == "success" }.count
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct TwoFactorView: View {
    let data: TwoFactorBootstrap
    @State private var authToken = ""
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let qr = data.qrCode,
               let encoded = qr.split(separator: ",").last.map(String.init),
               let decoded = Data(base64Encoded: encoded),
               let image = UIImage(data: decoded) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220)
            }
            if let secret = data.secret {
                Text("Secret: \(secret)").font(.caption)
            }
            TextField("Auth token", text: $authToken)
                .textFieldStyle(.roundedBorder)
            Button("Verify") {
                Task {
                    await appViewModel.verify2FA(verificationToken: data.verificationToken ?? "", authToken: authToken)
                }
            }
        }
    }
}
