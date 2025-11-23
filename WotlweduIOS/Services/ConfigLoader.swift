import Foundation

enum ConfigError: Error {
    case missingConfig
    case decode(Error)
}

final class ConfigLoader {
    func load() throws -> AppConfig {
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
