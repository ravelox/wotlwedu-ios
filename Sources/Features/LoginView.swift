import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionStore
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isBusy = false
    @State private var errorMessage: String?
    @State private var showServerConfig = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Sign in to Wotlwedu").font(.title.bold())
            TextField("Email", text: $email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding().background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding().background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
            if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
            Button {
                Task { await signIn() }
            } label: {
                HStack { if isBusy { ProgressView().tint(.white) } ; Text("Sign In").bold() }
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isBusy || email.isEmpty || password.isEmpty)
            HStack {
                Text("No account?")
                NavigationLink("Register") { RegisterView() }
            }
            .font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showServerConfig = true } label: { Image(systemName: "gearshape") }
            }
        }
        .sheet(isPresented: $showServerConfig) { NavigationStack { ServerConfigView() } }
    }
    
    private func signIn() async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }
        do {
            try await session.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}