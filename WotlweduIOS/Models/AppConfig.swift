import Foundation

struct AppConfig: Codable {
    var apiUrl: String
    var appVersion: String
    var defaultStartPage: String
    var errorCountdown: Int
    var allowInsecureCertificates: Bool?

    static let `default` = AppConfig(
        apiUrl: "https://api.wotlwedu.com:9876/",
        appVersion: "0.2.3",
        defaultStartPage: "home",
        errorCountdown: 30,
        allowInsecureCertificates: true
    )
}

struct AppConfigOverrides: Codable {
    var apiUrl: String
    var defaultStartPage: String
    var errorCountdown: Int
    var allowInsecureCertificates: Bool?
}
