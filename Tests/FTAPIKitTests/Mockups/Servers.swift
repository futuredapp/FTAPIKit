import Foundation
import FTAPIKit

// MARK: - Test servers
// Integration tests use httpbin.org for real HTTP requests.
// These tests require network access and may fail if httpbin.org is unreachable.

struct HTTPBinServer: URLServer {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "http://httpbin.org/")!
}

/// Configuration that adds a Bearer token to the request.
struct BearerTokenConfiguration: RequestConfiguring {
    let token: String

    init(token: String = UUID().uuidString) {
        self.token = token
    }

    func configure(_ request: inout URLRequest) async throws {
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

struct NonExistingServer: URLServer {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "https://www.tato-stranka-urcite-neexistuje.cz/")!
}

struct ErrorThrowingServer: URLServer {
    typealias ErrorType = ThrowawayAPIError

    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "http://httpbin.org/")!
}

struct HTTPBinServerWithObservers: URLServer {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "http://httpbin.org/")!
    let networkObservers: [any NetworkObserver]

    init(observers: [any NetworkObserver] = []) {
        self.networkObservers = observers
    }
}
