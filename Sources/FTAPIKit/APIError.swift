import Foundation

#if os(Linux)
import FoundationNetworking
#endif

/// Error protocol used in types conforming to ``URLServer`` protocol. Default implementation called ``APIErrorStandard``
/// is provided. A type conforming to ``APIError`` protocol can be provided to ``URLServer``
/// to use custom error handling.
///
/// - Note: Since this type is specific to the standard implementation, it works with Foundation `URLSession`
/// network API.
public protocol APIError: Error {
    /// Standard implementation of ``APIError``
    typealias Standard = APIErrorStandard

    /// Creates instance if arguments do not represent a valid server response.
    ///
    /// - Parameters:
    ///   - data: The data returned from the server
    ///   - response: The URL response returned from the server
    ///   - error: Error returned by `URLSession` task execution
    ///   - decoding: The decoder associated with this server, in case the `data` parameter is encoded
    ///
    /// - Warning: Initializer can't return an instance if arguments contain a valid server response. The
    /// response would be discarded if it does, and the API call would be treated as a failure.
    init?(data: Data?, response: URLResponse?, error: Error?, decoding: Decoding)

    /// If the initializer fails but the server response is not valid, this property is used as a fallback.
    static var unhandled: Self { get }
}
