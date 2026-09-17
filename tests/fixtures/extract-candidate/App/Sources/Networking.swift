import Foundation

public enum APIEndpoint {
    case profile(id: String)

    public var path: String {
        switch self {
        case .profile(let id):
            return "/profiles/\(id)"
        }
    }
}

public struct APIRequestBuilder {
    public let baseURL: URL

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    public func request(for endpoint: APIEndpoint) -> URLRequest {
        URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
    }
}
