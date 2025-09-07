
import SwiftUI

struct BaseURLConfigView: View {
    @AppStorage("apiBaseURL") private var apiBaseURL: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Backend URL") {
                TextField("https://example.com", text: $apiBaseURL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            Button("Save") { dismiss() }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Server Settings")
    }
}

#Preview {
    BaseURLConfigView()
}
