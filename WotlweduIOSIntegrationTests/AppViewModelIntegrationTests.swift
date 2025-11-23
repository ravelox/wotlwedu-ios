@testable import WotlweduIOS
import XCTest

final class AppViewModelIntegrationTests: XCTestCase {
    func testBootstrapLoadsConfig() {
        let viewModel = AppViewModel()
        viewModel.bootstrap()
        XCTAssertTrue(viewModel.isConfigured)
        XCTAssertEqual(viewModel.config.appVersion, "0.1.0") // from default or fixture if found
    }
}
