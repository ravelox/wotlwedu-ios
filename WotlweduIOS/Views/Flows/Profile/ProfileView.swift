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

    var body: some View {
        List {
            if let user {
                Section("Account") {
                    Text(user.displayName).font(.headline)
                    Text(user.email ?? "").foregroundStyle(.secondary)
                    if user.admin == true { Text("Administrator").font(.caption).foregroundStyle(.secondary) }
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
        .task { await loadUser() }
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
