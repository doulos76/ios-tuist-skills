import Testing
@testable import CoreNetworking

@Test func describeLogsTheRequest() {
    #expect(HTTPClient().describe(HTTPRequest(path: "/x")) == "[log] GET /x")
}
