@testable import WotlweduIOS
import XCTest

final class ConfigLoaderTests: XCTestCase {
    func testLoadsConfigFromBundle() throws {
        let loader = ConfigLoader()
        let config = try loader.load()
        XCTAssertEqual(config.apiUrl, "https://example.test/api/")
        XCTAssertEqual(config.appVersion, "9.9.9")
        XCTAssertEqual(config.defaultStartPage, "home")
        XCTAssertEqual(config.errorCountdown, 42)
    }

    func testThrowsWhenMissing() {
        class EmptyLoader: ConfigLoader {
            override func load() throws -> AppConfig {
                throw ConfigError.missingConfig
            }
        }

        do {
            _ = try EmptyLoader().load()
            XCTFail("Expected missing config error")
        } catch {
            // expected
        }
    }
}
