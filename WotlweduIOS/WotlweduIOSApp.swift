import SwiftUI

@main
struct WotlweduIOSApp: App {
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        Group {
            if !appViewModel.isConfigured {
                ProgressView("Loading configuration...")
                    .task {
                        appViewModel.bootstrap()
                        if appViewModel.isAuthenticated {
                            await appViewModel.refreshStatus()
                            await appViewModel.refreshNotifications()
                        }
                    }
            } else if appViewModel.isAuthenticated {
                MainShellView()
            } else {
                AuthFlowView()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { appViewModel.errorMessage != nil },
            set: { _ in appViewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appViewModel.errorMessage ?? "")
        }
    }
}
