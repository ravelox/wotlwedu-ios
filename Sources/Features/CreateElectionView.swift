import SwiftUI

struct CreateElectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: SessionStore
    @State private var name = ""
    @State private var description = ""
    @State private var error: String?
    @State private var isBusy = false

    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $name)
                TextField("Description (optional)", text: $description, axis: .vertical)
            }
            if let error { Text(error).foregroundStyle(.red) }
            Button {
                Task { await create() }
            } label: {
                HStack { if isBusy { ProgressView() } ; Text("Create Election") }.frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isBusy || name.isEmpty)
        }
        .navigationTitle("New Election")
    }

    private func create() async {
        guard let api = session.api else { return }
        error = nil
        isBusy = true
        defer { isBusy = false }
        do {
            _ = try await api.createElection(name: name, description: description.isEmpty ? nil : description)
            dismiss()
        } catch {
            self.error = (error as? APIError)?.userMessage ?? error.localizedDescription
        }
    }
}