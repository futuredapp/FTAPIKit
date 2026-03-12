import Foundation
import FTAPIKit

struct HTTPBinServer: Server {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "http://httpbin.org/")!

    func buildRequest(endpoint: Endpoint) async throws -> URLRequest {
        var request = try buildStandardRequest(endpoint: endpoint)
        if endpoint is AuthorizedEndpoint {
            request.addValue("Bearer \(UUID().uuidString)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

struct NonExistingServer: Server {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "https://www.tato-stranka-urcite-neexistuje.cz/")!
}

struct ErrorThrowingServer: Server {
    typealias ErrorType = ThrowawayAPIError

    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "http://httpbin.org/")!
}

struct HTTPBinServerWithObservers: Server {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "http://httpbin.org/")!
    let networkObservers: [any NetworkObserver]

    init(observers: [any NetworkObserver] = []) {
        self.networkObservers = observers
    }
}
