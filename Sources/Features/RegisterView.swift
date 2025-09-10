import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var session: SessionStore
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var error: String?
    @State private var isBusy = false
    
    var body: some View {
        Form {
            Section("Create Account") {
                TextField("Name (optional)", text: $name)
                TextField("Email", text: $email)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
            }
            if let error { Text(error).foregroundStyle(.red) }
            Button {
                Task { await register() }
            } label: {
                HStack { if isBusy { ProgressView() } ; Text("Register") }.frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isBusy || email.isEmpty || password.isEmpty)
        }
        .navigationTitle("Register")
    }
    
    private func register() async {
        error = nil
        isBusy = true
        defer { isBusy = false }
        do {
            try await session.register(email: email, password: password, name: name.isEmpty ? nil : name)
        } catch {
            self.error = error.localizedDescription
        }
    }
}