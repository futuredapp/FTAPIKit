/// `Server` is an abstraction rather than a protocol-bound requirement.
///
/// The expectation of a `Server` conforming type is, that it provides a gateway to an API over HTTP. Conforming
/// type shoudl also have the ability to encode/decode data into requests and responses using the `Codable`
/// conformances and strongly typed coding of the Swift language.
///
/// Conforming type must specify the type representing a request like `Foundation.URLRequest` or
/// `Alamofire.Request`. However, conforming type is expected to have the ability to execute the request too.
///
/// The `FTAPIKit` provides a reference implementation tailored for `Foundation.URLSession` and
/// `Foundation` JSON coders. The reference implelentation is represented by `protocol URLServer`.
public protocol Server {
    /// The type representing a `Request` of the network library, like `Foundation.URLRequest` or
    /// `Alamofire.Request`.
    associatedtype Request

    /// The instance providing strongly typed decoding.
    var decoding: Decoding { get }

    /// The instance providing strongly typed encoding.
    var encoding: Encoding { get }

    /// Takes a Swift decription of an endpoint call and transforms it into a valid request. The reason why the
    /// function returns the request to the user is, so the user is able to modify the request before executing.
    /// This is useful in cases when the API uses OAuth or some other token based authorization, where the
    /// request may be delayed, before the valid tokens are received.
    /// - Parameter endpoint: An instance of an endpoint representing a call.
    /// - Returns: A valid request.
    func buildRequest(endpoint: Endpoint) throws -> Request
}
