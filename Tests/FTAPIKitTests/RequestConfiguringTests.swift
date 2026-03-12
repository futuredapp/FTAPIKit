import Foundation
import Testing

@testable import FTAPIKit

/// Tests for RequestConfiguring protocol functionality
@Suite
struct RequestConfiguringTests {

    @Test
    func nilConfigurationMakesNoChanges() async throws {
        let server = HTTPBinServer()
        let data = try await server.call(data: GetEndpoint())
        let response = try JSONDecoder().decode(HTTPBinHeadersResponse.self, from: data)
        #expect(response.headers["X-Custom-Header"] == nil)
    }

    @Test
    func customConfigurationModifiesRequest() async throws {
        let config = HeaderAddingConfiguration(headerName: "X-Custom-Header", headerValue: "test-value-123")
        let server = HTTPBinServer()
        let data = try await server.call(data: GetEndpoint(), configuring: config)
        let response = try JSONDecoder().decode(HTTPBinHeadersResponse.self, from: data)
        #expect(response.headers["X-Custom-Header"] == "test-value-123")
    }

    @Test
    func configurationErrorPropagates() async throws {
        let config = FailingConfiguration()
        let server = HTTPBinServer()

        do {
            _ = try await server.call(data: GetEndpoint(), configuring: config)
            Issue.record("Expected error to be thrown")
        } catch let error as ConfigurationError {
            #expect(error == .tokenRefreshFailed)
        }
    }

    @Test
    func asyncOperationsInConfigure() async throws {
        let tokenManager = MockAsyncTokenManager()
        let config = AsyncTokenConfiguration(tokenManager: tokenManager)
        let server = HTTPBinServer()
        let data = try await server.call(data: GetEndpoint(), configuring: config)
        let response = try JSONDecoder().decode(HTTPBinHeadersResponse.self, from: data)
        #expect(response.headers["Authorization"] == "Bearer refreshed-token")
        #expect(tokenManager.refreshCalled)
    }

    @Test
    func responseEndpointWithConfiguration() async throws {
        let config = HeaderAddingConfiguration(headerName: "X-Api-Key", headerValue: "secret-key")
        let server = HTTPBinServer()
        let response = try await server.call(response: JSONResponseEndpoint(), configuring: config)
        #expect(!response.slideshow.title.isEmpty)
    }

    @Test
    func voidEndpointWithConfiguration() async throws {
        let config = HeaderAddingConfiguration(headerName: "X-Request-Id", headerValue: "req-123")
        let server = HTTPBinServer()
        try await server.call(endpoint: NoContentEndpoint(), configuring: config)
    }
}

// MARK: - Test Configurations

private struct HeaderAddingConfiguration: RequestConfiguring {
    let headerName: String
    let headerValue: String

    func configure(_ request: inout URLRequest) async throws {
        request.setValue(headerValue, forHTTPHeaderField: headerName)
    }
}

private struct FailingConfiguration: RequestConfiguring {
    func configure(_ request: inout URLRequest) async throws {
        throw ConfigurationError.tokenRefreshFailed
    }
}

private struct AsyncTokenConfiguration: RequestConfiguring {
    let tokenManager: MockAsyncTokenManager

    func configure(_ request: inout URLRequest) async throws {
        let token = await tokenManager.getValidToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

// MARK: - Test Helpers

private enum ConfigurationError: Error, Equatable {
    case tokenRefreshFailed
}

private final class MockAsyncTokenManager: Sendable {
    nonisolated(unsafe) var refreshCalled = false

    func getValidToken() async -> String {
        try? await Task.sleep(nanoseconds: 10_000_000)
        refreshCalled = true
        return "refreshed-token"
    }
}

private struct HTTPBinHeadersResponse: Decodable, Sendable {
    let headers: [String: String]
}
