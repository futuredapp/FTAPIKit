import Foundation

/// Protocol describing API endpoint. API Endpoint describes one URI with all the
/// data and parameters which are sent to it.
///
/// Recommended conformance of this protocol is implemented using `struct`. It is
/// of course possible using `enum` or `class`. Endpoints are are not designed
/// to be referenced and used instantly after creation, so no memory usage is required.
/// The case for not using enums is long-term sustainability. Enums tend to have many
/// cases and information about one endpoint is spreaded all over the files. Also,
/// structs offer us generated initializers, which is very helpful
///
public protocol Endpoint {

    /// URL path component without base URI.
    var path: String { get }

    var headers: [String: String] { get }

    var query: [String: String] { get }

    /// HTTP method/verb describing the action.
    var method: HTTPMethod { get }

    func body(encoding: Encoding) throws -> InputStream?
}

public extension Endpoint {
    var headers: [String: String] { [:] }
    var query: [String: String] { [:] }
    var method: HTTPMethod { .get }
}

public protocol DataEndpoint: Endpoint {
    var data: Data { get }
}

public extension DataEndpoint {
    func body(encoding: Encoding) throws -> InputStream? { InputStream(data: data) }
}

/// Endpoint protocol extending `Endpoint` having decodable associated type, which is used
/// for automatic deserialization.
public protocol ResponseEndpoint: Endpoint {
    /// Associated type describing the return type conforming to `Decodable`
    /// protocol. This is only a phantom-type used by `APIAdapter`
    /// for automatic decoding/deserialization of API results.
    associatedtype Response: Decodable
}

/// Endpoint protocol extending `Endpoint` encapsulating and improving sending JSON models to API.
public protocol RequestEndpoint: Endpoint {
    /// Associated type describing the encodable request model for
    /// JSON serialization. The associated type is derived from
    /// the body property.
    associatedtype Parameters: Encodable
    /// Generic encodable model, which will be sent as JSON body.
    var parameters: Parameters { get }
}

public extension RequestEndpoint {
    var method: HTTPMethod { .post }

    func body(encoding: Encoding) throws -> InputStream? {
        InputStream(data: try encoding.encode(parameters))
    }
}

/// Typealias combining request and response API endpoint. For describing JSON
/// request which both sends and expects JSON model from the server.
public typealias RequestResponseEndpoint = RequestEndpoint & ResponseEndpoint
