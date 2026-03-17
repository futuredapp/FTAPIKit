import Foundation

/// `URLServer` represents a single web service and provides a gateway to an API over HTTP.
///
/// Conforming type should have the ability to encode/decode data into requests and responses
/// using the `Codable` conformances and strongly typed coding of the Swift language.
///
/// The protocol provides default implementations for `decoding`, `encoding`, `urlSession`,
/// and `networkObservers`. Only `baseUri` must be provided by conforming types.
///
/// In case that the requests need to cooperate with other services, like OAuth, override the
/// default implementation of `buildRequest`, use `buildStandardRequest(endpoint:)` within
/// your new implementation, and use the `URLRequest` as a baseline.
public protocol URLServer {
    /// Error type which is initialized during the request execution.
    associatedtype ErrorType: APIError = APIError.Standard

    /// Base URI of the server.
    var baseUri: URL { get }

    /// `URLSession` instance, which is used for task execution.
    var urlSession: URLSession { get }

    /// The instance providing strongly typed decoding.
    var decoding: Decoding { get }

    /// The instance providing strongly typed encoding.
    var encoding: Encoding { get }

    /// Array of network observers.
    /// Each observer receives lifecycle callbacks for every request.
    var networkObservers: [any NetworkObserver] { get }

    /// Takes a Swift description of an endpoint call and transforms it into a valid request.
    ///
    /// This is useful in cases when the API uses OAuth or some other token-based authorization,
    /// where the request may be delayed before the valid tokens are received.
    /// - Parameter endpoint: An instance of an endpoint representing a call.
    /// - Returns: A valid `URLRequest`.
    func buildRequest(endpoint: Endpoint) async throws -> URLRequest
}

public extension URLServer {
    var urlSession: URLSession { .shared }
    var decoding: Decoding { JSONDecoding() }
    var encoding: Encoding { JSONEncoding() }
    var networkObservers: [any NetworkObserver] { [] }

    func buildRequest(endpoint: Endpoint) async throws -> URLRequest {
        try buildStandardRequest(endpoint: endpoint)
    }
}
