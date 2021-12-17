#if swift(>=5.5) && !os(Linux)
import Foundation
import XCTest

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
final class AsyncTests: XCTestCase {
    func testCallWithoutResponse() async throws {
        let server = HTTPBinServer()
        let endpoint = GetEndpoint()
        try await server.call(endpoint: endpoint)
    }

    func testCallWithData() async throws {
        let server = HTTPBinServer()
        let endpoint = GetEndpoint()
        let data = try await server.call(data: endpoint)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testCallParsingResponse() async throws {
        let server = HTTPBinServer()
        let user = User(uuid: UUID(), name: "Some Name", age: .random(in: 0...120))
        let endpoint = UpdateUserEndpoint(request: user)
        let response = try await server.call(response: endpoint)
        XCTAssertEqual(user, response.json)
    }

    static var allTests = [
        ("testCallWithoutResponse", testCallWithoutResponse),
        ("testCallWithData", testCallWithData),
        ("testCallParsingResponse", testCallParsingResponse)
    ]
}
#endif
