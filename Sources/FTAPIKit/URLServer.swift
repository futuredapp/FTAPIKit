import Foundation

#if os(Linux)
import FoundationNetworking
#endif

/// The standard implementation of the `Server` protocol based on `Foundation.URLSession` networking
/// stack.
///
/// The URLServer provides various means of executing its requests, depending on the needs of the programmer.
/// Extension for the following approaches are currently implemented:
///  - Completion handler based approach (the baseline implementation)
///  - Async/Await pattern
///  - Combine bindings
///
/// It provides a default implementation for
/// `var decoding: Decoding`, `var encoding: Encoding` and
/// `func buildRequest(endpoint: Endpoint) throws -> URLRequest`.  The `URLRequest`
/// creation is implemented in `struct URLRequestBuilder`.
///
/// In case that the requests need to cooperate with other services, like OAuth, override the default implementation
/// of `func buildRequest`, use
/// `func buildStandardRequest(endpoint: Endpoint) throws -> URLRequest` within our new
/// implementation, and use the `URLRequest` as a baseline.
///
/// - Note: The standard implementation is specifically made in order to let you customize:
/// * Error handling
/// * URLRequest creation
/// * Encoding and decoding
/// * URLSession configuration
///
/// In case you need further customization, it might not be worth the time required to bend the standard
///  implementation to your needs.
///
public protocol URLServer: Server where Request == URLRequest {
    /// Error type which is initialized during the request execution
    /// - Note: Provided default implementation.
    associatedtype ErrorType: APIError = APIError.Standard

    /// Base URI of the server
    var baseUri: URL { get }

    /// `URLSession` instance, which is used for task execution
    /// - Note: Provided default implementation.
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
