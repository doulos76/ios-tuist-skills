import KeyValueStore

public struct Cache {
    private var store = KVStore()

    public init() {}

    public mutating func save(_ value: String, key: String) {
        store.set(value, for: key)
    }

    public func load(_ key: String) -> String? {
        store.value(for: key)
    }
}
