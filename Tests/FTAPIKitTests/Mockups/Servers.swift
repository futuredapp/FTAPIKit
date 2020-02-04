import FTAPIKit
import Foundation

struct HTTPBinServer: URLServer {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "http://httpbin.org/")!

    let requestBuilder: (Self, Endpoint) throws -> URLRequest = { server, endpoint in
        var request = try buildStandardRequest(server: server, endpoint: endpoint)
        if endpoint is AuthorizedEndpoint {
            request.addValue("Bearer \(UUID().uuidString)", forHTTPHeaderField: "Authorization")
        }
        return request
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
