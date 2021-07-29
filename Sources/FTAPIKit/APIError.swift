import Foundation

#if os(Linux)
import FoundationNetworking
#endif

/// Error protocol used in types conforming to `URLServer` protocol. Default implementation called `APIErrorStandard`
/// is provided. A type conforming to `APIError` protocol can be provided to `URLServer`
/// to use custom error handling.
///
/// - Note: Since this type is specific to the reference implementation, it works with Foundation `URLSession`
/// network API.
public protocol APIError: Error {
    /// Reference implementation of `APIError`
    typealias Standard = APIErrorStandard

    /// Initializer used during error handling in the reference implementation.
    ///
    /// - Parameters:
    ///   - data: The data returned from the server
    ///   - response: The URL response returned from the server
    ///   - error: Error returned by `URLSession` task execution
    ///   - decoding: The decoder associated with this server, in case the `data` parameter is encoded
    init?(data: Data?, response: URLResponse?, error: Error?, decoding: Decoding)

    /// In case the optional initializer fails this property is used as fallback.
    static var unhandled: Self { get }
}
