import SwiftUI
import UIKit
import GoogleSignIn
import GoogleSignInSwift

struct AuthFlowView: View {
    private enum AuthTab: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case settings = "Settings"

        var id: String { rawValue }
    }

    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showingRegister = false
    @State private var showingReset = false
    @State private var selectedTab: AuthTab = .signIn

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 32)

                Text("wotlwedu")
                    .font(.system(size: 26, weight: .bold))
                Text("What'll We Do?")
                    .foregroundStyle(.secondary)

                Picker("Section", selection: $selectedTab) {
                    ForEach(AuthTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                if selectedTab == .signIn {
                    LoginForm(showingReset: $showingReset)

                    Button(showingRegister ? "Back to login" : "Create account") {
                        showingRegister.toggle()
                    }

                    if showingRegister {
                        RegisterForm()
                    }
                } else {
                    LoginSettingsForm()
                }
            }
            .padding()
            .navigationTitle("Welcome")
        }
    }
}

private struct LoginForm: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Binding var showingReset: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var inviteTokenText = ""
    @State private var isGoogleLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sign in").font(.headline)
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))

            TextField("Invite token (optional)", text: $inviteTokenText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))

            if let invite = appViewModel.inviteDetails {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invitation ready")
                        .font(.subheadline.weight(.semibold))
                    Text("Sign in with Google to join \(invite.organizationName ?? "the organization") as \(invite.email ?? "the invited account").")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.08)))
            }

            Button {
                Task {
                    isLoading = true
                    await appViewModel.login(email: email, password: password)
                    isLoading = false
                }
            } label: {
                HStack {
                    if isLoading { ProgressView() }
                    Text("Log in")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            .buttonStyle(.borderedProminent)

            if googleConfigured {
                GoogleSignInButton(action: handleGoogleSignIn)
                    .frame(height: 50)
                    .disabled(isGoogleLoading)
            }

            Button("Forgot password?") { showingReset = true }
                .font(.footnote)
                .sheet(isPresented: $showingReset) {
                    PasswordResetRequestView()
                }

            if !inviteTokenText.isEmpty {
                Button("Check invite") {
                    Task {
                        await appViewModel.lookupInvite(token: inviteTokenText)
                    }
                }
                .font(.footnote)
            }
        }
        .onAppear {
            if let inviteToken = appViewModel.inviteToken, inviteTokenText.isEmpty {
                inviteTokenText = inviteToken
            }
        }
    }

    private var googleConfigured: Bool {
        let clientId = (Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String) ?? ""
        let serverClientId = (Bundle.main.object(forInfoDictionaryKey: "GIDServerClientID") as? String) ?? ""
        return !clientId.isEmpty && !serverClientId.isEmpty
    }

    private func handleGoogleSignIn() {
        guard googleConfigured else {
            appViewModel.errorMessage = "Google Sign-In is not configured."
            return
        }

        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?.rootViewController else {
            appViewModel.errorMessage = "Unable to present Google Sign-In."
            return
        }

        let clientId = (Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String) ?? ""
        let serverClientId = (Bundle.main.object(forInfoDictionaryKey: "GIDServerClientID") as? String) ?? ""
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientId,
            serverClientID: serverClientId
        )

        isGoogleLoading = true
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            Task {
                await MainActor.run {
                    if let error {
                        appViewModel.errorMessage = error.localizedDescription
                        isGoogleLoading = false
                        return
                    }
                }

                guard let idToken = result?.user.idToken?.tokenString else {
                    await MainActor.run {
                        appViewModel.errorMessage = "Google Sign-In did not return an ID token."
                        isGoogleLoading = false
                    }
                    return
                }

                let inviteToken = inviteTokenText.trimmingCharacters(in: .whitespacesAndNewlines)
                await appViewModel.loginWithGoogle(
                    idToken: idToken,
                    inviteToken: inviteToken.isEmpty ? nil : inviteToken
                )
                await MainActor.run {
                    isGoogleLoading = false
                }
            }
        }
    }
}

private struct RegisterForm: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var alias = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var successMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Register").font(.headline)
            TextField("First name", text: $firstName).textFieldStyle(.roundedBorder)
            TextField("Last name", text: $lastName).textFieldStyle(.roundedBorder)
            TextField("Alias", text: $alias).textFieldStyle(.roundedBorder)
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
            SecureField("Password", text: $password).textFieldStyle(.roundedBorder)

            if let successMessage {
                Text(successMessage).font(.footnote).foregroundStyle(.green)
            }

            Button {
                Task {
                    isLoading = true
                    let registration = WotlweduRegistration(
                        email: email,
                        firstName: firstName,
                        lastName: lastName,
                        alias: alias,
                        auth: password
                    )
                    await appViewModel.register(registration)
                    successMessage = "Registration submitted. Check your email to confirm."
                    isLoading = false
                }
            } label: {
                HStack {
                    if isLoading { ProgressView() }
                    Text("Register")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            .buttonStyle(.bordered)
        }
    }
}

private struct LoginSettingsForm: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var apiUrl = ""
    @State private var defaultStartPage = "home"
    @State private var errorCountdown = 30
    @State private var allowInsecureCertificates = false
    @State private var loaded = false
    @State private var saveMessage: String?

    private let startPageOptions = [
        "home",
        "notifications",
        "preferences",
        "categories",
        "groups",
        "workgroups",
        "organizations",
        "items",
        "images",
        "lists",
        "elections",
        "votes",
        "roles",
        "users",
        "friends",
        "profile"
    ]

    var body: some View {
        Form {
            Section("Connection") {
                TextField("API URL", text: $apiUrl)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                Toggle("Allow insecure certificates", isOn: $allowInsecureCertificates)
            }

            Section("Behavior") {
                Picker("Default start page", selection: $defaultStartPage) {
                    ForEach(startPageOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }

                Stepper(value: $errorCountdown, in: 1...300) {
                    Text("Error countdown: \(errorCountdown)s")
                }
            }

            Section {
                Button("Save settings") {
                    appViewModel.saveConfig(
                        apiUrl: apiUrl,
                        defaultStartPage: defaultStartPage,
                        errorCountdown: errorCountdown,
                        allowInsecureCertificates: allowInsecureCertificates
                    )
                    saveMessage = "Settings saved"
                }
                .buttonStyle(.borderedProminent)

                Button("Reset to bundled defaults", role: .destructive) {
                    appViewModel.resetConfigOverrides()
                    applyConfig(appViewModel.config)
                    saveMessage = "Settings reset"
                }
            }

            if let saveMessage {
                Section {
                    Text(saveMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 360)
        .onAppear {
            guard !loaded else { return }
            applyConfig(appViewModel.config)
            loaded = true
        }
    }

    private func applyConfig(_ config: AppConfig) {
        apiUrl = config.apiUrl
        defaultStartPage = startPageOptions.contains(config.defaultStartPage.lowercased())
            ? config.defaultStartPage.lowercased()
            : "home"
        errorCountdown = max(1, config.errorCountdown)
        allowInsecureCertificates = config.allowInsecureCertificates ?? false
    }
}

struct PasswordResetRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var email = ""
    @State private var sent = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                if sent {
                    Text("Reset link requested. Check your email.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Reset password")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        Task {
                            await appViewModel.requestPasswordReset(email: email)
                            sent = true
                        }
                    }.disabled(email.isEmpty)
                }
            }
        }
    }
}
