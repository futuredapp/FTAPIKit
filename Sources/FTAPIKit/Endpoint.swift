import Foundation

/// Protocol describing API endpoint. API Endpoint describes one URI with all the
/// data and parameters which are sent to it.
///
/// Recommended conformance of this protocol is implemented using `struct`. It is
/// of course possible using `enum` or `class`. Endpoints are not designed
/// to be referenced and used instantly after creation, so no memory usage is required.
/// The case for not using enums is long-term sustainability. Enums tend to have many
/// cases and information about one endpoint is spreaded all over the files. Also,
/// structs offer us generated initializers, which is very helpful.
///
/// - Important: Each endpoint should conform to at most one body-providing protocol
///   (``DataEndpoint``, ``URLEncodedEndpoint``, ``MultipartEndpoint``, ``RequestEndpoint``,
///   ``UploadEndpoint``). Conforming to multiple body protocols results in undefined body selection.
///
public protocol Endpoint {

    /// URL path component without base URI.
    var path: String { get }

    /// HTTP headers.
    /// - Note: Default implementation returns empty dictionary.
    var headers: [String: String] { get }

    /// Query of the request, expressible as a dictionary literal with non-unique keys.
    /// - Note: Default implementation returns empty query.
    var query: URLQuery { get }

    /// HTTP method/verb describing the action.
    /// - Note: Default implementation returns ``FTAPIKit/HTTPMethod/get``.
    var method: HTTPMethod { get }
}

public extension Endpoint {
    var headers: [String: String] { [:] }
    var query: URLQuery { URLQuery() }
    var method: HTTPMethod { .get }
}

/// ``DataEndpoint`` transmits data provided in the ``FTAPIKit/DataEndpoint/body`` property without any further encoding.
/// - Note: Default HTTP method is ``FTAPIKit/HTTPMethod/post``.
public protocol DataEndpoint: Endpoint {
    var body: Data { get }
}

public extension DataEndpoint {
    var method: HTTPMethod { .post }
}

/// ``UploadEndpoint`` will send the provided file to the API.
///
/// - Note: If the standard implementation is used, `URLSession.uploadTask` methods will be used.
/// Default HTTP method is ``FTAPIKit/HTTPMethod/post``.
public protocol UploadEndpoint: Endpoint {

    /// File which will be sent.
    var file: URL { get }
}

public extension UploadEndpoint {
    var method: HTTPMethod { .post }
}

/// Endpoint which will be sent as a multipart HTTP request.
///
/// - Note: If the standard implementation is used, the body parts will be merged into a temporary file, which will
/// then be transformed to an input stream and passed to the request as a `httpBodyStream`.
/// Default HTTP method is ``FTAPIKit/HTTPMethod/post``.
public protocol MultipartEndpoint: Endpoint {

    /// List of individual body parts.
    var parts: [MultipartBodyPart] { get }
}

public extension MultipartEndpoint {
    var method: HTTPMethod { .post }
}

/// The body of the endpoint with the URL query format.
/// - Note: Default HTTP method is ``FTAPIKit/HTTPMethod/post``.
public protocol URLEncodedEndpoint: Endpoint {
    var body: URLQuery { get }
}

public extension URLEncodedEndpoint {
    var method: HTTPMethod { .post }
}

/// An abstract representation of endpoint, body of which is represented by Swift encodable type. It serves as an
/// abstraction between the ``URLServer`` protocol and more specific ``Endpoint`` conforming protocols.
/// Do not use this protocol to represent an encodable endpoint, use ``RequestEndpoint`` instead.
public protocol EncodableEndpoint: Endpoint {

    /// Returns `data` which will be sent as the body of the endpoint. Note that only the encoder is passed to
    /// the function. The origin of the encodable data is not specified by this protocol.
    /// - Parameter encoding: Server provided encoder, which will also configure headers.
    func body(encoding: Encoding) throws -> Data
}

/// Protocol extending ``Endpoint`` with decodable associated type, which is used
/// for automatic deserialization.
public protocol ResponseEndpoint: Endpoint {
    /// Associated type describing the return type conforming to `Decodable`
    /// protocol. This is only a phantom-type used by ``URLServer``
    /// for automatic decoding/deserialization of API results.
    associatedtype Response: Decodable & Sendable
}

/// Protocol extending ``Endpoint``, which supports sending `Encodable` data to the server.
///
/// - Note: Provides default implementation for ``FTAPIKit/RequestEndpoint/body(encoding:)``
/// and ``FTAPIKit/RequestEndpoint/method``.
public protocol RequestEndpoint: EncodableEndpoint {
    /// Associated type describing the encodable request model for serialization. The associated type is derived
    /// from the body property.
    associatedtype Request: Encodable & Sendable
    /// Generic encodable model, which will be sent in the body of the request.
    var request: Request { get }
}

public extension RequestEndpoint {
    var method: HTTPMethod { .post }

    func body(encoding: Encoding) throws -> Data {
        try encoding.encode(request)
    }
}

/// Typealias combining request and response API endpoint. For describing codable
/// request which both sends and expects serialized model from the server.
public typealias RequestResponseEndpoint = RequestEndpoint & ResponseEndpoint
