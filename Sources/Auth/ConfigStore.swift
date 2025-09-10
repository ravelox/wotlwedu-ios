import Foundation

final class ClientConfigView: ObservableObject {
    @Published var baseURLString: String {
        didSet { UserDefaults.standard.set(baseURLString, forKey: Self.keyBaseURL) }
    }
    @Published var timeout: TimeInterval {
        didSet { UserDefaults.standard.set(timeout, forKey: Self.keyTimeout) }
    }
    
    static let keyBaseURL = "wotlwedu.baseURL"
    static let keyTimeout = "wotlwedu.timeout"
    
    init() {
        if let saved = UserDefaults.standard.string(forKey: Self.keyBaseURL) {
            self.baseURLString = saved
        } else if let info = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String {
            self.baseURLString = info
        } else {
            self.baseURLString = "https://localhost:9876"
        }
        if UserDefaults.standard.object(forKey: Self.keyTimeout) != nil {
            self.timeout = UserDefaults.standard.double(forKey: Self.keyTimeout)
        } else if let tString = Bundle.main.object(forInfoDictionaryKey: "API_DEFAULT_TIMEOUT") as? String, let t = TimeInterval(tString) {
            self.timeout = t
        } else {
            self.timeout = 20
        }
    }
}
