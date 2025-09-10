import SwiftUI

@main
struct WotlweduClientApp: App {
    @StateObject private var session = SessionStore()
    var body: some Scene {
        WindowGroup { RootView().environmentObject(session) }
    }
}