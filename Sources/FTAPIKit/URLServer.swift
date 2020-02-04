import Foundation

public protocol URLServer: Server where Request == URLRequest {
    var baseUri: URL { get }
    var urlSession: URLSession { get }
}

public extension URLServer {
    var urlSession: URLSession { .shared }
    var decoding: Decoding { JSONDecoding() }
    var encoding: Encoding { JSONEncoding() }
    var requestBuilder: (Self, Endpoint) throws -> URLRequest { Self.buildStandardRequest }
}
