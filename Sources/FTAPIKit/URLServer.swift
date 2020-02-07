import Foundation

public protocol URLServer: Server where Request == URLRequest {
    associatedtype ErrorType: APIError = APIError.Standard

    var baseUri: URL { get }
    var urlSession: URLSession { get }
}

public extension URLServer {
    var urlSession: URLSession { .shared }
    var decoding: Decoding { JSONDecoding() }
    var encoding: Encoding { JSONEncoding() }

    func buildRequest(endpoint: Endpoint) throws -> URLRequest {
        try buildStandardRequest(endpoint: endpoint)
    }
}
