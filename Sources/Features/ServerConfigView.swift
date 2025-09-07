
import SwiftUI

struct ServerConfigView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) var dismiss
    @State private var baseURLString: String = ""
    @State private var timeoutString: String = ""
    @State private var error: String?

    var body: some View {
        Form {
            Section("API Server") {
                TextField("Base URL (https://example.com)", text: $baseURLString)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                TextField("Timeout (seconds)", text: $timeoutString)
                    .keyboardType(.numberPad)
            }
            if let error { Text(error).foregroundStyle(.red) }
            Button {
                if validateAndSave() { dismiss() }
            } label: {
                Text("Save").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Server Settings")
        .onAppear {
            baseURLString = session.config.baseURLString
            timeoutString = String(Int(session.config.timeout))
        }
    }

    private func validateAndSave() -> Bool {
        guard let url = URL(string: baseURLString),
              let scheme = url.scheme, scheme.hasPrefix("http") else {
            error = "Please enter a valid http/https URL."
            return false
        }
        let t = TimeInterval(timeoutString) ?? 20
        session.config.baseURLString = baseURLString
        session.config.timeout = max(1, t)
        // Rebuild the API client with the new settings
        session.rebuildAPI()
        error = nil
        return true
    }
}
