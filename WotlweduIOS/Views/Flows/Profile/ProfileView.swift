import SwiftUI

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
    let service: WotlweduDomainService
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var user: WotlweduUser?
    @State private var show2FA = false
    @State private var twoFAData: TwoFactorBootstrap?
    @State private var workgroups: [WotlweduWorkgroup] = []
    @State private var selectedWorkgroupId: String = ""

    var body: some View {
        List {
            if let user {
                Section("Account") {
                    Text(user.displayName).font(.headline)
                    Text(user.email ?? "").foregroundStyle(.secondary)
                    if user.admin == true { Text("Administrator").font(.caption).foregroundStyle(.secondary) }
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
            await loadWorkgroups()
        }
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

    private func loadWorkgroups() async {
        if let result = try? await service.workgroups(page: 1, items: 200, filter: nil) {
            workgroups = result.collection
        }
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
