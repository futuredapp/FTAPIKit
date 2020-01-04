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

    /// URL parameters is string dictionary sent either as URL query, multipart,
    /// JSON parameters or URL/Base64 encoded body. The `type` parameter of `APIEndpoint`
    /// protocol describes the way how to send the parameters.
    var parameters: HTTPParameters { get }

    /// HTTP method/verb describing the action.
    var method: HTTPMethod { get }

    /// Type of the request describing how the parameters and data should be encoded and
    /// sent to the server. If additional data (not only parameters) are sent, then they
    /// are returned as an associated value of the type.
    var type: RequestType { get }

    /// Boolean marking whether the endpoint should be signed and authorization is required.
    ///
    /// This value is not used inside the framework. This value should be checked and handled
    /// accordingly when signing using the `APIAdapterDelegate`.
    var authorized: Bool { get }
}

public extension Endpoint {
    var parameters: HTTPParameters {
        return [:]
    }

    var type: RequestType {
        return .jsonParams
    }

    var method: HTTPMethod {
        return .get
    }

    var authorized: Bool {
        return false
    }
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
    associatedtype Request: Encodable
    /// Generic encodable model, which will be sent as JSON body.
    var body: Request { get }
}

public extension RequestEndpoint {
    var method: HTTPMethod {
        return .post
    }

    var type: RequestType {
        return RequestType.jsonBody(body)
    }
}

/// Typealias combining request and response API endpoint. For describing JSON
/// request which both sends and expects JSON model from the server.
public typealias RequestResponseEndpoint = RequestEndpoint & ResponseEndpoint
