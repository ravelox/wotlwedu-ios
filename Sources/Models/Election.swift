import Foundation

struct Election: Codable, Identifiable, Hashable {
    let id: Int
    var name: String
    var description: String?
    var items: [ElectionItem]?
    /// Normalized image URL field (optional)
    var imageUrl: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, description, items
        case imageUrl
        case imageURL, image, image_url
        case coverImageUrl, cover_image_url, coverUrl, cover_url
    }

    init(id: Int, name: String, description: String? = nil, items: [ElectionItem]? = nil, imageUrl: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.items = items
        self.imageUrl = imageUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        items = try c.decodeIfPresent([ElectionItem].self, forKey: .items)

        let keys: [CodingKeys] = [.imageUrl, .imageURL, .image, .image_url, .coverImageUrl, .cover_image_url, .coverUrl, .cover_url]
        var found: String? = nil
        for k in keys {
            if let v = try c.decodeIfPresent(String.self, forKey: k) { found = v; break }
        }
        imageUrl = found
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(items, forKey: .items)
        try c.encodeIfPresent(imageUrl, forKey: .imageUrl)
    }
}

struct ElectionItem: Codable, Identifiable, Hashable {
    let id: Int
    var name: String
    var description: String?
    var votes: Int?
}