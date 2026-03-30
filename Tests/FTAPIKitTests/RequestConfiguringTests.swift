import Foundation
import FTAPIKit
import Testing

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
        let tokenManager = MockTokenManager()
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

    @Test
    func configuringOverridesBuildRequest() async throws {
        let server = UserAgentServer()
        let config = HeaderAddingConfiguration(headerName: "User-Agent", headerValue: "ConfigOverride/1.0")
        let data = try await server.call(data: GetEndpoint(), configuring: config)
        let response = try JSONDecoder().decode(HTTPBinHeadersResponse.self, from: data)
        #expect(response.headers["User-Agent"] == "ConfigOverride/1.0")
    }

    @Test
    func compositeConfiguration() async throws {
        let config1 = HeaderAddingConfiguration(headerName: "X-First", headerValue: "one")
        let config2 = HeaderAddingConfiguration(headerName: "X-Second", headerValue: "two")
        let composite = CompositeRequestConfiguring([config1, config2])
        let server = HTTPBinServer()
        let data = try await server.call(data: GetEndpoint(), configuring: composite)
        let response = try JSONDecoder().decode(HTTPBinHeadersResponse.self, from: data)
        #expect(response.headers["X-First"] == "one")
        #expect(response.headers["X-Second"] == "two")
    }

    @Test
    func compositeConfigurationOrderMatters() async throws {
        let first = HeaderAddingConfiguration(headerName: "X-Order", headerValue: "first")
        let second = HeaderAddingConfiguration(headerName: "X-Order", headerValue: "second")
        let composite = CompositeRequestConfiguring([first, second])
        let server = HTTPBinServer()
        let data = try await server.call(data: GetEndpoint(), configuring: composite)
        let response = try JSONDecoder().decode(HTTPBinHeadersResponse.self, from: data)
        #expect(response.headers["X-Order"] == "second")
    }

    @Test
    func downloadWithConfiguration() async throws {
        let config = HeaderAddingConfiguration(headerName: "X-Download-Id", headerValue: "dl-456")
        let server = HTTPBinServer()
        let url = try await server.download(endpoint: ImageEndpoint(), configuring: config)
        #expect(FileManager.default.fileExists(atPath: url.path))
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
    let tokenManager: MockTokenManager

    func configure(_ request: inout URLRequest) async throws {
        let token = await tokenManager.getValidToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

// MARK: - Test Server

/// Server that sets User-Agent in buildRequest, to verify configuring can override it.
private struct UserAgentServer: URLServer {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "http://httpbin.org/")!

    func buildRequest(endpoint: Endpoint) async throws -> URLRequest {
        var request = try buildStandardRequest(endpoint: endpoint)
        request.setValue("BuildRequest/1.0", forHTTPHeaderField: "User-Agent")
        return request
    }
}

// MARK: - Test Helpers

private enum ConfigurationError: Error, Equatable {
    case tokenRefreshFailed
}
