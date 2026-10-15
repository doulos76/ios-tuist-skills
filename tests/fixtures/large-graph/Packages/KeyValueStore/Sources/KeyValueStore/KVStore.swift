public struct KVStore {
    private var storage: [String: String] = [:]

    public init() {}

    public mutating func set(_ value: String, for key: String) {
        storage[key] = value
    }

    public func value(for key: String) -> String? {
        storage[key]
    }
}
