import Foundation

/// A minimal protocol that mirrors the one expected by the generated models.
/// The models already conform to `Encodable` via `Codable`, so no additional
/// requirements are needed here.
public protocol JSONEncodable: Encodable {}
