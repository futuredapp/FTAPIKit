#if swift(>=5.5.2) && !os(Linux)
import Foundation
import XCTest

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
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
