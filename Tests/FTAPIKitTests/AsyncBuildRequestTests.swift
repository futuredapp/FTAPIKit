import XCTest
#if os(Linux)
import FoundationNetworking
#endif
@testable import FTAPIKit

/// Tests demonstrating async buildRequest functionality addressing GitHub issue #105
final class AsyncBuildRequestTests: XCTestCase {

    func testAsyncBuildRequestWithDynamicHeaders() async throws {
        // Given: A server with async buildRequest that fetches dynamic configuration
        let server = DynamicHeaderServer()

        // When: Making a call to an endpoint
        let data = try await server.call(data: GetEndpoint())

        // Then: The request should have included the dynamically fetched headers
        // Decode the response to verify headers were included
        let response = try JSONDecoder().decode(HTTPBinResponse.self, from: data)
        XCTAssertEqual(response.headers["X-App-Version"], "2.0.0")
        XCTAssertEqual(response.headers["X-Device-Id"], "test-device-123")
    }

    func testAsyncBuildRequestWithTokenRefresh() async throws {
        // Given: A server with async buildRequest that refreshes tokens
        let tokenManager = MockTokenManager()
        let server = TokenRefreshServer(tokenManager: tokenManager)

        // When: Making a call (with expired token)
        tokenManager.currentToken = "expired-token"
        let data = try await server.call(data: GetEndpoint())

        // Then: The request should have used the refreshed token
        let response = try JSONDecoder().decode(HTTPBinResponse.self, from: data)
        XCTAssertEqual(response.headers["Authorization"], "Bearer refreshed-token-456")
        XCTAssertTrue(tokenManager.refreshCalled)
    }

    static let allTests = [
        ("testAsyncBuildRequestWithDynamicHeaders", testAsyncBuildRequestWithDynamicHeaders),
        ("testAsyncBuildRequestWithTokenRefresh", testAsyncBuildRequestWithTokenRefresh)
    ]
}

// MARK: - Mock Servers

/// Server that fetches configuration asynchronously before building requests
private struct DynamicHeaderServer: URLServer {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "http://httpbin.org/")!

    func buildRequest(endpoint: Endpoint) async throws -> URLRequest {
        // Simulate async configuration fetch
        let config = await fetchConfiguration()

        var request = try buildStandardRequest(endpoint: endpoint)
        request.addValue(config.appVersion, forHTTPHeaderField: "X-App-Version")
        request.addValue(config.deviceId, forHTTPHeaderField: "X-Device-Id")
        return request
    }

    private func fetchConfiguration() async -> AppConfiguration {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        return AppConfiguration(appVersion: "2.0.0", deviceId: "test-device-123")
    }
}

/// Server that refreshes authentication tokens before building requests
private struct TokenRefreshServer: URLServer {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "http://httpbin.org/")!
    let tokenManager: MockTokenManager

    func buildRequest(endpoint: Endpoint) async throws -> URLRequest {
        // Refresh token if needed
        await tokenManager.refreshIfNeeded()

        var request = try buildStandardRequest(endpoint: endpoint)
        request.addValue("Bearer \(tokenManager.currentToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}

// MARK: - Mock Models

private struct AppConfiguration {
    let appVersion: String
    let deviceId: String
}

private class MockTokenManager {
    var currentToken: String = "initial-token"
    var refreshCalled = false

    func refreshIfNeeded() async {
        // Simulate token refresh
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        refreshCalled = true
        currentToken = "refreshed-token-456"
    }
}

private struct HTTPBinResponse: Decodable, Sendable {
    let headers: [String: String]

    private enum CodingKeys: String, CodingKey {
        case headers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // HTTPBin returns headers with various casings, normalize to our expected keys
        let rawHeaders = try container.decode([String: String].self, forKey: .headers)
        self.headers = rawHeaders
    }
}
