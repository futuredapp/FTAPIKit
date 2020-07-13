import Foundation
import FTAPIKit

struct HTTPBinServer: URLServer {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "http://httpbin.org/")!

    func buildRequest(endpoint: Endpoint) throws -> URLRequest {
        var request = try buildStandardRequest(endpoint: endpoint)
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
