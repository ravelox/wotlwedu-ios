import Foundation

struct Endpoints {
    let baseURL: URL
    let timeout: TimeInterval

    init(baseURLString: String, timeout: TimeInterval) {
        guard let url = URL(string: baseURLString) else {
            fatalError("Invalid API base URL string: \(baseURLString)")
        }
        self.baseURL = url
        self.timeout = timeout
    }

    var login: URL { baseURL.appendingPathComponent("login") }
    var register: URL { baseURL.appendingPathComponent("login").appendingPathComponent("register") }
    var me: URL { baseURL.appendingPathComponent("users").appendingPathComponent("me") }

    var elections: URL { baseURL.appendingPathComponent("elections") }
    func election(id: Int) -> URL { elections.appendingPathComponent(String(id)) }
    func items(electionId: Int) -> URL { election(id: electionId).appendingPathComponent("items") }
    func vote(electionId: Int, itemId: Int) -> URL { items(electionId: electionId).appendingPathComponent(String(itemId)).appendingPathComponent("vote") }
    func electionImage(electionId: Int) -> URL { election(id: electionId).appendingPathComponent("image") }
    func itemImage(electionId: Int, itemId: Int) -> URL { items(electionId: electionId).appendingPathComponent(String(itemId)).appendingPathComponent("image") }
}
