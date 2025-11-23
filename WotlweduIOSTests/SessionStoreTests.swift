@testable import WotlweduIOS
import XCTest

final class SessionStoreTests: XCTestCase {
    func testSaveAndLoadRoundTrip() {
        let defaults = UserDefaults(suiteName: "SessionStoreTests")!
        defaults.removePersistentDomain(forName: "SessionStoreTests")

        let store = SessionStore(defaults: defaults)
        store.save(id: "user1", auth: "auth-token", refresh: "refresh-token", displayName: "Tester", admin: true)

        let reloaded = SessionStore(defaults: defaults)
        XCTAssertEqual(reloaded.userId, "user1")
        XCTAssertEqual(reloaded.authToken, "auth-token")
        XCTAssertEqual(reloaded.refreshToken, "refresh-token")
        XCTAssertEqual(reloaded.displayName, "Tester")
        XCTAssertTrue(reloaded.isAdmin)
    }

    func testResetClearsData() {
        let defaults = UserDefaults(suiteName: "SessionStoreTests")!
        defaults.removePersistentDomain(forName: "SessionStoreTests")

        let store = SessionStore(defaults: defaults)
        store.save(id: "user1", auth: "auth-token", refresh: "refresh-token", displayName: "Tester", admin: true)
        store.reset()

        XCTAssertNil(store.userId)
        XCTAssertNil(store.authToken)
        XCTAssertNil(store.refreshToken)
        XCTAssertNil(store.displayName)
        XCTAssertFalse(store.isAdmin)
    }
}
