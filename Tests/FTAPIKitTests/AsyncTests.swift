#if swift(>=5.5)
import Foundation
import XCTest

final class AsyncTests: XCTestCase {
    func testCallWithoutResponse() async throws {
        guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) else {
            return
        }
        let server = HTTPBinServer()
        let endpoint = GetEndpoint()
        try await server.call(endpoint: endpoint)
    }

    func testCallWithData() async throws {
        guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) else {
            return
        }
        let server = HTTPBinServer()
        let endpoint = GetEndpoint()
        let data = try await server.call(data: endpoint)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testCallParsingResponse() async throws {
        guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) else {
            return
        }
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
