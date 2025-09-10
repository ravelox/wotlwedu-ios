import Foundation

/// Utility for transforming `Encodable` objects into request parameters.
public enum JSONEncodingHelper {
    public static func encodingParameters<T: Encodable>(forEncodableObject encodable: T?) -> [String: Any]? {
        guard let encodable = encodable else { return nil }
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(encodable),
              let json = try? JSONSerialization.jsonObject(with: data),
              let dict = json as? [String: Any] else {
            return nil
        }
        return dict
    }
}
