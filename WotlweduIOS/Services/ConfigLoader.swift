import Foundation

enum ConfigError: Error {
    case missingConfig
    case decode(Error)
}

final class ConfigLoader {
    private let overridesKey = "wotlwedu-config-overrides"

    func load() throws -> AppConfig {
        var config = try loadBundleConfig()
        if let overrides = loadOverrides() {
            config.apiUrl = overrides.apiUrl
            config.defaultStartPage = overrides.defaultStartPage
            config.errorCountdown = overrides.errorCountdown
            config.allowInsecureCertificates = overrides.allowInsecureCertificates
        }
        return config
    }

    func saveOverrides(_ overrides: AppConfigOverrides) throws {
        let data = try JSONEncoder().encode(overrides)
        UserDefaults.standard.set(data, forKey: overridesKey)
    }

    func clearOverrides() {
        UserDefaults.standard.removeObject(forKey: overridesKey)
    }

    func loadOverrides() -> AppConfigOverrides? {
        guard let data = UserDefaults.standard.data(forKey: overridesKey) else {
            return nil
        }
        return try? JSONDecoder().decode(AppConfigOverrides.self, from: data)
    }

    private func loadBundleConfig() throws -> AppConfig {
        let bundle = Bundle.main
        let candidates = ["wotlwedu-config", "wotlwedu-config.json"]
        for name in candidates {
            if let url = bundle.url(forResource: name, withExtension: name.hasSuffix(".json") ? nil : "json") {
                do {
                    let data = try Data(contentsOf: url)
                    return try JSONDecoder().decode(AppConfig.self, from: data)
                } catch {
                    throw ConfigError.decode(error)
                }
            }
        }
        throw ConfigError.missingConfig
    }
}
