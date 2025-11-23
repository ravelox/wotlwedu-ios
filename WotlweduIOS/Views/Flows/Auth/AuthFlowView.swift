import SwiftUI

struct AuthFlowView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showingRegister = false
    @State private var showingReset = false

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

                LoginForm(showingReset: $showingReset)

                Button(showingRegister ? "Back to login" : "Create account") {
                    showingRegister.toggle()
                }

                if showingRegister {
                    RegisterForm()
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

            Button("Forgot password?") { showingReset = true }
                .font(.footnote)
                .sheet(isPresented: $showingReset) {
                    PasswordResetRequestView()
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
