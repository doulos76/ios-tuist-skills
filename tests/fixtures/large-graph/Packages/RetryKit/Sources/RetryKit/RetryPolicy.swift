public struct RetryPolicy: Equatable {
    public let limit: Int

    public init(limit: Int) {
        self.limit = limit < 1 ? 1 : limit
    }

    public var attempts: [Int] {
        Array(1...limit)
    }
}
