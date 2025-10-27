import Foundation
import FTAPIKit

#if os(Linux)
import FoundationNetworking
#endif

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

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct TestServerWithCustomLogger: URLServer {
    let urlSession = URLSession(configuration: .ephemeral)
    let baseUri = URL(string: "https://api.example.com/")!
    let logger: LoggerProtocol?
    
    init(logger: LoggerProtocol) {
        self.logger = logger
    }
}
