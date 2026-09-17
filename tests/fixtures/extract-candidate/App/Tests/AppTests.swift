import Foundation
import Testing
@testable import App

@Test func requestBuilderComposesProfilePath() {
    let builder = APIRequestBuilder(baseURL: URL(string: "https://example.com")!)
    let request = builder.request(for: .profile(id: "42"))
    #expect(request.url?.path == "/profiles/42")
}
