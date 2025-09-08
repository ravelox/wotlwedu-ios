#if canImport(Combine)
@_exported import Combine
#else
// Provide minimal stand-ins for Combine types so the sources can be
// type-checked on platforms where Combine is unavailable (e.g. Linux).
protocol ObservableObject {}

@propertyWrapper
struct Published<Value> {
    var wrappedValue: Value
    init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
}
#endif

