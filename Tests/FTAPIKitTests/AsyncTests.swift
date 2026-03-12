import Foundation
import Testing

@testable import FTAPIKit

@Suite
struct AsyncTests {

    @Test
    func callWithoutResponse() async throws {
        let server = HTTPBinServer()
        let endpoint = GetEndpoint()
        try await server.call(endpoint: endpoint)
    }

    @Test
    func callWithData() async throws {
        let server = HTTPBinServer()
        let endpoint = GetEndpoint()
        let data = try await server.call(data: endpoint)
        #expect(!data.isEmpty)
    }

    @Test
    func callParsingResponse() async throws {
        let server = HTTPBinServer()
        let user = User(uuid: UUID(), name: "Some Name", age: .random(in: 0...120))
        let endpoint = UpdateUserEndpoint(request: user)
        let response = try await server.call(response: endpoint)
        #expect(user == response.json)
    }
}
