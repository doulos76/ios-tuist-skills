import LogKit

public struct HTTPRequest: Equatable {
    public let path: String

    public init(path: String) {
        self.path = path
    }
}

public struct HTTPClient {
    public init() {}

    public func describe(_ request: HTTPRequest) -> String {
        Log.message("GET " + request.path)
    }
}
