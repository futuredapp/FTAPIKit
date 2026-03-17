import Foundation
import Testing

@testable import FTAPIKit

/// Tests demonstrating async buildRequest functionality addressing GitHub issue #105
@Suite
struct AsyncBuildRequestTests {

    @Test
    func asyncBuildRequestWithDynamicHeaders() async throws {
        let server = DynamicHeaderServer()
        let data = try await server.call(data: GetEndpoint())
        let response = try JSONDecoder().decode(HTTPBinResponse.self, from: data)
        #expect(response.headers["X-App-Version"] == "2.0.0")
        #expect(response.headers["X-Device-Id"] == "test-device-123")
    }

    @Test
    func asyncBuildRequestWithTokenRefresh() async throws {
        let tokenManager = MockTokenManager()
        let server = TokenRefreshServer(tokenManager: tokenManager)
        tokenManager.currentToken = "expired-token"
        let data = try await server.call(data: GetEndpoint())
        let response = try JSONDecoder().decode(HTTPBinResponse.self, from: data)
        #expect(response.headers["Authorization"] == "Bearer refreshed-token-456")
        #expect(tokenManager.refreshCalled)
    }
}

// MARK: - Mock Servers

private struct DynamicHeaderServer: URLServer {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "http://httpbin.org/")!

    func buildRequest(endpoint: Endpoint) async throws -> URLRequest {
        let config = await fetchConfiguration()
        var request = try buildStandardRequest(endpoint: endpoint)
        request.addValue(config.appVersion, forHTTPHeaderField: "X-App-Version")
        request.addValue(config.deviceId, forHTTPHeaderField: "X-Device-Id")
        return request
    }

    private func fetchConfiguration() async -> AppConfiguration {
        try? await Task.sleep(nanoseconds: 10_000_000)
        return AppConfiguration(appVersion: "2.0.0", deviceId: "test-device-123")
    }
}

private struct TokenRefreshServer: URLServer {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "http://httpbin.org/")!
    let tokenManager: MockTokenManager

    func buildRequest(endpoint: Endpoint) async throws -> URLRequest {
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

private final class MockTokenManager: @unchecked Sendable {
    private let lock = NSLock()
    private var _currentToken: String = "initial-token"
    private var _refreshCalled = false

    var currentToken: String {
        get { lock.withLock { _currentToken } }
        set { lock.withLock { _currentToken = newValue } }
    }

    var refreshCalled: Bool {
        lock.withLock { _refreshCalled }
    }

    func refreshIfNeeded() async {
        try? await Task.sleep(nanoseconds: 10_000_000)
        lock.withLock {
            _refreshCalled = true
            _currentToken = "refreshed-token-456"
        }
    }
}

private struct HTTPBinResponse: Decodable, Sendable {
    let headers: [String: String]

    private enum CodingKeys: String, CodingKey {
        case headers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawHeaders = try container.decode([String: String].self, forKey: .headers)
        self.headers = rawHeaders
    }
}
