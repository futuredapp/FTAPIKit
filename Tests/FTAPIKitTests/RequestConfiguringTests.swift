import XCTest
#if os(Linux)
import FoundationNetworking
#endif
@testable import FTAPIKit

/// Tests for RequestConfiguring protocol functionality
final class RequestConfiguringTests: XCTestCase {

    func testNilConfigurationMakesNoChanges() async throws {
        // Given: A server and endpoint with no configuration
        let server = HTTPBinServer()

        // When: Making a call without configuration (nil default)
        let data = try await server.call(data: GetEndpoint())

        // Then: Request should succeed without any modifications
        let response = try JSONDecoder().decode(HTTPBinHeadersResponse.self, from: data)
        XCTAssertNil(response.headers["X-Custom-Header"])
    }

    func testCustomConfigurationModifiesRequest() async throws {
        // Given: A custom configuration that adds headers
        let config = HeaderAddingConfiguration(headerName: "X-Custom-Header", headerValue: "test-value-123")
        let server = HTTPBinServer()

        // When: Making a call with the configuration
        let data = try await server.call(data: GetEndpoint(), configuring: config)

        // Then: The request should have the custom header
        let response = try JSONDecoder().decode(HTTPBinHeadersResponse.self, from: data)
        XCTAssertEqual(response.headers["X-Custom-Header"], "test-value-123")
    }

    func testConfigurationErrorPropagates() async throws {
        // Given: A configuration that throws an error
        let config = FailingConfiguration()
        let server = HTTPBinServer()

        // When/Then: The error should propagate
        do {
            _ = try await server.call(data: GetEndpoint(), configuring: config)
            XCTFail("Expected error to be thrown")
        } catch let error as ConfigurationError {
            XCTAssertEqual(error, .tokenRefreshFailed)
        }
    }

    func testAsyncOperationsInConfigure() async throws {
        // Given: A configuration that performs async token refresh
        let tokenManager = MockAsyncTokenManager()
        let config = AsyncTokenConfiguration(tokenManager: tokenManager)
        let server = HTTPBinServer()

        // When: Making a call with the async configuration
        let data = try await server.call(data: GetEndpoint(), configuring: config)

        // Then: The async operation should have completed and header should be set
        let response = try JSONDecoder().decode(HTTPBinHeadersResponse.self, from: data)
        XCTAssertEqual(response.headers["Authorization"], "Bearer refreshed-token")
        XCTAssertTrue(tokenManager.refreshCalled)
    }

    func testResponseEndpointWithConfiguration() async throws {
        // Given: A response endpoint with configuration
        let config = HeaderAddingConfiguration(headerName: "X-Api-Key", headerValue: "secret-key")
        let server = HTTPBinServer()

        // When: Making a call with configuration
        let response = try await server.call(response: JSONResponseEndpoint(), configuring: config)

        // Then: Response should be decoded correctly
        XCTAssertFalse(response.slideshow.title.isEmpty)
    }

    func testVoidEndpointWithConfiguration() async throws {
        // Given: An endpoint that returns no content
        let config = HeaderAddingConfiguration(headerName: "X-Request-Id", headerValue: "req-123")
        let server = HTTPBinServer()

        // When/Then: Call should succeed without throwing
        try await server.call(endpoint: NoContentEndpoint(), configuring: config)
    }

    static let allTests = [
        ("testNilConfigurationMakesNoChanges", testNilConfigurationMakesNoChanges),
        ("testCustomConfigurationModifiesRequest", testCustomConfigurationModifiesRequest),
        ("testConfigurationErrorPropagates", testConfigurationErrorPropagates),
        ("testAsyncOperationsInConfigure", testAsyncOperationsInConfigure),
        ("testResponseEndpointWithConfiguration", testResponseEndpointWithConfiguration),
        ("testVoidEndpointWithConfiguration", testVoidEndpointWithConfiguration)
    ]
}

// MARK: - Test Configurations

/// Simple configuration that adds a header
private struct HeaderAddingConfiguration: RequestConfiguring {
    let headerName: String
    let headerValue: String

    func configure(_ request: inout URLRequest) async throws {
        request.setValue(headerValue, forHTTPHeaderField: headerName)
    }
}

/// Configuration that always fails
private struct FailingConfiguration: RequestConfiguring {
    func configure(_ request: inout URLRequest) async throws {
        throw ConfigurationError.tokenRefreshFailed
    }
}

/// Configuration with async token refresh
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

private class MockAsyncTokenManager: @unchecked Sendable {
    var refreshCalled = false

    func getValidToken() async -> String {
        // Simulate async token refresh
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        refreshCalled = true
        return "refreshed-token"
    }
}

private struct HTTPBinHeadersResponse: Decodable, Sendable {
    let headers: [String: String]
}
