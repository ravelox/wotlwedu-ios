import Foundation

/// Minimal helper utilities expected by the generated API code.
public enum APIHelper {
    /// Maps a value to a path item by converting it to a `String`.
    public static func mapValueToPathItem<T>(_ value: T) -> String {
        return String(describing: value)
    }

    /// Removes any headers with `nil` values.
    public static func rejectNilHeaders(_ headers: [String: Any?]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in headers {
            if let value = value {
                result[key] = value
            }
        }
        return result
    }
}
