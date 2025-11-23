import Foundation

struct AppConfig: Codable {
    var apiUrl: String
    var appVersion: String
    var defaultStartPage: String
    var errorCountdown: Int

    static let `default` = AppConfig(
        apiUrl: "https://api.wotlwedu.com:9876/",
        appVersion: "0.1.0",
        defaultStartPage: "home",
        errorCountdown: 30
    )
}
