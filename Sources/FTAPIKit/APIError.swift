import Foundation

#if os(Linux)
import FoundationNetworking
#endif

/// Abstract error type for the reference implementation. Default implementation called `APIErrorStandard`
/// is provided. The `APIError` is used in the  reference implementation, so that you can use your own
/// Error type instead of `APIErrorStandard` without the need to modify the reference implementation.
///
/// - Note: Since this type is specific to the reference implementation, it works with Foundation `URLSession`
/// network API.
public protocol APIError: Error {
    /// Reference implementation of `APIError`
    typealias Standard = APIErrorStandard

    /// Initializer used during error handling in the reference implementation.
    /// - Parameters:
    ///   - data: The data returned from the server
    ///   - response: The URL response returned from the server
    ///   - error: Error returned by the Foundation API
    ///   - decoding: The decoder associated with this server, in case the `data` parameter is encoded
    init?(data: Data?, response: URLResponse?, error: Error?, decoding: Decoding)

    /// In case, that the conditional init fails, the `.unhandled` case is used as fallback
    static var unhandled: Self { get }
}
